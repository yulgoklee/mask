/// 알림 발송 기록 — SQLite notification_logs 테이블과 1:1 대응
///
/// Stage 4 방어율 계산의 핵심 입력 데이터.
/// userAction이 'maskWorn'인 경우만 '확정 방어'로 집계.
enum NotificationType {
  dangerEntry,  // T_final 초과 진입
  safeEntry,    // 안심 구간 복귀
  morning,      // 오전 정기 알림
  evening,      // 저녁 정기 알림
  pm10Warning,  // PM10 국가경보 (예외 레이어)
}

enum UserAction {
  maskWorn,              // [마스크 챙김] 버튼 클릭 — 확정 방어
  appOpened,             // 알림 탭 → 앱 열기만 — 추정 방어
  snoozed,               // [나중에] 버튼 클릭 — 6시간 스누즈
  none,                  // 무반응
  suppressedByQuietHours, // 방해 금지 시간 억제 — 통계 분모에서 제외
}

class NotificationLog {
  final int? id;
  final DateTime triggeredAt;
  final NotificationType notificationType;
  final int? pm25Value;
  final int? pm10Value;
  final double? tFinal;
  final UserAction userAction;

  /// [마스크 챙겼어요] 탭 시점의 마스크 종류 스냅샷 (maskWorn일 때만 기록)
  final String? maskType;

  /// 스누즈 만료 시각 (snoozed일 때만 기록, UTC ISO8601)
  final DateTime? snoozeUntil;

  const NotificationLog({
    this.id,
    required this.triggeredAt,
    required this.notificationType,
    this.pm25Value,
    this.pm10Value,
    this.tFinal,
    this.userAction = UserAction.none,
    this.maskType,
    this.snoozeUntil,
  });

  bool get isConfirmedDefense => userAction == UserAction.maskWorn;
  bool get isEstimatedDefense => userAction == UserAction.appOpened;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'triggered_at': triggeredAt.toIso8601String(),
        'notification_type': notificationType.name,
        'pm25_value': pm25Value,
        'pm10_value': pm10Value,
        't_final': tFinal,
        'user_action': userAction.name,
        'mask_type': maskType,
        'snooze_until': snoozeUntil?.toIso8601String(),
      };

  factory NotificationLog.fromMap(Map<String, dynamic> m) => NotificationLog(
        id: m['id'] as int?,
        triggeredAt: DateTime.parse(m['triggered_at'] as String),
        notificationType: NotificationType.values.firstWhere(
          (e) => e.name == m['notification_type'],
          orElse: () => NotificationType.dangerEntry,
        ),
        pm25Value: m['pm25_value'] as int?,
        pm10Value: m['pm10_value'] as int?,
        tFinal: (m['t_final'] as num?)?.toDouble(),
        userAction: UserAction.values.firstWhere(
          (e) => e.name == m['user_action'],
          orElse: () => UserAction.none,
        ),
        maskType: m['mask_type'] as String?,
        snoozeUntil: m['snooze_until'] != null
            ? DateTime.parse(m['snooze_until'] as String)
            : null,
      );
}

/// 알림 발송 시점의 AQI 환경 컨텍스트를 포함한 조인 결과
///
/// [notification]  알림 로그 원본
/// [aqiPm25]       조인된 aqi_records의 PM2.5 (1시간 이내 매칭 없으면 null)
/// [aqiPm10]       조인된 aqi_records의 PM10  (1시간 이내 매칭 없으면 null)
/// [aqiDataTime]   조인된 aqi_records의 측정 시각 (null이면 컨텍스트 없음)
class NotificationWithAqiContext {
  final NotificationLog notification;
  final int? aqiPm25;
  final int? aqiPm10;
  final DateTime? aqiDataTime;

  const NotificationWithAqiContext({
    required this.notification,
    this.aqiPm25,
    this.aqiPm10,
    this.aqiDataTime,
  });

  /// 1시간 이내 AQI 컨텍스트가 존재하는지 여부
  bool get hasAqiContext => aqiDataTime != null;
}
