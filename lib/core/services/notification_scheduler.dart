import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/notification_setting.dart';
import '../constants/app_constants.dart';
import '../constants/dust_standards.dart';
import '../utils/dust_calculator.dart';
import 'air_korea_service.dart';
import 'notification_service.dart';

/// 미세먼지 알림 스케줄러
/// 백그라운드 서비스에서 호출되는 알림 발송 로직을 캡슐화
class NotificationScheduler {
  Future<void> runCheck(SharedPreferences prefs) async {
    try {
      final stationName = prefs.getString(AppConstants.prefStationName);
      if (stationName == null) return;

      final service = AirKoreaService(prefs);
      final dust = await service.getDustData(stationName);
      if (dust == null) return;

      final profileJson = prefs.getString(AppConstants.prefUserProfile);
      final profile = profileJson != null
          ? UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>)
          : UserProfile.defaultProfile();

      final settingJson = prefs.getString(AppConstants.prefNotificationSetting);
      final setting = settingJson != null
          ? NotificationSetting.fromJson(
              jsonDecode(settingJson) as Map<String, dynamic>)
          : const NotificationSetting();

      final notifService = NotificationService();
      await notifService.initialize();

      final result = DustCalculator.calculate(profile, dust);
      final now = DateTime.now();
      final pm25 = dust.pm25Value ?? 0;
      final gradeName = _gradeLabel(DustStandards.getPm25Grade(pm25));

      final riskLabel = result.riskLevel.label;
      final maskType = result.maskType;

      // ── 오전 알림 ────────────────────────────────────────
      if (setting.morningAlertEnabled &&
          _inWindow(now, setting.morningAlertHour, setting.morningAlertMinute) &&
          !_sentToday(prefs, 'morning')) {
        await notifService.showImmediateNotification(
          id: NotificationService.morningAlertId,
          title: '오늘 미세먼지 안내',
          body: NotificationService.morningMessage(pm25, gradeName,
              riskLabel: riskLabel, maskType: maskType),
        );
        _markSent(prefs, 'morning');
      }

      // ── 전날 예보 알림 ───────────────────────────────────
      if (setting.eveningForecastEnabled &&
          _inWindow(now, setting.eveningForecastHour, setting.eveningForecastMinute) &&
          !_sentToday(prefs, 'forecast')) {
        final sido = await service.getSidoForStation(stationName);
        final forecastGrade = await service.getTomorrowForecast(sidoName: sido);
        await notifService.showImmediateNotification(
          id: NotificationService.eveningForecastId,
          title: '내일 미세먼지 예보',
          body: NotificationService.forecastMessage(forecastGrade ?? '보통',
              riskLabel: riskLabel),
        );
        _markSent(prefs, 'forecast');
      }

      // ── 귀가 알림 ────────────────────────────────────────
      if (setting.eveningReturnEnabled &&
          _inWindow(now, setting.eveningReturnHour, setting.eveningReturnMinute) &&
          !_sentToday(prefs, 'return')) {
        await notifService.showImmediateNotification(
          id: NotificationService.eveningReturnId,
          title: '귀가 전 미세먼지 확인',
          body: NotificationService.eveningReturnMessage(gradeName,
              riskLabel: riskLabel, maskType: maskType),
        );
        _markSent(prefs, 'return');
      }

      // ── 실시간 경보 ──────────────────────────────────────
      // 동일 시간대(1시간 단위) 중복 발송 방지
      if (setting.realtimeAlertEnabled &&
          result.shouldSendRealtime &&
          !_sentThisHour(prefs, 'realtime')) {
        await notifService.showImmediateNotification(
          id: NotificationService.realtimeAlertId,
          title: '⚠️ 미세먼지 경보',
          body: result.message,
        );
        _markSentHour(prefs, 'realtime');
      }
    } catch (e, st) {
      debugPrint('[NotificationScheduler] 오류: $e\n$st');
    }
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

String _gradeLabel(DustGrade grade) {
  switch (grade) {
    case DustGrade.good:    return '좋음';
    case DustGrade.normal:  return '보통';
    case DustGrade.bad:     return '나쁨';
    case DustGrade.veryBad: return '매우나쁨';
  }
}
