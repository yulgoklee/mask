/// 활동 태그 상수
class ActivityTag {
  static const String commute   = 'commute';   // 출퇴근
  static const String walk      = 'walk';       // 산책
  static const String exercise  = 'exercise';  // 운동
  static const String delivery  = 'delivery';  // 배달/외근
  static const String childcare = 'childcare'; // 아이 등하원
}

/// 개인 건강 프로필 모델 v2
///
/// 10개 필드 기반 (enum 미사용)
class UserProfile {
  final String nickname;              // Q1 표시 이름
  final int birthYear;                // Q2 출생연도 (기본 1990)
  final String gender;                // Q3 'male'|'female'|'other'
  /// Q4 호흡기 상태 — 비트플래그
  /// 0=건강, 1=비염, 2=천식, 3=비염+천식
  final int respiratoryStatus;
  final int sensitivityLevel;         // Q5 0=무던 1=보통 2=예민
  final bool isPregnant;              // Q6 female only
  final bool recentSkinTreatment;     // Q7 피부 시술 받았는지 여부
  final DateTime? skinTreatmentDate;  // Q7 시술 날짜 (null = 날짜 미입력)
  final int outdoorMinutes;           // Q8 0=1h미만 1=1~3h 2=3h이상
  final List<String> activityTags;    // Q9 활동 태그 목록
  final int discomfortLevel;          // Q10 0=안느낌 1=보통 2=많이불편

  const UserProfile({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.respiratoryStatus,
    required this.sensitivityLevel,
    required this.isPregnant,
    required this.recentSkinTreatment,
    this.skinTreatmentDate,
    required this.outdoorMinutes,
    required this.activityTags,
    required this.discomfortLevel,
  });

  // ── 계산 속성 ──────────────────────────────────────────────

  /// 실제 나이
  int get age => DateTime.now().year - birthYear;

  /// 취약 연령 여부 (18세 미만 or 60세 이상)
  bool get isVulnerableAge => age < 18 || age >= 60;

  /// 알림/홈 화면 호칭 ("율곡님" or "사용자님")
  /// 닉네임 미입력 시 '님'만 남는 어색한 표현 방지
  String get displayName => nickname.isNotEmpty ? '$nickname님' : '사용자님';

  /// 피부 시술 효과 활성 여부
  /// - 날짜가 없으면 사용자가 "받았어요"를 눌렀으므로 활성으로 간주
  /// - 날짜가 있으면 14일(2주) 이내인 경우만 활성
  bool get isSkinTreatmentActive {
    if (!recentSkinTreatment) return false;
    if (skinTreatmentDate == null) return true;
    return DateTime.now().difference(skinTreatmentDate!).inDays <= 14;
  }

  /// 호흡기 상태 레이블 (비트플래그 기반)
  String get respiratoryLabel {
    final hasRhinitis = respiratoryStatus & 1 != 0;
    final hasAsthma   = respiratoryStatus & 2 != 0;
    if (hasRhinitis && hasAsthma) return '비염+천식';
    if (hasAsthma)                return '천식 등 질환';
    if (hasRhinitis)              return '비염 있음';
    return '건강함';
  }

  /// 민감도 계수 S ([0.1, 0.6] clamp)
  ///
  /// 기저 0.0에서 시작해 각 조건에 따라 가중치 누적
  double get sensitivityIndex {
    double s = 0.0;
    if (isVulnerableAge)                       s += 0.10;
    if (respiratoryStatus & 1 != 0)            s += 0.15; // 비염 (bit 0)
    if (respiratoryStatus & 2 != 0)            s += 0.30; // 천식 (bit 1)
    if (sensitivityLevel == 1)                 s += 0.05; // 보통
    if (sensitivityLevel == 2)                 s += 0.10; // 매우 예민
    if ((gender == 'female' || gender.isEmpty) && isPregnant) s += 0.30; // 임신 (성별 미선택 포함)
    if (isSkinTreatmentActive)                 s += 0.25; // 피부 시술 (2주 내)
    if (outdoorMinutes == 1)                   s += 0.05; // 1~3h
    if (outdoorMinutes == 2)                   s += 0.10; // 3h이상
    // Q9 활동 태그 — 운동·배달 +5%, 기타 +3%, 최대 +10%
    double tagW = 0.0;
    for (final tag in activityTags) {
      tagW += (tag == ActivityTag.exercise || tag == ActivityTag.delivery)
          ? 0.05
          : 0.03;
    }
    s += tagW.clamp(0.0, 0.10);
    if (discomfortLevel == 2)                  s -= 0.10; // 많이 불편 (완화)
    return s.clamp(0.1, 0.6);
  }

