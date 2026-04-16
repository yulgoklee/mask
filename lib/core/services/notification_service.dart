import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/notification_setting.dart';
import '../../data/models/user_profile.dart';

class NotificationService {
  static const String _channelId   = 'mask_alert_channel';
  static const String _channelName = '마스크 알림';
  static const String _channelDesc = '미세먼지 상태에 따른 마스크 착용 안내';

  static const int morningAlertId    = 1;
  static const int eveningForecastId = 2;
  static const int eveningReturnId   = 3;
  static const int realtimeAlertId   = 4;
  static const int simulationAlertId = 99; // Phase 4 가상 시뮬레이션 전용

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

  // ── 개인화 알림 문구 ─────────────────────────────────────

  /// 오전 외출 전 알림 메시지 (페르소나 반영)
  static String morningMessage(
    int pm25,
    String grade, {
    String? riskLabel,
    String? maskType,
    UserProfile? profile,
    String voice = NotificationVoice.friendly,
  }) {
    final name = profile?.displayName ?? '님';

    if (voice == NotificationVoice.analytical) {
      // 단호한 분석가
      if (maskType != null) {
        return '$name, 현재 PM2.5 ${pm25}μg/m³. $maskType 마스크를 반드시 착용하세요.';
      }
      return '$name, 현재 PM2.5 ${pm25}μg/m³($grade). 오늘 외출 시 주의하세요.';
    }

    // 다정한 가디언 (기본)
    final String lead;
    if (maskType != null) {
      lead = '$maskType 마스크를 챙겨보시는 건 어떨까요?';
    } else if (grade == '나쁨' || grade == '매우나쁨') {
      lead = '오늘은 마스크를 챙기시는 게 좋을 것 같아요.';
    } else {
      lead = '오늘은 마스크 없이 외출하셔도 괜찮은 것 같아요.';
    }

    return '$name, $lead (PM2.5 ${pm25}μg/m³)';
  }

  /// 전날 예보 알림 메시지 (페르소나 반영)
  static String forecastMessage(
    String tomorrowGrade, {
    String? riskLabel,
    UserProfile? profile,
    String voice = NotificationVoice.friendly,
  }) {
    final name = profile?.displayName ?? '님';

    if (voice == NotificationVoice.analytical) {
      return '$name, 내일 미세먼지 예보: $tomorrowGrade. '
          '${_isBad(tomorrowGrade) ? "마스크를 반드시 준비하세요." : "야외 활동에 문제 없습니다."}';
    }

    final String lead = _isBad(tomorrowGrade)
        ? '내일은 마스크를 꼭 챙기시면 좋겠어요!'
        : '내일은 마스크 없이 외출 가능한 것 같아요.';
    return '$name, $lead 내일 예보: $tomorrowGrade';
  }

  /// 귀가 전 알림 메시지 (페르소나 반영)
  static String eveningReturnMessage(
    String grade, {
    String? riskLabel,
    String? maskType,
    UserProfile? profile,
    String voice = NotificationVoice.friendly,
  }) {
    final name = profile?.displayName ?? '님';

    if (voice == NotificationVoice.analytical) {
      if (maskType != null) {
        return '$name, 귀가 시 $maskType 마스크를 착용하세요. 현재: $grade';
      }
      return '$name, 퇴근 시간 미세먼지: $grade.';
    }

    final String lead;
    if (maskType != null) {
      lead = '귀가 시 $maskType 마스크를 챙겨보세요!';
    } else if (_isBad(grade)) {
      lead = '귀가 시 마스크를 챙기시는 게 좋을 것 같아요.';
    } else {
      lead = '퇴근 시간 공기가 괜찮은 것 같아요.';
    }

    return '$name, $lead 현재: $grade';
  }

  /// Phase 4: 가상 시뮬레이션 알림
  static String simulationMessage({
    required UserProfile profile,
    required NotificationSetting setting,
  }) {
    final name = profile.displayName;
    final timeStr =
        '${setting.morningAlertHour.toString().padLeft(2, '0')}:'
        '${setting.morningAlertMinute.toString().padLeft(2, '0')}';
    final voice = setting.notificationVoice;

    if (voice == NotificationVoice.analytical) {
      return '$name의 안전 기준선은 ${profile.tFinal.toStringAsFixed(0)}μg/m³입니다. '
          '내일 $timeStr에 첫 보고서를 전달하겠습니다.';
    }

    return '설정하신 대로 내일 아침 $timeStr에 첫 보고서를 들고 올게요! '
        '$name의 기준선(${profile.tFinal.toStringAsFixed(0)}μg/m³)을 기준으로 챙겨드릴게요. 😊';
  }

  static bool _isBad(String grade) =>
      grade == '나쁨' || grade == '매우나쁨';
}
