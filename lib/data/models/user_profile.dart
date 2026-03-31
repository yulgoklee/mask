/// 개인 건강 프로필 모델
class UserProfile {
  final AgeGroup ageGroup;
  final bool hasCondition;
  final ConditionType conditionType;
  final Severity severity;
  final bool isDiagnosed;
  final ActivityLevel activityLevel;
  final SensitivityLevel sensitivity;

  const UserProfile({
    required this.ageGroup,
    required this.hasCondition,
    this.conditionType = ConditionType.none,
    this.severity = Severity.mild,
    this.isDiagnosed = false,
    required this.activityLevel,
    this.sensitivity = SensitivityLevel.normal,
  });

  factory UserProfile.defaultProfile() => const UserProfile(
        ageGroup: AgeGroup.thirties,
        hasCondition: false,
        conditionType: ConditionType.none,
        severity: Severity.mild,
        isDiagnosed: false,
        activityLevel: ActivityLevel.normal,
        sensitivity: SensitivityLevel.normal,
      );

  UserProfile copyWith({
    AgeGroup? ageGroup,
    bool? hasCondition,
    ConditionType? conditionType,
    Severity? severity,
    bool? isDiagnosed,
    ActivityLevel? activityLevel,
    SensitivityLevel? sensitivity,
  }) {
    return UserProfile(
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
        'ageGroup': ageGroup.index,
        'hasCondition': hasCondition,
        'conditionType': conditionType.index,
        'severity': severity.index,
        'isDiagnosed': isDiagnosed,
        'activityLevel': activityLevel.index,
        'sensitivity': sensitivity.index,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        ageGroup: AgeGroup.values[json['ageGroup'] as int],
        hasCondition: json['hasCondition'] as bool,
        conditionType: ConditionType.values[json['conditionType'] as int],
        severity: Severity.values[json['severity'] as int],
        isDiagnosed: json['isDiagnosed'] as bool,
        activityLevel: ActivityLevel.values[json['activityLevel'] as int],
        sensitivity: SensitivityLevel.values[json['sensitivity'] as int],
      );
}

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