  /// 최종 PM2.5 알림 임계치 (μg/m³)
  double get tFinal => 35.0 * (1.0 - sensitivityIndex);

  /// 페르소나 레이블
  String get personaLabel {
    final s = sensitivityIndex;
    if (s >= 0.5)                          return '복합 고위험군';
    if (s >= 0.35 && respiratoryStatus & 2 != 0) return '호흡기 취약형';
    if (s >= 0.35 && isPregnant)           return '임산부 보호형';
    if (s >= 0.3)                          return '민감형 관리자';
    if (outdoorMinutes == 2)               return '활동형 아웃도어';
    return '기본 관리형';
  }

  // ── 팩토리 ────────────────────────────────────────────────

  factory UserProfile.defaultProfile() => const UserProfile(
        nickname: '',
        birthYear: 1990,
        gender: '', // 기본값: 미선택 상태
        respiratoryStatus: 0,
        sensitivityLevel: 1,
        isPregnant: false,
        recentSkinTreatment: false,
        skinTreatmentDate: null,
        outdoorMinutes: 1,
        activityTags: [],
        discomfortLevel: 1,
      );

  // ── copyWith ──────────────────────────────────────────────

  UserProfile copyWith({
    String? nickname,
    int? birthYear,
    String? gender,
    int? respiratoryStatus,
    int? sensitivityLevel,
    bool? isPregnant,
    bool? recentSkinTreatment,
    // skinTreatmentDate를 null로 지우려면 clearSkinTreatmentDate: true 사용
    DateTime? skinTreatmentDate,
    bool clearSkinTreatmentDate = false,
    int? outdoorMinutes,
    List<String>? activityTags,
    int? discomfortLevel,
  }) {
    return UserProfile(
      nickname:            nickname           ?? this.nickname,
      birthYear:           birthYear          ?? this.birthYear,
      gender:              gender             ?? this.gender,
      respiratoryStatus:   respiratoryStatus  ?? this.respiratoryStatus,
      sensitivityLevel:    sensitivityLevel   ?? this.sensitivityLevel,
      isPregnant:          isPregnant         ?? this.isPregnant,
      recentSkinTreatment: recentSkinTreatment ?? this.recentSkinTreatment,
      skinTreatmentDate:   clearSkinTreatmentDate
                               ? null
                               : (skinTreatmentDate ?? this.skinTreatmentDate),
      outdoorMinutes:      outdoorMinutes     ?? this.outdoorMinutes,
      activityTags:        activityTags       ?? this.activityTags,
      discomfortLevel:     discomfortLevel    ?? this.discomfortLevel,
    );
  }

  // ── JSON 직렬화 ───────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'nickname':            nickname,
        'birthYear':           birthYear,
        'gender':              gender,
        'respiratoryStatus':   respiratoryStatus,
        'sensitivityLevel':    sensitivityLevel,
        'isPregnant':          isPregnant,
        'recentSkinTreatment': recentSkinTreatment,
        'skinTreatmentDate':   skinTreatmentDate?.toIso8601String(),
        'outdoorMinutes':      outdoorMinutes,
        'activityTags':        activityTags,
        'discomfortLevel':     discomfortLevel,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final d = UserProfile.defaultProfile();
    final skinDateStr = json['skinTreatmentDate'] as String?;
    return UserProfile(
      nickname:            json['nickname']            as String?  ?? d.nickname,
      birthYear:           json['birthYear']           as int?     ?? d.birthYear,
      gender:              json['gender']              as String?  ?? d.gender,
      respiratoryStatus:   json['respiratoryStatus']  as int?     ?? d.respiratoryStatus,
      sensitivityLevel:    json['sensitivityLevel']   as int?     ?? d.sensitivityLevel,
      isPregnant:          json['isPregnant']          as bool?    ?? d.isPregnant,
      recentSkinTreatment: json['recentSkinTreatment'] as bool?   ?? d.recentSkinTreatment,
      skinTreatmentDate:   skinDateStr != null
                               ? DateTime.tryParse(skinDateStr)
                               : null,
      outdoorMinutes:      json['outdoorMinutes']      as int?     ?? d.outdoorMinutes,
      activityTags:        (json['activityTags'] as List<dynamic>?)
                               ?.cast<String>()                   ?? d.activityTags,
      discomfortLevel:     json['discomfortLevel']    as int?     ?? d.discomfortLevel,
    );
  }
}
