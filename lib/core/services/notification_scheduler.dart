import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/dust_standards.dart';
import '../utils/dust_calculator.dart';
import 'air_korea_service.dart';
import 'cloud_functions_data_source.dart';
import 'dust_data_source.dart';
import 'notification_service.dart';

/// 미세먼지 알림 스케줄러
/// 백그라운드 서비스에서 호출되는 알림 발송 로직을 캡슐화
class NotificationScheduler {
  Future<void> runCheck(SharedPreferences prefs) async {
    try {
      final stationName = prefs.getString(AppConstants.prefStationName);
      if (stationName == null) return;

      // Cloud Functions URL이 설정된 경우 서버 프록시 사용 (API 키 보안)
      // 미설정 시 직접 호출로 폴백 (개발 환경 등)
      final DustDataSource service =
          AppConfig.cloudFunctionsBaseUrl.isNotEmpty
              ? CloudFunctionsDataSource()
              : AirKoreaService(prefs);

      // 네트워크 실패 시 최대 2회 재시도 (3초 간격)
      final dust = await _fetchWithRetry(() => service.getDustData(stationName));
      if (dust == null) {
        debugPrint('[NotificationScheduler] 데이터 조회 실패 (재시도 포함) — 알림 건너뜀');
        return;
      }

      final profileJson = prefs.getString(AppConstants.prefUserProfile);
      final profile = profileJson != null
          ? UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>)
          : UserProfile.defaultProfile();

      final settingJson = prefs.getString(AppConstants.prefNotificationSetting);
      final setting = settingJson != null
          ? NotificationSetting.fromJson(
              jsonDecode(settingJson) as Map<String, dynamic>)
          : const NotificationSetting();

      // ── Tier 2: 기간 상태 로드 ─────────────────────────
      final tempStatesRaw = prefs.getString('temporary_states');
      final temporaryStates = tempStatesRaw != null
          ? (jsonDecode(tempStatesRaw) as List<dynamic>)
              .map((e) => TemporaryState.fromJson(e as Map<String, dynamic>))
              .where((s) => s.isActive)
              .toList()
          : <TemporaryState>[];

      // ── Tier 3: 오늘의 상황 로드 ───────────────────────
      final todaySitRaw = prefs.getString('today_situation');
      TodaySituation? todaySituation;
      if (todaySitRaw != null) {
        try {
          final sit = TodaySituation.fromJson(
              jsonDecode(todaySitRaw) as Map<String, dynamic>);
          if (sit.isActive) todaySituation = sit;
        } catch (_) {}
      }

      // ── 계산 ────────────────────────────────────────────
      final notifService = NotificationService();
      await notifService.initialize();

      // 공기 자체 기준만으로 계산한 결과 (Tier 1만)
      final baseResult = DustCalculator.calculate(profile, dust);
      // Tier 2/3 포함 최종 결과
      final result = DustCalculator.calculate(
        profile,
        dust,
        temporaryStates: temporaryStates,
        todaySituation: todaySituation,
      );

      final now = DateTime.now();
      final pm25 = dust.pm25Value ?? 0;
      final gradeName = _gradeLabel(DustStandards.getPm25Grade(pm25));
      final maskType = result.maskType;

      // 가장 유의미한 활성 상태명 (본문에 표기)
      final stateNote = _primaryStateNote(temporaryStates, todaySituation);
      // 공기 자체는 괜찮지만 상태 때문에 마스크 필요한 경우
      final stateOnlyMask = result.maskRequired && !baseResult.maskRequired;

      final analytics = FirebaseAnalytics.instance;

      // ── 오전 알림 ────────────────────────────────────────
      if (setting.morningAlertEnabled &&
          _inWindow(now, setting.morningAlertHour, setting.morningAlertMinute) &&
          !_sentToday(prefs, 'morning')) {
        final content = NotificationService.morningContent(
          profile: profile,
          pm25: pm25,
          gradeName: gradeName,
          maskRequired: result.maskRequired,
          maskType: maskType,
          stateNote: stateNote,
          stateOnlyMask: stateOnlyMask,
        );
        await _sendNotification(
          notifService: notifService,
          analytics: analytics,
          id: NotificationService.morningAlertId,
          type: 'morning',
          title: content.title,
          body: content.body,
          onSuccess: () => _markSent(prefs, 'morning'),
        );
      }

      // ── 전날 예보 알림 ───────────────────────────────────
      if (setting.eveningForecastEnabled &&
          _inWindow(now, setting.eveningForecastHour, setting.eveningForecastMinute) &&
          !_sentToday(prefs, 'forecast')) {
        final sido = await service.getSidoForStation(stationName);
        final forecastGrade = await service.getTomorrowForecast(sidoName: sido);
        final tomorrowGrade = forecastGrade ?? '보통';

        // 취약 상태 기준으로 내일 예보 마스크 필요 여부 재계산
        final forecastCheck = DustCalculator.forecastCheck(
          gradeName: tomorrowGrade,
          profile: profile,
          temporaryStates: temporaryStates,
        );
        // 예보에서 stateOnly 여부: 등급만으론 마스크 불필요하지만 상태로 필요
        final forecastStateOnly = forecastCheck.maskRequired &&
            !(tomorrowGrade == '나쁨' || tomorrowGrade == '매우나쁨');

        final content = NotificationService.forecastContent(
          profile: profile,
          tomorrowGrade: tomorrowGrade,
          maskType: forecastCheck.maskType,
          maskRequired: forecastCheck.maskRequired,
          stateNote: stateNote,
          stateOnlyMask: forecastStateOnly,
        );
        await _sendNotification(
          notifService: notifService,
          analytics: analytics,
          id: NotificationService.eveningForecastId,
          type: 'forecast',
          title: content.title,
          body: content.body,
          onSuccess: () => _markSent(prefs, 'forecast'),
        );
      }

      // ── 귀가 알림 ────────────────────────────────────────
      if (setting.eveningReturnEnabled &&
          _inWindow(now, setting.eveningReturnHour, setting.eveningReturnMinute) &&
          !_sentToday(prefs, 'return')) {
        final content = NotificationService.eveningReturnContent(
          profile: profile,
          gradeName: gradeName,
          maskType: maskType,
          stateNote: stateNote,
          stateOnlyMask: stateOnlyMask,
        );
        await _sendNotification(
          notifService: notifService,
          analytics: analytics,
          id: NotificationService.eveningReturnId,
          type: 'return',
          title: content.title,
          body: content.body,
          onSuccess: () => _markSent(prefs, 'return'),
        );
      }

      // ── 실시간 경보 ──────────────────────────────────────
      if (setting.realtimeAlertEnabled &&
          result.shouldSendRealtime &&
          !_sentThisHour(prefs, 'realtime')) {
        final content = NotificationService.realtimeContent(
          profile: profile,
          pm25: pm25,
          stateNote: stateNote,
        );
        await _sendNotification(
          notifService: notifService,
          analytics: analytics,
          id: NotificationService.realtimeAlertId,
          type: 'realtime',
          title: content.title,
          body: content.body,
          onSuccess: () => _markSentHour(prefs, 'realtime'),
        );
      }
    } catch (e, st) {
      debugPrint('[NotificationScheduler] 오류: $e\n$st');
      try {
        FirebaseAnalytics.instance.logEvent(name: 'notification_bg_failed');
        await FirebaseCrashlytics.instance.recordError(
          e, st,
          fatal: false,
          reason: 'background_notification_check',
        );
      } catch (_) {}
    }
  }
}

