/// 초개인화 건강 프로필 모델 (v2)
///
/// Q1~Q10 온보딩 답변을 그대로 저장하고,
/// T_final(개인별 PM2.5 임계값)을 실시간으로 산출합니다.
class UserProfile {
  /// Q1: 닉네임 (2~10자). 빈 문자열이면 "님"으로 호칭.
  final String nickname;

  /// Q2: 출생 연도. 영유아(≤10세) / 고령자(≥70세) 판단용.
  final int birthYear;

  /// Q3: 성별. 'male' 또는 'female'.
  final String gender;

  /// Q4: 호흡기 상태.
  /// 0 = 튼튼함, 1 = 비염, 2 = 천식 등 질환 있음.
  final int respiratoryStatus;

  /// Q5: 체감 민감도.
  /// 0 = 무던함, 1 = 보통, 2 = 예민함.
  final int sensitivityLevel;

  /// Q6: 임신 여부. gender == 'female' 일 때만 유효값.
  final bool isPregnant;

  /// Q7: 최근 2주 내 피부 시술 여부.
  final bool recentSkinTreatment;

  /// Q8: 야외 활동 시간.
  /// 0 = 30분 미만, 1 = 1~3시간, 2 = 3시간 이상.
  final int outdoorMinutes;

  /// Q9: 활동 성격 (중복 선택).
  /// 예: ['commute', 'walk', 'exercise']
  final List<String> activityTags;

  /// Q10: 마스크 불편 정도.
  /// 0 = 괜찮음, 1 = 가끔 답답함, 2 = 매우 답답함.
  final int discomfortLevel;

  const UserProfile({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.respiratoryStatus,
    required this.sensitivityLevel,
    required this.isPregnant,
    required this.recentSkinTreatment,
    required this.outdoorMinutes,
    required this.activityTags,
    required this.discomfortLevel,
  });

  // ── 계산 프로퍼티 ────────────────────────────────────────

  /// 현재 나이 (출생 연도 기준 단순 계산)
  int get age => DateTime.now().year - birthYear;

  /// 취약 연령 여부 (영유아 10세 이하 또는 고령자 70세 이상)
  bool get isVulnerableAge => age <= 10 || age >= 70;

  /// 알림 및 홈 화면 호칭. 닉네임이 없으면 "님".
  String get displayName => nickname.isNotEmpty ? '$nickname님' : '님';

  /// 개인 민감도 지수 S.
  ///
  /// 각 항목별 가중치를 누적 합산하며, [0.1, 0.6] 범위로 제한합니다.
  ///
  /// | 항목               | 가중치  |
  /// |--------------------|---------|
  /// | 취약 연령          | +0.10   |
  /// | 비염               | +0.15   |
  /// | 천식 등 질환       | +0.30   |
  /// | 체감 예민함        | +0.10   |
  /// | 임신 (최우선)      | +0.30   |
  /// | 최근 피부 시술     | +0.25   |
  /// | 3시간 이상 야외    | +0.10   |
  /// | 마스크 매우 답답함 | -0.10   |
  double get sensitivityIndex {
    double s = 0.0;
    if (isVulnerableAge) s += 0.10;
    if (respiratoryStatus == 1) s += 0.15;
    if (respiratoryStatus == 2) s += 0.30;
    if (sensitivityLevel == 2) s += 0.10;
    if (gender == 'female' && isPregnant) s += 0.30;
    if (recentSkinTreatment) s += 0.25;
    if (outdoorMinutes == 2) s += 0.10;
    if (discomfortLevel == 2) s -= 0.10;
    return s.clamp(0.1, 0.6);
  }

  /// 개인별 PM2.5 안전 임계값 T_final (μg/m³).
  ///
  /// 공식: T_final = 35 × (1 − S)
  /// 범위: S=0.1 → 31.5, S=0.6 → 14.0
  double get tFinal => 35.0 * (1.0 - sensitivityIndex);

  /// 페르소나 레이블 (Phase 3 대시보드 표출용)
  String get personaLabel {
    final active = outdoorMinutes >= 1;
    final sensitive = sensitivityLevel == 2 ||
        respiratoryStatus >= 1 ||
        isPregnant;

    if (active && sensitive) return '활동량이 많은 민감형 가디언';
    if (active) return '활동적인 야외형 가디언';
    if (sensitive) return '건강을 세심하게 챙기는 민감형 가디언';
    return '균형 잡힌 생활형 가디언';
  }

  // ── 팩토리 ──────────────────────────────────────────────

  factory UserProfile.defaultProfile() => UserProfile(
        nickname: '',
        birthYear: DateTime.now().year - 30,
        gender: 'male',
        respiratoryStatus: 0,
        sensitivityLevel: 1,
        isPregnant: false,
        recentSkinTreatment: false,
        outdoorMinutes: 1,
        activityTags: const [],
        discomfortLevel: 0,
      );

  // ── copyWith ─────────────────────────────────────────────

  UserProfile copyWith({
    String? nickname,
    int? birthYear,
    String? gender,
    int? respiratoryStatus,
    int? sensitivityLevel,
    bool? isPregnant,
    bool? recentSkinTreatment,
    int? outdoorMinutes,
    List<String>? activityTags,
    int? discomfortLevel,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      respiratoryStatus: respiratoryStatus ?? this.respiratoryStatus,
      sensitivityLevel: sensitivityLevel ?? this.sensitivityLevel,
      isPregnant: isPregnant ?? this.isPregnant,
      recentSkinTreatment: recentSkinTreatment ?? this.recentSkinTreatment,
      outdoorMinutes: outdoorMinutes ?? this.outdoorMinutes,
      activityTags: activityTags ?? this.activityTags,
      discomfortLevel: discomfortLevel ?? this.discomfortLevel,
    );
  }

  // ── 직렬화 ──────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'birthYear': birthYear,
        'gender': gender,
        'respiratoryStatus': respiratoryStatus,
        'sensitivityLevel': sensitivityLevel,
        'isPregnant': isPregnant,
        'recentSkinTreatment': recentSkinTreatment,
        'outdoorMinutes': outdoorMinutes,
        'activityTags': activityTags,
        'discomfortLevel': discomfortLevel,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // activityTags: dynamic → List<String> 안전 변환
    final rawTags = json['activityTags'];
    final List<String> tags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    return UserProfile(
      nickname: json['nickname'] as String? ?? '',
      birthYear: json['birthYear'] as int? ?? DateTime.now().year - 30,
      gender: json['gender'] as String? ?? 'male',
      respiratoryStatus: json['respiratoryStatus'] as int? ?? 0,
      sensitivityLevel: json['sensitivityLevel'] as int? ?? 1,
      isPregnant: json['isPregnant'] as bool? ?? false,
      recentSkinTreatment: json['recentSkinTreatment'] as bool? ?? false,
      outdoorMinutes: json['outdoorMinutes'] as int? ?? 1,
      activityTags: tags,
      discomfortLevel: json['discomfortLevel'] as int? ?? 0,
    );
  }
}

// ── 활동 태그 상수 ────────────────────────────────────────

/// Q9 활동 태그 식별자
class ActivityTag {
  static const String commute = 'commute';
  static const String walk = 'walk';
  static const String exercise = 'exercise';

  static String label(String tag) {
    switch (tag) {
      case commute:  return '출퇴근';
      case walk:     return '산책';
      case exercise: return '야외 운동';
      default:       return tag;
    }
  }
}
