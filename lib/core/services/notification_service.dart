import 'dart:io';
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/datasources/defense_repository.dart';
import '../../data/datasources/feedback_repository.dart';
import '../../data/models/defense_record.dart';
import '../../data/models/notification_feedback.dart';
import '../../data/models/user_profile.dart';

/// 배경 isolate: 알림 액션 버튼 탭 처리
///
/// ┌────────────────────────────────────────────────────────┐
/// │ actionAcknowledge ("챙겼어요")                          │
/// │  → DefenseRecord 생성 + 저장                            │
/// │  → FeedbackType.acknowledged 기록                      │
/// │                                                        │
/// │ actionSnoozeToday ("오늘 끄기")                         │
/// │  → prefSnoozedDate 에 오늘 날짜 저장                     │
/// │  → FeedbackType.snoozed 기록                           │
/// │  → 스케줄러가 당일 모든 예약 알림 건너뜀                   │
/// └────────────────────────────────────────────────────────┘
///
/// top-level 함수 제약: Riverpod 사용 불가 → SharedPreferences 직접 접근.
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final pm25  = prefs.getInt(NotificationService.prefLastNotifPm25) ?? 0;

    if (response.actionId == NotificationService.actionAcknowledge) {
      // ── "챙겼어요" ──────────────────────────────────────────
      if (pm25 > 0) {
        final maskType =
            prefs.getString(NotificationService.prefLastNotifMaskType) ??
                'KF80';
        final record = DefenseRecord.create(pm25: pm25, maskType: maskType);
        await DefenseRepository.addRecordToPrefs(prefs, record);
      }
      // 피드백 기록 (pm25 == 0이어도 응답 의사는 기록)
      final pending = _loadPendingNotifId(prefs);
      await FeedbackRepository.addFeedbackToPrefs(
        prefs,
        NotificationFeedback(
          notifId: pending ?? _nowId(),
          timestamp: DateTime.now(),
          pm25: pm25,
          type: FeedbackType.acknowledged,
        ),
      );
    } else if (response.actionId == NotificationService.actionSnoozeToday) {
      // ── "오늘 끄기" ─────────────────────────────────────────
      final today = _dateKey(DateTime.now());
      await prefs.setString(NotificationService.prefSnoozedDate, today);

      final pending = _loadPendingNotifId(prefs);
      await FeedbackRepository.addFeedbackToPrefs(
        prefs,
        NotificationFeedback(
          notifId: pending ?? _nowId(),
          timestamp: DateTime.now(),
          pm25: pm25,
          type: FeedbackType.snoozed,
        ),
      );
    }
  } catch (_) {
    // 배경 핸들러 오류는 조용히 무시 (앱 충돌 방지)
  }
}

String? _loadPendingNotifId(SharedPreferences prefs) {
  final raw = prefs.getString(FeedbackRepository.pendingKey);
  if (raw == null) return null;
  return raw.split('|').firstOrNull;
}