/// 알림 발송 + 성공/실패 추적
Future<void> _sendNotification({
  required NotificationService notifService,
  required FirebaseAnalytics analytics,
  required int id,
  required String type,
  required String title,
  required String body,
  required VoidCallback onSuccess,
}) async {
  try {
    await notifService.showImmediateNotification(
      id: id,
      title: title,
      body: body,
    );
    onSuccess();
    analytics.logEvent(
      name: 'notification_sent',
      parameters: {'type': type},
    );
    debugPrint('[NotificationScheduler] ✅ $type 알림 발송 성공');
  } catch (e, st) {
    debugPrint('[NotificationScheduler] ❌ $type 알림 발송 실패: $e');
    analytics.logEvent(
      name: 'notification_send_failed',
      parameters: {'type': type},
    );
    try {
      await FirebaseCrashlytics.instance.recordError(
        e, st,
        fatal: false,
        reason: 'notification_send_failed_$type',
      );
    } catch (_) {}
  }
}

bool _inWindow(DateTime now, int hour, int minute) {
  final target = DateTime(now.year, now.month, now.day, hour, minute);
  return now.difference(target).inMinutes.abs() <=
      AppConstants.notificationWindowMinutes;
}

bool _sentToday(SharedPreferences prefs, String type) {
  return prefs.getBool('notif_sent_${type}_${_dateKey()}') ?? false;
}

void _markSent(SharedPreferences prefs, String type) {
  prefs.setBool('notif_sent_${type}_${_dateKey()}', true);
}

String _dateKey() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
}

bool _sentThisHour(SharedPreferences prefs, String type) {
  return prefs.getBool('notif_sent_${type}_${_hourKey()}') ?? false;
}

void _markSentHour(SharedPreferences prefs, String type) {
  prefs.setBool('notif_sent_${type}_${_hourKey()}', true);
}

String _hourKey() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}'
      '${now.hour.toString().padLeft(2, '0')}';
}

/// 최대 [maxRetries]회 재시도. 각 시도 사이 [delaySeconds]초 대기.
Future<T?> _fetchWithRetry<T>(
  Future<T?> Function() fetch, {
  int maxRetries = 2,
  int delaySeconds = 3,
}) async {
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      final result = await fetch();
      if (result != null) return result;
    } catch (e) {
      debugPrint('[fetchWithRetry] 시도 ${attempt + 1} 실패: $e');
    }
    if (attempt < maxRetries) {
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }
  return null;
}

/// 가장 유의미한 활성 상태 이름 반환
/// 우선순위: Tier 2 (기간 상태) > Tier 3 (오늘의 상황)
String? _primaryStateNote(
    List<TemporaryState> temporaryStates, TodaySituation? todaySituation) {
  if (temporaryStates.isNotEmpty) return temporaryStates.first.label;
  if (todaySituation != null) return todaySituation.label;
  return null;
}

String _gradeLabel(DustGrade grade) {
  switch (grade) {
    case DustGrade.good:    return '좋음';
    case DustGrade.normal:  return '보통';
    case DustGrade.bad:     return '나쁨';
    case DustGrade.veryBad: return '매우나쁨';
  }
}
