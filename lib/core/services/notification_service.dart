import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const String _channelId = 'mask_alert_channel';
  static const String _channelName = '마스크 알림';
  static const String _channelDesc = '미세먼지 상태에 따른 마스크 착용 안내';

  static const int morningAlertId = 1;
  static const int eveningForecastId = 2;
  static const int eveningReturnId = 3;
  static const int realtimeAlertId = 4;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── 알림 문구 ──────────────────────────────────────────

  static String morningMessage(int pm25, String grade,
      {String? riskLabel, String? maskType}) {
    // 마스크 여부 → 농도 → 위험도 순
    final String lead;
    if (maskType != null) {
      lead = '$maskType 마스크를 착용하세요!';
    } else if (grade == '나쁨' || grade == '매우나쁨') {
      lead = '외출 시 마스크를 착용하세요!';
    } else {
      lead = '오늘은 마스크 없이 외출 가능해요.';
    }
    final detail = 'PM2.5 $pm25μg/m³(${grade})';
    final risk = riskLabel != null ? '나의 위험도: $riskLabel' : '';
    return '$lead $detail${risk.isNotEmpty ? ' / $risk' : ''}';
  }

  static String forecastMessage(String tomorrowGrade,
      {String? riskLabel}) {
    final String lead = (tomorrowGrade == '나쁨' || tomorrowGrade == '매우나쁨')
        ? '내일은 마스크를 꼭 챙기세요!'
        : '내일은 마스크 없이 외출 가능해요.';
    final risk = riskLabel != null ? ' / 나의 위험도: $riskLabel' : '';
    return '$lead 내일 예보: $tomorrowGrade$risk';
  }

  static String eveningReturnMessage(String grade,
      {String? riskLabel, String? maskType}) {
    final String lead;
    if (maskType != null) {
      lead = '귀가 시 $maskType 마스크를 착용하세요!';
    } else if (grade == '나쁨' || grade == '매우나쁨') {
      lead = '귀가 시 마스크를 착용하세요!';
    } else {
      lead = '퇴근 시간 공기가 괜찮아요.';
    }
    final detail = '현재 미세먼지: $grade';
    final risk = riskLabel != null ? '나의 위험도: $riskLabel' : '';
    return '$lead $detail${risk.isNotEmpty ? ' / $risk' : ''}';
  }
}
