import '../../core/engine/threshold_engine.dart';

/// 흡연 이력 상태
enum SmokingStatus {
  current, // 현재 흡연 중
  former,  // 과거 흡연 (금연)
  never,   // 비흡연
}

/// 사용자 그룹 (알림/케어 카피 분기용)
enum UserGroup {
  main,    // 취약 사용자 (호흡기/심혈관/60+/현재흡연)
  general, // 일반 사용자
}

/// 개인 건강 프로필 모델 v4 (2026-05-07: 활동·민감도 영구 제거)
///
/// 호흡기 4 + 심혈관 3 + 흡연 + 기본 정보 (닉네임·생년·성별)
class UserProfile {
  final String nickname;
  final int birthYear;
  final String gender; // 'male' | 'female' | ''

  // ── 호흡기 ─────────────────────────────────────────────────
  final bool asthma;
  final bool rhinitis;
  final bool copd;
  final bool allergy;

  // ── 심혈관 ─────────────────────────────────────────────────
  final bool hypertension;
  final bool heartDisease;
  final bool stroke;

  // ── 기타 건강 상태 ──────────────────────────────────────────
  final SmokingStatus smokingStatus;

  // ── 흡연 종류 (smokingStatus == current 일 때만 의미 있음) ──
  final bool smokesCigarette; // 연초 (일반 담배)
  final bool smokesHeated;    // 가열식 (IQOS, glo 등)
  final bool smokesVaping;    // 전자담배 (액상형)

  // ── 관심 지역 (Stage 3 iOS Fallback용) ──────────────────────
  final String homeStationName;
  final String officeStationName;

  const UserProfile({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.asthma,
    required this.rhinitis,
    required this.copd,
    required this.allergy,
    required this.hypertension,
    required this.heartDisease,
    required this.stroke,
    required this.smokingStatus,
    this.smokesCigarette = false,
    this.smokesHeated    = false,
    this.smokesVaping    = false,
    this.homeStationName  = '',
    this.officeStationName = '',
  });

  // ── 계산 속성 ──────────────────────────────────────────────

  /// 실제 나이
  int get age => DateTime.now().year - birthYear;

  /// 취약 연령 여부 (18세 미만 or 60세 이상)
  bool get isVulnerableAge => age < 18 || age >= 60;

  /// 알림/홈 화면 호칭 ("지수님" 또는 빈 문자열)
  String get displayName => nickname.isNotEmpty ? '$nickname님' : '';

  /// 호흡기 질환 보유 여부 (PM10 max 적용 분기에 사용)
  bool get hasRespiratoryCondition => asthma || rhinitis || copd || allergy;

  /// 심혈관 질환 보유 여부
  bool get hasCardiovascularCondition =>
      hypertension || heartDisease || stroke;

  /// 메인 사용자 여부 (취약 그룹)
  bool get isMainUser =>
      hasRespiratoryCondition ||
      hasCardiovascularCondition ||
      age >= 60 ||
      smokingStatus == SmokingStatus.current;

  /// 사용자 그룹 (케어 탭 분기용)
  UserGroup get userGroup => isMainUser ? UserGroup.main : UserGroup.general;

  /// 최종 PM2.5 알림 임계치 (μg/m³)
  ///
  /// 공식: clamp(35 × (1 − W_age − W_health), 15, 35)
  /// W_health = W_respiratory + W_cardiovascular + W_smoking
  double get tFinal => const ThresholdEngine().computeTFinal(this);

  // ── 팩토리 ────────────────────────────────────────────────

  factory UserProfile.defaultProfile() => const UserProfile(
        nickname:       '',
        birthYear:      1990,
        gender:         '',
        asthma:         false,
        rhinitis:       false,
        copd:           false,
        allergy:        false,
        hypertension:   false,
        heartDisease:   false,
        stroke:         false,
        smokingStatus:  SmokingStatus.never,
      );

  // ── copyWith ──────────────────────────────────────────────

  UserProfile copyWith({
    String? nickname,
    int? birthYear,
    String? gender,
    bool? asthma,
    bool? rhinitis,
    bool? copd,
    bool? allergy,
    bool? hypertension,
    bool? heartDisease,
    bool? stroke,
    SmokingStatus? smokingStatus,
    bool? smokesCigarette,
    bool? smokesHeated,
    bool? smokesVaping,
    String? homeStationName,
    String? officeStationName,
  }) {
    return UserProfile(
      nickname:          nickname          ?? this.nickname,
      birthYear:         birthYear         ?? this.birthYear,
      gender:            gender            ?? this.gender,
      asthma:            asthma            ?? this.asthma,
      rhinitis:          rhinitis          ?? this.rhinitis,
      copd:              copd              ?? this.copd,
      allergy:           allergy           ?? this.allergy,
      hypertension:      hypertension      ?? this.hypertension,
      heartDisease:      heartDisease      ?? this.heartDisease,
      stroke:            stroke            ?? this.stroke,
      smokingStatus:     smokingStatus     ?? this.smokingStatus,
      smokesCigarette:   smokesCigarette   ?? this.smokesCigarette,
      smokesHeated:      smokesHeated      ?? this.smokesHeated,
      smokesVaping:      smokesVaping      ?? this.smokesVaping,
      homeStationName:   homeStationName   ?? this.homeStationName,
      officeStationName: officeStationName ?? this.officeStationName,
    );
  }

  // ── JSON 직렬화 ───────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'nickname':          nickname,
        'birthYear':         birthYear,
        'gender':            gender,
        'asthma':            asthma,
        'rhinitis':          rhinitis,
        'copd':              copd,
        'allergy':           allergy,
        'hypertension':      hypertension,
        'heartDisease':      heartDisease,
        'stroke':            stroke,
        'smokingStatus':     smokingStatus.name,
        'smokesCigarette':   smokesCigarette,
        'smokesHeated':      smokesHeated,
        'smokesVaping':      smokesVaping,
        'homeStationName':   homeStationName,
        'officeStationName': officeStationName,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 구버전 respiratoryStatus 비트플래그 하위 호환
    final legacyStatus = json['respiratoryStatus'] as int? ?? 0;

    return UserProfile(
      nickname:  json['nickname']  as String? ?? '',
      birthYear: json['birthYear'] as int?    ?? 1990,
      gender:    json['gender']    as String? ?? '',
      // 신규 필드 없으면 legacyStatus 비트플래그로 폴백
      asthma:    json['asthma']    as bool?   ?? (legacyStatus & 2) != 0,
      rhinitis:  json['rhinitis']  as bool?   ?? (legacyStatus & 1) != 0,
      copd:      json['copd']      as bool?   ?? false,
      allergy:   json['allergy']   as bool?   ?? false,
      hypertension: json['hypertension'] as bool? ?? false,
      heartDisease: json['heartDisease'] as bool? ?? false,
      stroke:       json['stroke']       as bool? ?? false,
      smokingStatus: SmokingStatus.values.byName(
          json['smokingStatus'] as String? ?? 'never'),
      smokesCigarette: json['smokesCigarette'] as bool? ?? false,
      smokesHeated:    json['smokesHeated']    as bool? ?? false,
      smokesVaping:    json['smokesVaping']    as bool? ?? false,
      // activityTags·discomfortLevel은 v4(2026-05-07)에서 제거됨.
      // 옛 JSON에 키 있어도 자동 무시됨 (사용자 0명, 마이그레이션 불필요).
      homeStationName:   json['homeStationName']   as String? ?? '',
      officeStationName: json['officeStationName'] as String? ?? '',
    );
  }
}
