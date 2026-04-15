import 'dart:convert';
import 'dart:ui' show Color;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidNotificationAction;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/feedback_repository.dart';
import '../../data/models/forecast_models.dart';
import '../../data/models/notification_feedback.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/dust_standards.dart';
import '../utils/adaptive_learner.dart';
import '../utils/dust_calculator.dart';
import '../utils/sensitivity_calculator.dart';
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

      // ── 설정·시간 윈도우 선체크 (API 호출 전) ──────────────
      // 배터리 절약: 발송할 알림이 없는 시간대는 API 호출 없이 즉시 종료
      final settingJson = prefs.getString(AppConstants.prefNotificationSetting);
      final setting = settingJson != null
          ? NotificationSetting.fromJson(
              jsonDecode(settingJson) as Map<String, dynamic>)
          : const NotificationSetting();

      final now = DateTime.now();

      // ── 무응답 처리 + 학습 평가 ─────────────────────────────
      // 스누즈 여부와 무관하게 항상 먼저 실행:
      //   - 이전 알림 무응답 → ignored 기록
      //   - 피드백 데이터로 sOffset 재계산
      // (알림을 끄더라도 학습은 계속 누적되어야 함)
      final feedbackRepo = FeedbackRepository(prefs);
      await feedbackRepo.resolveIgnoredIfAny();
      await AdaptiveLearner.evaluate(prefs, feedbackRepo);

      // ── "오늘 끄기" 스누즈 체크 ─────────────────────────────
      // 학습 처리 후에 스누즈 여부를 판단
      if (_isSnoozedToday(prefs, now)) {
        debugPrint('[NotificationScheduler] 오늘 끄기 활성 — 예약 알림 건너뜀');
        // 실시간·급변은 스누즈와 무관하게 계속 처리
        if (!setting.realtimeAlertEnabled) return;
      }

      final needsScheduledAlert = _needsAnyScheduledAlert(prefs, setting, now);
      // 실시간·급변 알림이 꺼져 있고 예약 알림도 없으면 바로 종료
      if (!setting.realtimeAlertEnabled && !needsScheduledAlert) {
        debugPrint('[NotificationScheduler] 발송 대상 없음 — 조기 종료');
        return;
      }

      final profileJson = prefs.getString(AppConstants.prefUserProfile);
      final profile = profileJson != null
          ? UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>)
          : UserProfile.defaultProfile();

      // Cloud Functions URL이 설정된 경우 서버 프록시 사용 (API 키 보안)
      // 미설정 시 직접 호출로 폴백 (개발 환경 등)
      final DustDataSource service =
          AppConfig.cloudFunctionsBaseUrl.isNotEmpty
              ? CloudFunctionsDataSource()
              : AirKoreaService(prefs);

      // 네트워크 실패 시 최대 2회 재시도 → 그래도 실패 시 로컬 캐시로 폴백
      // AirKoreaService는 내부적으로 캐시를 관리하므로,
      // CloudFunctions 실패 시에도 캐시 데이터가 있으면 알림 발송 가능.
      var dust = await _fetchWithRetry(() => service.getDustData(stationName));
      if (dust == null) {
        // Fallback: AirKorea 캐시에서 마지막 유효 데이터 시도
        dust = await _fetchWithRetry(
          () => AirKoreaService(prefs).getDustData(stationName),
          maxRetries: 0, // 캐시 조회이므로 재시도 불필요
        );
      }
      if (dust == null) {
        debugPrint('[NotificationScheduler] 데이터 조회 실패 (캐시 포함) — 알림 건너뜀');
        return;
      }

      // ── Tier 2: 기간 상태 로드 ─────────────────────────
      final tempStatesRaw = prefs.getString('temporary_states');
      final temporaryStates = tempStatesRaw != null
          ? (jsonDecode(tempStatesRaw) as List<dynamic>)
              .map((e) => TemporaryState.fromJson(e as Map<String, dynamic>))
              .where((s) => s.isActive)
              .toList()
          : <TemporaryState>[];

      // ── Tier 3: 오늘의 상황 로드 (List) ──────────────────
      final todaySitRaw = prefs.getString('today_situation');
      List<TodaySituation> todaySituations = [];
      if (todaySitRaw != null) {
        try {
          final decoded = jsonDecode(todaySitRaw);
          if (decoded is Map<String, dynamic>) {
            // 이전 버전 호환: 단일 객체
            final sit = TodaySituation.fromJson(decoded);
            if (sit.isActive) todaySituations = [sit];
          } else if (decoded is List) {
            todaySituations = decoded
                .map((e) => TodaySituation.fromJson(e as Map<String, dynamic>))
                .where((s) => s.isActive)
                .toList();
          }
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
        todaySituations: todaySituations,
      );

      final pm25 = dust.pm25Value ?? 0;
      final gradeName = _gradeLabel(DustStandards.getPm25Grade(pm25));
      final maskType = result.maskType;

      // 가장 유의미한 활성 상태명 (본문에 표기)
      final stateNote = _primaryStateNote(temporaryStates, todaySituations);
      // 공기 자체는 괜찮지만 상태 때문에 마스크 필요한 경우
      final stateOnlyMask = result.maskRequired && !baseResult.maskRequired;

      // ── 개인 임계치(T_final) 트리거 여부 계산 ─────────────────
      // sOffset(학습 조정값)을 반영한 S_eff 기반으로 임계치 계산
      // T_final triggered = 개인 기준선 초과 AND 표준 '나쁨' 미달
      final s    = SensitivityCalculator.compute(profile);
      final sEff = AdaptiveLearner.effectiveS(s, prefs);   // sOffset 반영
      final tFinalValue = sEff >= SensitivityCalculator.sThreshold
          ? AdaptiveLearner.effectiveThreshold(s, prefs)
          : null;
      final tFinalTriggered = tFinalValue != null &&
          pm25.toDouble() >= tFinalValue &&
          pm25 <= DustStandards.pm25Normal;

      debugPrint('[NotificationScheduler] S=$s sEff=$sEff '
          'T_eff=${tFinalValue?.toStringAsFixed(1)} '
          '${AdaptiveLearner.debugSummary(prefs)}');

      final analytics = FirebaseAnalytics.instance;

      // ── 마스크 알림 발송 전 PM2.5 컨텍스트 저장 ─────────────────
      // "챙겼어요" 탭 시 배경 isolate가 이 값을 읽어 DefenseRecord 생성
      if (result.maskRequired) {
        await prefs.setInt(NotificationService.prefLastNotifPm25, pm25);
        await prefs.setString(
          NotificationService.prefLastNotifMaskType,
          maskType ?? 'KF80',
        );
        // 피드백 수집: 발송 이후 응답 대기 등록
        final notifId = DateTime.now().millisecondsSinceEpoch.toString();
        await feedbackRepo.markPending(notifId, DateTime.now(), pm25);
      }

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
          tFinalTriggered: tFinalTriggered,
          tFinal: tFinalValue,
        );
        await _sendNotification(
          notifService: notifService,
          analytics: analytics,
          id: NotificationService.morningAlertId,
          type: 'morning',
          title: content.title,
          body: content.body,
          gradeColor: NotificationService.colorForGrade(gradeName),
          actions: result.maskRequired
              ? NotificationService.maskActions
              : null,
          iosCategory: result.maskRequired
              ? NotificationService.categoryMask
              : null,
          smallIcon: result.maskRequired
              ? NotificationService.iconMask
              : null,
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
          gradeColor: NotificationService.colorForGrade(tomorrowGrade),
          actions: forecastCheck.maskRequired
              ? NotificationService.maskActions
              : null,
          iosCategory: forecastCheck.maskRequired
              ? NotificationService.categoryMask
              : null,
          smallIcon: forecastCheck.maskRequired
              ? NotificationService.iconMask
              : null,
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
          tFinalTriggered: tFinalTriggered,
          tFinal: tFinalValue,
        );
        final returnMaskRequired = stateNote != null ||
            gradeName == '나쁨' || gradeName == '매우나쁨';
        await _sendNotification(
          notifService: notifService,
          analytics: analytics,
          id: NotificationService.eveningReturnId,
          type: 'return',
          title: content.title,
          body: content.body,
          gradeColor: NotificationService.colorForGrade(gradeName),
          actions: returnMaskRequired
              ? NotificationService.maskActions
              : null,
          iosCategory: returnMaskRequired
              ? NotificationService.categoryMask
              : null,
          smallIcon: returnMaskRequired
              ? NotificationService.iconMask
              : null,
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
          gradeColor: NotificationService.colorForGrade('매우나쁨'),
          actions: NotificationService.alertActions,
          iosCategory: NotificationService.categoryAlert,
          smallIcon: NotificationService.iconWarning,
          onSuccess: () => _markSentHour(prefs, 'realtime'),
        );
      }

      // ── 기상 급변 선제 알림 ──────────────────────────────
      // 이미 매우나쁨이면 실시간 경보가 커버; 급증 예측은 아직 괜찮을 때만 의미 있음
      if (setting.realtimeAlertEnabled &&
          pm25 <= DustStandards.pm25Bad &&
          !_sentThisHour(prefs, 'surge')) {
        await _checkSurgeAlert(
          prefs: prefs,
          service: service,
          stationName: stationName,
          notifService: notifService,
          analytics: analytics,
          profile: profile,
          currentPm25: pm25,
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
///
/// [gradeColor]  : 등급 기반 Android 알림 액센트 색상 (선택)
/// [actions]     : Android 알림 액션 버튼 목록 (선택)
/// [iosCategory] : iOS 알림 카테고리 ID (선택)
/// [smallIcon]   : Android 소형 알림 아이콘 리소스명 (선택)
Future<void> _sendNotification({
  required NotificationService notifService,
  required FirebaseAnalytics analytics,
  required int id,
  required String type,
  required String title,
  required String body,
  Color? gradeColor,
  List<AndroidNotificationAction>? actions,
  String? iosCategory,
  String? smallIcon,
  required VoidCallback onSuccess,
}) async {
  try {
    await notifService.showImmediateNotification(
      id: id,
      title: title,
      body: body,
      gradeColor: gradeColor,
      actions: actions,
      iosCategory: iosCategory,
      smallIcon: smallIcon,
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

/// "오늘 끄기"가 오늘 활성화되어 있는지 확인
bool _isSnoozedToday(SharedPreferences prefs, DateTime now) {
  final snoozedDate = prefs.getString(NotificationService.prefSnoozedDate);
  if (snoozedDate == null) return false;
  final today = '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  return snoozedDate == today;
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
/// [maxRetries]=0 이면 단 1회 시도 (캐시 조회 등에서 사용).
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

// ── 기상 급변 선제 알림 ────────────────────────────────────

/// 급증 감지 최소 상승 속도 (μg/m³/h)
/// 7 μg/m³/h ≈ 1시간 후 보통→나쁨 경계 돌파 가능 수준
const double _kSurgeRateThreshold = 7.0;

/// 급증 감지 결과
class _SurgeResult {
  final int currentPm25;
  final String targetGrade; // '나쁨' | '매우나쁨'
  const _SurgeResult({required this.currentPm25, required this.targetGrade});
}

/// 시간별 과거 데이터로 1시간 내 등급 악화 여부를 예측
///
/// 알고리즘:
/// 1. 실측 데이터(non-forecast) 마지막 2개 포인트 추출
/// 2. 시간당 변화율(ratePerHour) 계산
/// 3. rate ≥ [_kSurgeRateThreshold] 이면 1시간 후 값 예측
/// 4. 등급 경계(보통→나쁨, 나쁨→매우나쁨) 돌파 예상 시 결과 반환
_SurgeResult? _detectSurge(List<HourlyDustData> history, int currentPm25) {
  final measurements = history
      .where((h) => !h.isForecast && h.pm25 != null)
      .toList();
  if (measurements.length < 2) return null;

  final latest = measurements.last;
  final prev = measurements[measurements.length - 2];

  final diffMins = latest.time.difference(prev.time).inMinutes;
  if (diffMins <= 0 || diffMins > 180) return null; // 데이터 간격 이상

  final ratePerHour = (latest.pm25! - prev.pm25!) * 60.0 / diffMins;
  if (ratePerHour < _kSurgeRateThreshold) return null; // 상승 속도 미달

  final projected = currentPm25 + ratePerHour.round();

  // 보통 → 나쁨 예상 (≤35 → >35)
  if (currentPm25 <= DustStandards.pm25Normal &&
      projected > DustStandards.pm25Normal) {
    return _SurgeResult(currentPm25: currentPm25, targetGrade: '나쁨');
  }
  // 나쁨 → 매우나쁨 예상 (≤75 → >75)
  if (currentPm25 > DustStandards.pm25Normal &&
      currentPm25 <= DustStandards.pm25Bad &&
      projected > DustStandards.pm25Bad) {
    return _SurgeResult(currentPm25: currentPm25, targetGrade: '매우나쁨');
  }
  return null;
}

/// 급증 선제 알림 실행
/// 실패해도 메인 알림 체크에 영향 없도록 내부에서 예외를 흡수
Future<void> _checkSurgeAlert({
  required SharedPreferences prefs,
  required DustDataSource service,
  required String stationName,
  required NotificationService notifService,
  required FirebaseAnalytics analytics,
  required UserProfile profile,
  required int currentPm25,
}) async {
  try {
    final history = await service.getHourlyHistory(stationName);
    final surge = _detectSurge(history, currentPm25);
    if (surge == null) return;

    final content = NotificationService.surgeContent(
      profile: profile,
      currentPm25: surge.currentPm25,
      targetGrade: surge.targetGrade,
    );
    await _sendNotification(
      notifService: notifService,
      analytics: analytics,
      id: NotificationService.surgeAlertId,
      type: 'surge',
      title: content.title,
      body: content.body,
      gradeColor: NotificationService.colorForGrade(surge.targetGrade),
      actions: NotificationService.alertActions,
      iosCategory: NotificationService.categoryAlert,
      smallIcon: NotificationService.iconWarning,
      onSuccess: () => _markSentHour(prefs, 'surge'),
    );
  } catch (e) {
    debugPrint('[NotificationScheduler] 급증 감지 오류 (무시): $e');
  }
}

/// 지금 시각에 발송해야 할 예약 알림(아침/예보/귀가)이 하나라도 있는지 확인
///
/// 실시간·급변 알림은 시간 무관 → 이 함수 대상 아님 (호출 측에서 별도 처리).
/// 이미 오늘 발송됐으면 윈도우 내라도 false 반환 (중복 발송 방지).
bool _needsAnyScheduledAlert(
    SharedPreferences prefs, NotificationSetting setting, DateTime now) {
  if (setting.morningAlertEnabled &&
      _inWindow(now, setting.morningAlertHour, setting.morningAlertMinute) &&
      !_sentToday(prefs, 'morning')) return true;

  if (setting.eveningForecastEnabled &&
      _inWindow(now, setting.eveningForecastHour, setting.eveningForecastMinute) &&
      !_sentToday(prefs, 'forecast')) return true;

  if (setting.eveningReturnEnabled &&
      _inWindow(now, setting.eveningReturnHour, setting.eveningReturnMinute) &&
      !_sentToday(prefs, 'return')) return true;

  return false;
}

/// 가장 유의미한 활성 상태 이름 반환
/// 우선순위: Tier 2 (기간 상태) > Tier 3 (오늘의 상황)
String? _primaryStateNote(
    List<TemporaryState> temporaryStates,
    List<TodaySituation> todaySituations) {
  if (temporaryStates.isNotEmpty) return temporaryStates.first.label;
  if (todaySituations.isNotEmpty) return todaySituations.first.label;
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
