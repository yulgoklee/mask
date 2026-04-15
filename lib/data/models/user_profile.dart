/// 개인 건강 프로필 모델
class UserProfile {
  /// 표시 이름 (선택). null이면 "님"으로 호칭.
  final String? name;

  /// 성별 (Issue 1)
  final Gender? gender;

  /// 출생연도 (Issue 3). null이면 ageGroup 폴백 사용.
  final int? birthYear;

  /// 나이대 — 하위 호환용. birthYear가 있으면 isVulnerableAge는 birthYear로 계산.
  final AgeGroup ageGroup;

  final bool hasCondition;
  final ConditionType conditionType;
  final Severity severity;
  final bool isDiagnosed;
  final ActivityLevel activityLevel;
  final SensitivityLevel sensitivity;

  // ── Phase 1.4 특별 상태 (w_spec) ──────────────────────────
  /// 피부 시술 후 2주 내 (w_spec: -0.25)
  final bool hasSkinProcedure;

  /// 영유아·고령자 부양 중 (w_spec: -0.15)
  final bool hasDependents;

  // ── Phase 1.5 편의 성향 (w_pref) ──────────────────────────
  /// 마스크 착용 시 답답함·김 서림이 심한 편 (w_pref: +0.08 → T_final 소폭 상향)
  final bool maskDiscomfort;

  const UserProfile({
    this.name,
    this.gender,
    this.birthYear,
    required this.ageGroup,
    required this.hasCondition,
    this.conditionType = ConditionType.none,
    this.severity = Severity.mild,
    this.isDiagnosed = false,
    required this.activityLevel,
    this.sensitivity = SensitivityLevel.normal,
    this.hasSkinProcedure = false,
    this.hasDependents = false,
    this.maskDiscomfort = false,
  });

  // ── 계산 속성 ──────────────────────────────────────────────

  /// 알림/홈 화면 호칭 ("율곡님" or "님")
  String get displayName => (name != null && name!.isNotEmpty) ? '$name님' : '님';

  /// 실제 나이 (birthYear가 없으면 null)
  int? get age =>
      birthYear != null ? DateTime.now().year - birthYear! : null;

  /// 취약 연령 여부 — birthYear 우선, 없으면 ageGroup 폴백
  bool get isVulnerableAge {
    final a = age;
    if (a != null) return a < 18 || a >= 60;
    return ageGroup.isVulnerable;
  }

  factory UserProfile.defaultProfile() => const UserProfile(
        name: null,
        gender: null,
        birthYear: null,
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
    Object? gender = _sentinel,
    Object? birthYear = _sentinel,
    AgeGroup? ageGroup,
    bool? hasCondition,
    ConditionType? conditionType,
    Severity? severity,
    bool? isDiagnosed,
    ActivityLevel? activityLevel,
    SensitivityLevel? sensitivity,
    bool? hasSkinProcedure,
    bool? hasDependents,
    bool? maskDiscomfort,
  }) {
    return UserProfile(
      name: name == _sentinel ? this.name : name as String?,
      gender: gender == _sentinel ? this.gender : gender as Gender?,
      birthYear: birthYear == _sentinel ? this.birthYear : birthYear as int?,
      ageGroup: ageGroup ?? this.ageGroup,
      hasCondition: hasCondition ?? this.hasCondition,
      conditionType: conditionType ?? this.conditionType,
      severity: severity ?? this.severity,
      isDiagnosed: isDiagnosed ?? this.isDiagnosed,
      activityLevel: activityLevel ?? this.activityLevel,
      sensitivity: sensitivity ?? this.sensitivity,
      hasSkinProcedure: hasSkinProcedure ?? this.hasSkinProcedure,
      hasDependents: hasDependents ?? this.hasDependents,
      maskDiscomfort: maskDiscomfort ?? this.maskDiscomfort,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender?.index,
        'birthYear': birthYear,
        'ageGroup': ageGroup.index,
        'hasCondition': hasCondition,
        'conditionType': conditionType.index,
        'severity': severity.index,
        'isDiagnosed': isDiagnosed,
        'activityLevel': activityLevel.index,
        'sensitivity': sensitivity.index,
        'hasSkinProcedure': hasSkinProcedure,
        'hasDependents': hasDependents,
        'maskDiscomfort': maskDiscomfort,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String?,
        gender: json['gender'] != null
            ? Gender.values[json['gender'] as int]
            : null,
        birthYear: json['birthYear'] as int?,
        ageGroup: AgeGroup.values[json['ageGroup'] as int],
        hasCondition: json['hasCondition'] as bool,
        conditionType: ConditionType.values[json['conditionType'] as int],
        severity: Severity.values[json['severity'] as int],
        isDiagnosed: json['isDiagnosed'] as bool,
        activityLevel: ActivityLevel.values[json['activityLevel'] as int],
        sensitivity: SensitivityLevel.values[json['sensitivity'] as int],
        // 하위 호환: 구버전 저장 데이터에는 없을 수 있으므로 기본값 false
        hasSkinProcedure: json['hasSkinProcedure'] as bool? ?? false,
        hasDependents: json['hasDependents'] as bool? ?? false,
        maskDiscomfort: json['maskDiscomfort'] as bool? ?? false,
      );
}

// copyWith에서 null과 "미전달"을 구분하기 위한 센티널
const _sentinel = Object();

// ── 열거형 ────────────────────────────────────────────────

enum Gender {
  male,
  female,
  other;

  String get label {
    const labels = ['남성', '여성', '기타'];
    return labels[index];
  }
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
  pregnancy, // 여성 전용 — UI에서 gender == female 조건으로만 노출
  other;

  String get label {
    const labels = ['없음', '호흡기 질환', '심혈관 질환', '알레르기', '천식', '임신 중', '기타'];
    return labels[index];
  }

  /// 성별 조건이 필요한 항목 여부 (true = 여성에게만 노출)
  bool get requiresFemale => this == ConditionType.pregnancy;
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
      case ActivityLevel.low:    return '하루 1시간 미만 외출해요';
      case ActivityLevel.normal: return '하루 1~3시간 외출해요';
      case ActivityLevel.high:   return '하루 3시간 이상 야외 활동해요';
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
