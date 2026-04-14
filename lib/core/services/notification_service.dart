import 'dart:io';
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/user_profile.dart';

/// 알림 제목 + 본문 묶음
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
  static const int surgeAlertId = 5;

  /// 등급별 Android 알림 액센트 색상
  ///
  /// 알림 트레이에서 등급을 색으로 즉시 인지할 수 있도록 한다.
  static const Map<String, Color> _gradeColors = {
    '좋음':    Color(0xFF4CAF50), // green
    '보통':    Color(0xFF42A5F5), // blue
    '나쁨':    Color(0xFFFF7043), // deep orange
    '매우나쁨': Color(0xFFEF5350), // red
  };

  /// 등급 이름으로 Android 알림 액센트 색상 반환
  static Color? colorForGrade(String gradeName) => _gradeColors[gradeName];

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

  /// 알림 즉시 발송
  ///
  /// [gradeColor] : 등급 기반 Android 알림 액센트 색상.
  ///               [colorForGrade] 헬퍼로 얻어 전달하면 등급별 색상이 적용된다.
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    Color? gradeColor,
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
          color: gradeColor,
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

  // ── 알림 콘텐츠 생성 — Action First 원칙 ─────────────────────
  //
  // 원칙: 제목 = 지금 당장 해야 할 행동 (마스크 종류 포함)
  //       본문 = 행동의 근거 (PM2.5 수치·등급·상태)
  //
  // "KF80 챙기세요" 처럼 제목만 봐도 무엇을 해야 하는지 명확하게.

  /// 아침 알림 — 오늘 마스크 여부
  ///
  /// [stateNote]    : 활성 취약 상태 이름 ("임신 중", "야외 운동 예정" 등)
  /// [stateOnlyMask]: 공기는 괜찮지만 취약 상태 때문에 마스크 필요할 때 true
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

    // ── 제목: Action First ──────────────────────────────────────
    final String title;
    if (maskRequired) {
      final emoji = stateOnlyMask ? '🛡️' : '😷';
      // 마스크 종류가 있으면 제목에 포함 → 즉각적인 행동 단서 제공
      final action = maskType != null ? '$maskType 챙기세요' : '마스크 챙기세요';
      title = '$emoji $name, $action';
    } else {
      title = '✅ $name, 오늘 쾌적해요';
    }

    // ── 본문: PM2.5 데이터 → 상태 컨텍스트 순 ─────────────────────
    final lines = <String>[];
    lines.add('PM2.5 $pm25μg/m³ · $gradeName');

    if (stateNote != null) {
      lines.add(maskRequired
          ? '$stateNote · 착용 권고'
          : stateNote);
    } else if (maskRequired && maskType != null) {
      lines.add('$maskType 이상 착용 권고');
    } else if (!maskRequired) {
      lines.add('마스크 없이 외출 가능해요');
    }

    if (stateNote == null) {
      final note = _personalNote(profile);
      if (note != null) lines.add(note);
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 저녁 예보 알림 — 내일 마스크 여부
  ///
  /// [maskRequired] : 취약 상태 포함 최종 마스크 필요 여부 (null이면 등급으로 판단)
  /// [stateNote]    : 활성 취약 상태 이름
  /// [stateOnlyMask]: 공기 등급은 괜찮지만 상태 때문에 마스크 필요할 때 true
  static NotificationContent forecastContent({
    required UserProfile profile,
    required String tomorrowGrade,
    String? maskType,
    bool? maskRequired,
    String? stateNote,
    bool stateOnlyMask = false,
  }) {
    final name = profile.displayName;
    final isBad = maskRequired ??
        (tomorrowGrade == '나쁨' || tomorrowGrade == '매우나쁨');

    // ── 제목 ────────────────────────────────────────────────────
    final String title;
    if (isBad) {
      final emoji = stateOnlyMask ? '🛡️' : '🌆';
      final action = maskType != null ? '내일 $maskType 챙기세요' : '내일 마스크 챙기세요';
      title = '$emoji $name, $action';
    } else {
      title = '🌤 $name, 내일 공기 좋아요';
    }

    // ── 본문 ────────────────────────────────────────────────────
    final lines = <String>['내일 PM2.5 예보: $tomorrowGrade'];

    if (isBad) {
      if (stateNote != null) {
        lines.add('$stateNote · ${maskType != null ? "$maskType 이상 권장" : "마스크 권장"}');
      } else {
        lines.add(maskType != null ? '$maskType 이상 미리 준비하세요' : '마스크 미리 챙겨두세요');
      }
    } else {
      lines.add('마스크 없이 외출해도 좋아요');
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 귀가 알림 — 퇴근길 공기 상태
  ///
  /// [stateNote] : 활성 취약 상태 이름
  static NotificationContent eveningReturnContent({
    required UserProfile profile,
    required String gradeName,
    String? maskType,
    String? stateNote,
    bool stateOnlyMask = false,
  }) {
    final name = profile.displayName;
    final isBad = gradeName == '나쁨' || gradeName == '매우나쁨';
    final maskRequired = stateNote != null || isBad;

    // ── 제목 ────────────────────────────────────────────────────
    final String title;
    if (maskRequired) {
      final action = maskType != null ? '퇴근길 $maskType 챙기세요' : '퇴근길 마스크 챙기세요';
      title = '🏠 $name, $action';
    } else {
      title = '🏠 $name, 퇴근길 공기 좋아요';
    }

    // ── 본문 ────────────────────────────────────────────────────
    final lines = <String>['PM2.5 $gradeName'];

    if (maskRequired) {
      if (stateNote != null) {
        lines.add('$stateNote · ${maskType != null ? "$maskType 착용 권고" : "마스크 착용 권고"}');
      } else {
        lines.add(maskType != null ? '$maskType 착용 권고' : '마스크 착용을 권장해요');
      }
    } else {
      lines.add('오늘 수고하셨어요 😊');
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 실시간 경보 — 현재 매우나쁨 돌파 시 즉시 발송
  ///
  /// [stateNote] : 활성 취약 상태 이름 (있으면 더 강한 경고)
  static NotificationContent realtimeContent({
    required UserProfile profile,
    required int pm25,
    String? stateNote,
  }) {
    final name = profile.displayName;

    // 매우나쁨 = KF94 필수 → 제목에 마스크 종류 명시
    final title = '🚨 $name, KF94 지금 쓰세요';
    final lines = <String>['PM2.5 $pm25μg/m³ · 매우나쁨 · 야외 즉시 중단'];
    if (stateNote != null) lines.add('$stateNote · 즉시 착용');

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 기상 급변 선제 알림 — 현재는 괜찮지만 1시간 내 등급 악화 예상
  ///
  /// [currentPm25] : 현재 PM2.5 μg/m³
  /// [targetGrade] : 예상 도달 등급 ('나쁨' | '매우나쁨')
  static NotificationContent surgeContent({
    required UserProfile profile,
    required int currentPm25,
    required String targetGrade,
  }) {
    final name = profile.displayName;
    final isSevere = targetGrade == '매우나쁨';

    // 예상 등급에 맞는 마스크 종류를 제목에 포함
    final maskHintTitle = isSevere ? 'KF94 미리 챙기세요' : 'KF80 미리 챙기세요';
    final title = '⚡ $name, $maskHintTitle';

    final maskHintBody = isSevere
        ? 'KF94 착용을 강력 권고해요'
        : '외출 전 마스크를 꼭 챙기세요';

    return NotificationContent(
      title: title,
      body: 'PM2.5 $currentPm25μg/m³ → 1시간 내 $targetGrade 예상\n$maskHintBody',
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
