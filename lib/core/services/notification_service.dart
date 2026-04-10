import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/user_profile.dart';

/// 알림 제목 + 본문 묶음 (배달앱 카드 스타일)
class NotificationContent {
  final String title;
  final String body;
  const NotificationContent({required this.title, required this.body});
}

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

  // ── 알림 콘텐츠 생성 (배달앱 카드 스타일) ──────────────────

  /// 아침 알림 — 오늘 마스크 여부
  ///
  /// [stateNote]   : 활성 취약 상태 이름 ("임신 중", "야외 운동 예정" 등)
  /// [stateOnlyMask]: true = 공기는 괜찮지만 상태 때문에 마스크 필요
  static NotificationContent morningContent({
    required UserProfile profile,
    required int pm25,
    required String gradeName,
    required bool maskRequired,
    String? maskType,
    String? stateNote,
    bool stateOnlyMask = false,
  }) {
    final name = profile.displayName;

    // 이모지: 공기는 괜찮지만 취약 상태 → 🛡️, 공기 나쁨 → 😷, 안전 → ✅
    final emoji = maskRequired
        ? (stateOnlyMask ? '🛡️' : '😷')
        : '✅';

    final title = maskRequired
        ? '$emoji $name, 오늘 마스크 챙기세요'
        : '✅ $name, 오늘은 마스크 없어도 돼요';

    final lines = <String>[];

    // 취약 상태가 있을 때 첫 줄에 이유 표기
    if (stateNote != null) {
      lines.add(maskType != null
          ? '$stateNote · $maskType 이상 권장'
          : stateNote);
    } else if (maskType != null) {
      lines.add('$maskType 이상 권장');
    }

    lines.add('PM2.5 $pm25μg/m³ · $gradeName');

    // stateNote 없을 때만 Tier 1 personalNote 추가
    if (stateNote == null) {
      final note = _personalNote(profile);
      if (note != null) lines.add(note);
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 저녁 예보 알림 — 내일 마스크 여부
  ///
  /// [maskRequired] : 취약 상태 포함 최종 마스크 필요 여부 (null이면 등급만으로 판단)
  /// [stateNote]    : 활성 취약 상태 이름
  /// [stateOnlyMask]: true = 공기 등급은 괜찮지만 상태 때문에 마스크 필요
  static NotificationContent forecastContent({
    required UserProfile profile,
    required String tomorrowGrade,
    String? maskType,
    bool? maskRequired,
    String? stateNote,
    bool stateOnlyMask = false,
  }) {
    final name = profile.displayName;

    // maskRequired 재정의가 없으면 등급 기반 판단 (기존 로직)
    final isBad = maskRequired ??
        (tomorrowGrade == '나쁨' || tomorrowGrade == '매우나쁨');

    final emoji = isBad ? (stateOnlyMask ? '🛡️' : '🌆') : '🌤';
    final title = isBad
        ? '$emoji $name, 내일 외출 준비 — 마스크 필요해요'
        : '🌤 $name, 내일 공기는 괜찮아요';

    final lines = <String>['내일 예보: $tomorrowGrade'];

    if (isBad) {
      if (stateNote != null) {
        lines.add(maskType != null
            ? '$stateNote · $maskType 이상 권장'
            : '$stateNote · 마스크 권장');
      } else if (maskType != null) {
        lines.add('$maskType 이상 권장');
      } else {
        lines.add('마스크 미리 챙겨두세요');
      }
    } else {
      lines.add('마스크 없이 외출해도 좋아요');
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 귀가 알림 — 퇴근길 공기 상태
  ///
  /// [stateNote]   : 활성 취약 상태 이름
  static NotificationContent eveningReturnContent({
    required UserProfile profile,
    required String gradeName,
    String? maskType,
    String? stateNote,
    bool stateOnlyMask = false,
  }) {
    final name = profile.displayName;
    final isBad = gradeName == '나쁨' || gradeName == '매우나쁨';

    // 상태 때문에 마스크 필요하면 등급 무관 "챙기세요"
    final maskRequired = stateNote != null || isBad;

    final title = maskRequired
        ? '🏠 $name, 퇴근길 마스크 챙기세요'
        : '🏠 $name, 퇴근길 공기 괜찮아요';

    final lines = <String>['현재 PM2.5: $gradeName'];

    if (maskRequired) {
      if (stateNote != null) {
        lines.add(maskType != null
            ? '$stateNote · $maskType 착용 권고'
            : '$stateNote · 마스크 착용 권고');
      } else {
        lines.add(maskType != null ? '$maskType 착용 권고' : '마스크 착용을 권장해요');
      }
    } else {
      lines.add('오늘 수고하셨어요 😊');
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 실시간 급등 알림
  ///
  /// [stateNote] : 활성 취약 상태 이름 (있으면 더 강한 경고)
  static NotificationContent realtimeContent({
    required UserProfile profile,
    required int pm25,
    String? stateNote,
  }) {
    final name = profile.displayName;
    final extraLine = stateNote != null ? '\n$stateNote · 즉시 마스크 착용' : '';
    return NotificationContent(
      title: '🚨 $name, 미세먼지 갑자기 나빠졌어요',
      body: 'PM2.5 $pm25μg/m³ · 매우나쁨\n야외 활동 즉시 중단 권고$extraLine',
    );
  }

  // ── 내부 헬퍼 ─────────────────────────────────────────────

  static String? _personalNote(UserProfile profile) {
    if (profile.hasCondition) return '${profile.conditionType.label} 기준 적용';
    if (profile.ageGroup.isVulnerable) return '${profile.ageGroup.label} 민감 연령 기준';
    if (profile.sensitivity == SensitivityLevel.high) return '고민감도 기준 적용';
    return null;
  }
}
