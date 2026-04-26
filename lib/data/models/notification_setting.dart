/// 알림 설정 모델
class NotificationSetting {
  // 전날 예보 알림 (기본: 오후 9시)
  final bool eveningForecastEnabled;
  final int eveningForecastHour;
  final int eveningForecastMinute;

  // 당일 오전 알림 (기본: 오전 7시)
  final bool morningAlertEnabled;
  final int morningAlertHour;
  final int morningAlertMinute;

  // 저녁 귀가 알림 (기본: 오후 6시)
  final bool eveningReturnEnabled;
  final int eveningReturnHour;
  final int eveningReturnMinute;

  // 실시간 경보 (수치 급등 시)
  final bool realtimeAlertEnabled;

  // 방해 금지 시간
  final bool quietHoursEnabled;
  final int quietHoursStartHour;   // 0~23
  final int quietHoursEndHour;     // 0~23

  const NotificationSetting({
    this.eveningForecastEnabled = false,
    this.eveningForecastHour = 21,
    this.eveningForecastMinute = 0,
    this.morningAlertEnabled = true,
    this.morningAlertHour = 7,
    this.morningAlertMinute = 0,
    this.eveningReturnEnabled = false,
    this.eveningReturnHour = 18,
    this.eveningReturnMinute = 0,
    this.realtimeAlertEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursEndHour = 7,
  });

  NotificationSetting copyWith({
    bool? eveningForecastEnabled,
    int? eveningForecastHour,
    int? eveningForecastMinute,
    bool? morningAlertEnabled,
    int? morningAlertHour,
    int? morningAlertMinute,
    bool? eveningReturnEnabled,
    int? eveningReturnHour,
    int? eveningReturnMinute,
    bool? realtimeAlertEnabled,
    bool? quietHoursEnabled,
    int?  quietHoursStartHour,
    int?  quietHoursEndHour,
  }) {
    return NotificationSetting(
      eveningForecastEnabled: eveningForecastEnabled ?? this.eveningForecastEnabled,
      eveningForecastHour: eveningForecastHour ?? this.eveningForecastHour,
      eveningForecastMinute: eveningForecastMinute ?? this.eveningForecastMinute,
      morningAlertEnabled: morningAlertEnabled ?? this.morningAlertEnabled,
      morningAlertHour: morningAlertHour ?? this.morningAlertHour,
      morningAlertMinute: morningAlertMinute ?? this.morningAlertMinute,
      eveningReturnEnabled: eveningReturnEnabled ?? this.eveningReturnEnabled,
      eveningReturnHour: eveningReturnHour ?? this.eveningReturnHour,
      eveningReturnMinute: eveningReturnMinute ?? this.eveningReturnMinute,
      realtimeAlertEnabled: realtimeAlertEnabled ?? this.realtimeAlertEnabled,
      quietHoursEnabled:   quietHoursEnabled   ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursEndHour:   quietHoursEndHour   ?? this.quietHoursEndHour,
    );
  }

  Map<String, dynamic> toJson() => {
    'eveningForecastEnabled': eveningForecastEnabled,
    'eveningForecastHour': eveningForecastHour,
    'eveningForecastMinute': eveningForecastMinute,
    'morningAlertEnabled': morningAlertEnabled,
    'morningAlertHour': morningAlertHour,
    'morningAlertMinute': morningAlertMinute,
    'eveningReturnEnabled': eveningReturnEnabled,
    'eveningReturnHour': eveningReturnHour,
    'eveningReturnMinute': eveningReturnMinute,
    'realtimeAlertEnabled': realtimeAlertEnabled,
    'quietHoursEnabled':   quietHoursEnabled,
    'quietHoursStartHour': quietHoursStartHour,
    'quietHoursEndHour':   quietHoursEndHour,
  };

  factory NotificationSetting.fromJson(Map<String, dynamic> json) =>
      NotificationSetting(
        eveningForecastEnabled: json['eveningForecastEnabled'] as bool? ?? false,
        eveningForecastHour: json['eveningForecastHour'] as int? ?? 21,
        eveningForecastMinute: json['eveningForecastMinute'] as int? ?? 0,
        morningAlertEnabled: json['morningAlertEnabled'] as bool? ?? true,
        morningAlertHour: json['morningAlertHour'] as int? ?? 7,
        morningAlertMinute: json['morningAlertMinute'] as int? ?? 0,
        eveningReturnEnabled: json['eveningReturnEnabled'] as bool? ?? false,
        eveningReturnHour: json['eveningReturnHour'] as int? ?? 18,
        eveningReturnMinute: json['eveningReturnMinute'] as int? ?? 0,
        realtimeAlertEnabled: json['realtimeAlertEnabled'] as bool? ?? true,
        quietHoursEnabled:   json['quietHoursEnabled']   as bool? ?? false,
        quietHoursStartHour: json['quietHoursStartHour'] as int?  ?? 22,
        quietHoursEndHour:   json['quietHoursEndHour']   as int?  ?? 7,
      );
}
