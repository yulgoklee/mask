/// 개인 건강 프로필 모델
class UserProfile {
  /// 표시 이름 (선택). null이면 "님"으로 호칭.
  final String? name;
  final AgeGroup ageGroup;
  final bool hasCondition;
  final ConditionType conditionType;
  final Severity severity;
  final bool isDiagnosed;
  final ActivityLevel activityLevel;
  final SensitivityLevel sensitivity;

  const UserProfile({
    this.name,
    required this.ageGroup,
    required this.hasCondition,
    this.conditionType = ConditionType.none,
    this.severity = Severity.mild,
    this.isDiagnosed = false,
    required this.activityLevel,
    this.sensitivity = SensitivityLevel.normal,
  });

  /// 알림/홈 화면 호칭 ("율곡님" or "님")
  String get displayName => (name != null && name!.isNotEmpty) ? '$name님' : '님';

  factory UserProfile.defaultProfile() => const UserProfile(
        name: null,
        ageGroup: AgeGroup.thirties,
        hasCondition: false,
        conditionType: ConditionType.none,
        severity: Severity.mild,
        isDiagnosed: false,
        activityLevel: ActivityLevel.normal,
        sensitivity: SensitivityLevel.normal,
      );

  UserProfile copyWith({
    Object? name = _sentinel,
    AgeGroup? ageGroup,
    bool? hasCondition,
    ConditionType? conditionType,
    Severity? severity,
    bool? isDiagnosed,
    ActivityLevel? activityLevel,
    SensitivityLevel? sensitivity,
  }) {
    return UserProfile(
      name: name == _sentinel ? this.name : name as String?,
      ageGroup: ageGroup ?? this.ageGroup,
      hasCondition: hasCondition ?? this.hasCondition,
      conditionType: conditionType ?? this.conditionType,
      severity: severity ?? this.severity,
      isDiagnosed: isDiagnosed ?? this.isDiagnosed,
      activityLevel: activityLevel ?? this.activityLevel,
      sensitivity: sensitivity ?? this.sensitivity,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ageGroup': ageGroup.index,
        'hasCondition': hasCondition,
        'conditionType': conditionType.index,
        'severity': severity.index,
        'isDiagnosed': isDiagnosed,
        'activityLevel': activityLevel.index,
        'sensitivity': sensitivity.index,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String?,
        ageGroup: AgeGroup.values[json['ageGroup'] as int],
        hasCondition: json['hasCondition'] as bool,
        conditionType: ConditionType.values[json['conditionType'] as int],
        severity: Severity.values[json['severity'] as int],
        isDiagnosed: json['isDiagnosed'] as bool,
        activityLevel: ActivityLevel.values[json['activityLevel'] as int],
        sensitivity: SensitivityLevel.values[json['sensitivity'] as int],
      );
}

// copyWith에서 null과 "미전달"을 구분하기 위한 센티널
const _sentinel = Object();

enum AgeGroup {
  teens,
  twenties,
  thirties,
  forties,
  fifties,
  sixtyPlus;

  String get label {
    const labels = ['10대', '20대', '30대', '40대', '50대', '60대 이상'];
    return labels[index];
  }

  bool get isVulnerable => this == AgeGroup.sixtyPlus || this == AgeGroup.teens;
}

enum ConditionType {
  none,
  respiratory,
  cardiovascular,
  allergy,
  asthma,
  other;

  String get label {
    const labels = ['없음', '호흡기 질환', '심혈관 질환', '알레르기', '천식', '기타'];
    return labels[index];
  }
}

enum Severity {
  mild,
  moderate,
  severe;

  String get label {
    const labels = ['경증', '중등도', '중증'];
    return labels[index];
  }
}

enum ActivityLevel {
  low,
  normal,
  high;

  String get label {
    const labels = ['낮음', '보통', '높음'];
    return labels[index];
  }

  String get description {
    switch (this) {
      case ActivityLevel.low:    return '주 1~2회 정도 외출해요';
      case ActivityLevel.normal: return '매일 출퇴근 등 외출해요';
      case ActivityLevel.high:   return '야외 활동이 많아요';
    }
  }
}

enum SensitivityLevel {
  low,
  normal,
  high;

  String get label {
    const labels = ['낮음', '보통', '높음'];
    return labels[index];
  }
}
