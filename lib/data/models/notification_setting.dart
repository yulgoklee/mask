/// 알림 설정 모델
class NotificationSetting {
  // ── 알림 시간 ────────────────────────────────────────────

  /// 외출 전 오전 알림 (기본: 오전 7시)
  final bool morningAlertEnabled;
  final int morningAlertHour;
  final int morningAlertMinute;

  /// 전날 예보 알림 (기본: 오후 9시)
  final bool eveningForecastEnabled;
  final int eveningForecastHour;
  final int eveningForecastMinute;

  /// 저녁 귀가 알림 (기본: 오후 6시)
  final bool eveningReturnEnabled;
  final int eveningReturnHour;
  final int eveningReturnMinute;

  /// 실시간 경보 (수치 급등 시)
  final bool realtimeAlertEnabled;

  // ── 알림 페르소나 (Phase 4) ──────────────────────────────

  /// 알림 목소리 스타일.
  /// 'friendly' = 다정한 가디언 (기본값)
  /// 'analytical' = 단호한 분석가
  final String notificationVoice;

  const NotificationSetting({
    this.morningAlertEnabled = true,
    this.morningAlertHour = 7,
    this.morningAlertMinute = 0,
    this.eveningForecastEnabled = false,
    this.eveningForecastHour = 21,
    this.eveningForecastMinute = 0,
    this.eveningReturnEnabled = false,
    this.eveningReturnHour = 18,
    this.eveningReturnMinute = 0,
    this.realtimeAlertEnabled = true,
    this.notificationVoice = 'friendly',
  });

  NotificationSetting copyWith({
    bool? morningAlertEnabled,
    int? morningAlertHour,
    int? morningAlertMinute,
    bool? eveningForecastEnabled,
    int? eveningForecastHour,
    int? eveningForecastMinute,
    bool? eveningReturnEnabled,
    int? eveningReturnHour,
    int? eveningReturnMinute,
    bool? realtimeAlertEnabled,
    String? notificationVoice,
  }) {
    return NotificationSetting(
      morningAlertEnabled: morningAlertEnabled ?? this.morningAlertEnabled,
      morningAlertHour: morningAlertHour ?? this.morningAlertHour,
      morningAlertMinute: morningAlertMinute ?? this.morningAlertMinute,
      eveningForecastEnabled:
          eveningForecastEnabled ?? this.eveningForecastEnabled,
      eveningForecastHour: eveningForecastHour ?? this.eveningForecastHour,
      eveningForecastMinute:
          eveningForecastMinute ?? this.eveningForecastMinute,
      eveningReturnEnabled: eveningReturnEnabled ?? this.eveningReturnEnabled,
      eveningReturnHour: eveningReturnHour ?? this.eveningReturnHour,
      eveningReturnMinute: eveningReturnMinute ?? this.eveningReturnMinute,
      realtimeAlertEnabled: realtimeAlertEnabled ?? this.realtimeAlertEnabled,
      notificationVoice: notificationVoice ?? this.notificationVoice,
    );
  }

  Map<String, dynamic> toJson() => {
        'morningAlertEnabled': morningAlertEnabled,
        'morningAlertHour': morningAlertHour,
        'morningAlertMinute': morningAlertMinute,
        'eveningForecastEnabled': eveningForecastEnabled,
        'eveningForecastHour': eveningForecastHour,
        'eveningForecastMinute': eveningForecastMinute,
        'eveningReturnEnabled': eveningReturnEnabled,
        'eveningReturnHour': eveningReturnHour,
        'eveningReturnMinute': eveningReturnMinute,
        'realtimeAlertEnabled': realtimeAlertEnabled,
        'notificationVoice': notificationVoice,
      };

  factory NotificationSetting.fromJson(Map<String, dynamic> json) =>
      NotificationSetting(
        morningAlertEnabled: json['morningAlertEnabled'] as bool? ?? true,
        morningAlertHour: json['morningAlertHour'] as int? ?? 7,
        morningAlertMinute: json['morningAlertMinute'] as int? ?? 0,
        eveningForecastEnabled:
            json['eveningForecastEnabled'] as bool? ?? false,
        eveningForecastHour: json['eveningForecastHour'] as int? ?? 21,
        eveningForecastMinute: json['eveningForecastMinute'] as int? ?? 0,
        eveningReturnEnabled: json['eveningReturnEnabled'] as bool? ?? false,
        eveningReturnHour: json['eveningReturnHour'] as int? ?? 18,
        eveningReturnMinute: json['eveningReturnMinute'] as int? ?? 0,
        realtimeAlertEnabled: json['realtimeAlertEnabled'] as bool? ?? true,
        notificationVoice:
            json['notificationVoice'] as String? ?? 'friendly',
      );
}

// ── 알림 페르소나 ─────────────────────────────────────────

/// Phase 4 알림 목소리 스타일
class NotificationVoice {
  static const String friendly   = 'friendly';
  static const String analytical = 'analytical';

  static String label(String voice) {
    switch (voice) {
      case friendly:   return '다정한 가디언';
      case analytical: return '단호한 분석가';
      default:         return '다정한 가디언';
    }
  }

  static String description(String voice) {
    switch (voice) {
      case friendly:
        return '"공기가 조금 차네요.\n마스크 챙겨보시는 건 어떨까요?"';
      case analytical:
        return '"현재 수치는 님께 위험합니다.\n반드시 KF94를 착용하세요."';
      default:
        return '"공기가 조금 차네요.\n마스크 챙겨보시는 건 어떨까요?"';
    }
  }
}