String _nowId() => DateTime.now().millisecondsSinceEpoch.toString();
String _dateKey(DateTime dt) =>
    '${dt.year}${dt.month.toString().padLeft(2, '0')}'
    '${dt.day.toString().padLeft(2, '0')}';

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

  // ── SharedPreferences 키 ──────────────────────────────────────
  /// 가장 최근 마스크 알림 발송 시점의 PM2.5 값 (int)
  static const String prefLastNotifPm25 = '_last_notif_pm25';

  /// 가장 최근 마스크 알림 발송 시점의 마스크 종류 ('KF80' | 'KF94')
  static const String prefLastNotifMaskType = '_last_notif_mask_type';

  /// "오늘 끄기" 탭 날짜 — 'yyyyMMdd' 형식, 스케줄러가 당일 알림 억제에 사용
  static const String prefSnoozedDate = 'notif_snoozed_date';

  // ── Rich Notification 액션 ID ──────────────────────────────────
  /// "챙겼어요" — 마스크 착용 확인 액션
  static const String actionAcknowledge = 'action_ack';

  /// "오늘 끄기" — 당일 알림 스누즈 액션
  static const String actionSnoozeToday = 'action_snooze';

  // ── iOS 카테고리 ID ────────────────────────────────────────────
  static const String _categoryMask  = 'category_mask';   // 마스크 관련 알림
  static const String _categoryAlert = 'category_alert';  // 경보 알림

  /// iOS 카테고리: 마스크 알림 (챙겼어요 / 오늘 끄기)
  static String get categoryMask  => _categoryMask;

  /// iOS 카테고리: 경보 알림 (확인했어요)
  static String get categoryAlert => _categoryAlert;

  // ── 알림 아이콘 리소스 이름 ────────────────────────────────────
  static const String _iconMask    = '@drawable/ic_notif_mask';
  static const String _iconWarning = '@drawable/ic_notif_warning';

  // ── Android 액션 버튼 프리셋 ──────────────────────────────────

  /// 마스크 알림용 액션: [챙겼어요] [오늘 끄기]
  static final List<AndroidNotificationAction> maskActions = [
    const AndroidNotificationAction(
      actionAcknowledge,
      '챙겼어요 ✓',
      showsUserInterface: false,
    ),
    const AndroidNotificationAction(
      actionSnoozeToday,
      '오늘 끄기',
      showsUserInterface: false,
    ),
  ];

  /// 경보 알림용 액션: [확인했어요]
  static final List<AndroidNotificationAction> alertActions = [
    const AndroidNotificationAction(
      actionAcknowledge,
      '확인했어요',
      showsUserInterface: false,
    ),
  ];

  /// 등급별 Android 알림 액센트 색상
  ///
  /// 좋음=파랑(안심), 보통=초록(여유), 나쁨=주황(주의), 매우나쁨=빨강(위험)
  static const Map<String, Color> _gradeColors = {
    '좋음':    Color(0xFF42A5F5), // sky blue  — 안심
    '보통':    Color(0xFF4CAF50), // green     — 여유
    '나쁨':    Color(0xFFFF7043), // deep orange — 주의
    '매우나쁨': Color(0xFFEF5350), // red       — 위험
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

    // iOS 카테고리: 마스크 알림(챙겼어요 / 오늘 끄기) + 경보 알림(확인했어요)
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryMask,
          actions: [
            DarwinNotificationAction.plain(actionAcknowledge, '챙겼어요 ✓'),
            DarwinNotificationAction.plain(
              actionSnoozeToday,
              '오늘 끄기',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
        DarwinNotificationCategory(
          _categoryAlert,
          actions: [
            DarwinNotificationAction.plain(actionAcknowledge, '확인했어요'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveBackgroundNotificationResponse:
          onNotificationActionBackground,
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
  /// [gradeColor]   : 등급 기반 Android 알림 액센트 색상 ([colorForGrade] 헬퍼 사용).
  /// [actions]      : Android 알림 액션 버튼 목록 ([maskActions] / [alertActions]).
  /// [iosCategory]  : iOS 알림 카테고리 ID ([_categoryMask] / [_categoryAlert]).
  /// [smallIcon]    : Android 소형 알림 아이콘 리소스명.
  ///                  null 이면 기본값(@mipmap/ic_launcher) 사용.
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    Color? gradeColor,
    List<AndroidNotificationAction>? actions,
    String? iosCategory,
    String? smallIcon,
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
          icon: smallIcon ?? '@mipmap/ic_launcher',
          color: gradeColor,
          styleInformation: BigTextStyleInformation(body),
          actions: actions,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: iosCategory,
        ),
      ),
    );
  }

  // ── 알림 유형별 아이콘 헬퍼 ──────────────────────────────────

  /// 마스크 관련 알림(아침·귀가·예보)용 소형 아이콘
  static String get iconMask => _iconMask;

  /// 경보 알림(실시간·급변)용 소형 아이콘
  static String get iconWarning => _iconWarning;

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  /// 온보딩 알림 시뮬레이션 — 설정 완료 전 미리 받아보기
  static const int simulationAlertId = 99;

  Future<void> showSimulationNotification({String voice = 'friendly'}) async {
    final isAnalytical = voice == 'analytical';
    final title = isAnalytical
        ? '😷 마스크 착용 — PM2.5 32μg/m³'
        : '😷 오늘 마스크 챙겨가세요!';
    final body = isAnalytical
        ? 'KF80 이상. 외출 전 반드시 착용하세요.'
        : '오늘 미세먼지가 조금 있어요. 가볍게 KF80 마스크 하나 챙겨가면 안심이 될 거예요 :)';
    await showImmediateNotification(
      id: simulationAlertId,
      title: title,
      body: body,
      gradeColor: _gradeColors['나쁨'],
      smallIcon: _iconMask,
    );
  }

  // ── 알림 콘텐츠 생성 — 다정한 조언자 원칙 ──────────────────────
  //
  // 원칙:
  //  - 제목 = 지금 해야 할 행동 (명확하게, 마스크 종류 포함)
  //  - 본문 = 부드러운 이유 설명 ("공기가 조금 무겁네요" 스타일)
  //  - T_final 트리거 시 = 개인 기준선 도달 사실을 본문에 명시
  //    ("당신의 기준 {X}μg/m³을 넘었어요" → 개인화 가치 체감)

  /// 아침 알림 — 오늘 마스크 여부
  ///
  /// [tFinalTriggered] : 개인 임계치(T_final)가 발송 트리거인 경우 true
  /// [tFinal]          : 개인 임계치 값 (tFinalTriggered=true일 때 표시)
  /// [stateNote]       : 활성 취약 상태 이름 ("임신 중", "야외 운동 예정" 등)
  /// [stateOnlyMask]   : 공기는 괜찮지만 취약 상태 때문에 마스크 필요할 때 true
  static NotificationContent morningContent({
    required UserProfile profile,
    required int pm25,
    required String gradeName,
    required bool maskRequired,
    String? maskType,
    String? stateNote,
    bool stateOnlyMask = false,
    bool tFinalTriggered = false,
    double? tFinal,
  }) {
    final name = profile.displayName;

    // ── 제목: Action First — 부드러운 권유형 ─────────────────────
    final String title;
    if (maskRequired) {
      final emoji = stateOnlyMask ? '🛡️' : '😷';
      final action = maskType != null
          ? '오늘 $maskType 마스크를 챙기는 게 좋아요'
          : '오늘 마스크를 챙기는 게 좋아요';
      title = '$emoji $name, $action';
    } else {
      title = '✅ $name, 오늘 공기가 맑아요';
    }

    // ── 본문: 이유를 부드럽게 ────────────────────────────────────
    final lines = <String>[];

    if (maskRequired) {
      if (tFinalTriggered && tFinal != null) {
        // 개인 기준선 도달 → 이유를 명확히 설명
        lines.add('PM2.5 ${pm25}μg/m³ · $gradeName');
        lines.add('당신의 기준(${tFinal.toStringAsFixed(1)}μg/m³)을 넘었어요.');
        lines.add(maskType != null
            ? '$maskType 착용을 권해드려요 😊'
            : '마스크 착용을 권해드려요 😊');
      } else if (stateNote != null) {
        lines.add('PM2.5 ${pm25}μg/m³ · $gradeName');
        lines.add('$stateNote 상태라 더 신경 쓰는 게 좋아요.');
        if (maskType != null) lines.add('$maskType 착용을 권해드려요 😊');
      } else {
        lines.add('PM2.5 ${pm25}μg/m³ · $gradeName');
        lines.add('공기가 조금 무겁네요.');
        lines.add(maskType != null
            ? '$maskType 착용을 권해드려요 😊'
            : '마스크를 꼭 챙겨주세요 😊');
      }
    } else {
      lines.add('PM2.5 ${pm25}μg/m³ · $gradeName');
      if (stateNote != null) {
        lines.add('$stateNote 상태를 참고해 주세요.');
      } else {
        lines.add('마스크 없이 외출하셔도 좋아요 😊');
        final note = _personalNote(profile);
        if (note != null) lines.add(note);
      }
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

    // ── 제목 ─────────────────────────────────────────────────────
    final String title;
    if (isBad) {
      final emoji = stateOnlyMask ? '🛡️' : '🌆';
      final action = maskType != null
          ? '내일 $maskType 마스크를 미리 챙겨두세요'
          : '내일 마스크를 미리 챙겨두세요';
      title = '$emoji $name, $action';
    } else {
      title = '🌤 $name, 내일 공기가 좋을 것 같아요';
    }

    // ── 본문 ─────────────────────────────────────────────────────
    final lines = <String>['내일 PM2.5 예보: $tomorrowGrade'];

    if (isBad) {
      if (stateNote != null) {
        lines.add('$stateNote 상태라 조금 더 주의하는 게 좋겠어요.');
        if (maskType != null) lines.add('$maskType 이상을 권해드려요 😊');
      } else {
        lines.add('내일 출발 전에 미리 ${ maskType ?? "마스크"}를 챙겨두시면 좋겠어요 😊');
      }
    } else {
      lines.add('내일은 마스크 없이 쾌적하게 외출하실 수 있어요 😊');
    }

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  /// 귀가 알림 — 퇴근길 공기 상태
  ///
  /// [tFinalTriggered] : 개인 임계치(T_final)가 발송 트리거인 경우 true
  /// [tFinal]          : 개인 임계치 값
  /// [stateNote]       : 활성 취약 상태 이름
  static NotificationContent eveningReturnContent({
    required UserProfile profile,
    required String gradeName,
    String? maskType,
    String? stateNote,
    bool stateOnlyMask = false,
    bool tFinalTriggered = false,
    double? tFinal,
  }) {
    final name = profile.displayName;
    final isBad = gradeName == '나쁨' || gradeName == '매우나쁨';
    final maskRequired = tFinalTriggered || stateNote != null || isBad;

    // ── 제목 ─────────────────────────────────────────────────────
    final String title;
    if (maskRequired) {
      final action = maskType != null
          ? '퇴근길에 $maskType 마스크를 챙겨주세요'
          : '퇴근길에 마스크를 챙겨주세요';
      title = '🏠 $name, $action';
    } else {
      title = '🏠 $name, 퇴근길 공기가 좋아요';
    }

    // ── 본문 ─────────────────────────────────────────────────────
    final lines = <String>[];

    if (maskRequired) {
      lines.add('PM2.5 $gradeName');
      if (tFinalTriggered && tFinal != null) {
        lines.add('당신의 기준(${tFinal.toStringAsFixed(1)}μg/m³)을 넘었어요.');
        lines.add('귀가 시 마스크를 꼭 챙겨주세요 😊');
      } else if (stateNote != null) {
        lines.add('$stateNote 상태라 조금 더 신경 써주세요.');
        if (maskType != null) lines.add('$maskType 착용을 권해드려요 😊');
      } else {
        lines.add('퇴근길 공기가 다소 무거워요.');
        lines.add(maskType != null ? '$maskType 착용을 권해드려요 😊' : '마스크를 챙겨주세요 😊');
      }
    } else {
      lines.add('PM2.5 $gradeName');
      lines.add('오늘 하루도 수고 많으셨어요. 편하게 귀가하세요 😊');
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

    // 매우나쁨 = 안전 최우선 → 명확하되 당황하지 않게
    final title = '🚨 $name, 지금 KF94 마스크가 꼭 필요해요';
    final lines = <String>[
      'PM2.5 ${pm25}μg/m³ · 매우나쁨',
      '가능하면 야외 활동을 줄이시고, KF94 마스크를 착용해 주세요.',
    ];
    if (stateNote != null) {
      lines.add('$stateNote 상태라 특히 주의가 필요해요.');
    }

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
    final maskHint = isSevere ? 'KF94' : 'KF80';

    final title = '⚡ $name, 미리 $maskHint 마스크를 챙겨두세요';
    final lines = <String>[
      'PM2.5 ${currentPm25}μg/m³ → 1시간 내 $targetGrade 예상',
      '지금은 괜찮지만 곧 나빠질 것 같아요.',
      '외출 전에 $maskHint 마스크를 챙겨두시면 안심이에요 😊',
    ];

    return NotificationContent(title: title, body: lines.join('\n'));
  }

  // ── 내부 헬퍼 ─────────────────────────────────────────────

  static String? _personalNote(UserProfile profile) {
    if (profile.respiratoryStatus & 2 != 0) return '호흡기 질환 기준으로 맞춤 관리 중이에요';
    if (profile.respiratoryStatus & 1 != 0) return '비염 기준으로 맞춤 관리 중이에요';
    if (profile.isVulnerableAge) return '${profile.age}세 민감 연령 기준으로 관리 중이에요';
    if (profile.sensitivityLevel == 2) return '고민감도 기준으로 맞춤 관리 중이에요';
    return null;
  }
}
