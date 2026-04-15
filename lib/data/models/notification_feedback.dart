/// 알림 1건에 대한 사용자 반응 기록
///
/// 수집 경로:
///  - acknowledged: "챙겼어요" 탭 → onNotificationActionBackground
///  - snoozed:      "오늘 끄기" 탭 → onNotificationActionBackground
///  - ignored:      알림 발송 후 [_kIgnoreWindowHours]시간 경과 + 무응답
///                  (스케줄러 다음 실행 시 미응답 알림 자동 처리)
///
/// 저장: SharedPreferences JSON 배열 ('notification_feedbacks')
/// 보관: 최근 30일 (학습에 필요한 최소 기간)
class NotificationFeedback {
  final String notifId;   // 알림 고유 ID (timestamp 기반)
  final DateTime timestamp;
  final int pm25;

  /// 사용자 반응
  final FeedbackType type;

  const NotificationFeedback({
    required this.notifId,
    required this.timestamp,
    required this.pm25,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'notifId': notifId,
        'timestamp': timestamp.toIso8601String(),
        'pm25': pm25,
        'type': type.name,
      };

  factory NotificationFeedback.fromJson(Map<String, dynamic> json) =>
      NotificationFeedback(
        notifId: json['notifId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        pm25: json['pm25'] as int,
        type: FeedbackType.values.byName(json['type'] as String),
      );
}

/// 사용자 반응 유형
enum FeedbackType {
  /// "챙겼어요" 탭 — 가장 긍정적 신호 (알림이 적절했음)
  acknowledged,

  /// "오늘 끄기" 탭 — 알림 자체는 인지했으나 오늘은 필요 없다는 의사
  snoozed,

  /// 무응답 — 알림 무시 (알림이 잦거나 불필요했을 가능성)
  ignored,
}
