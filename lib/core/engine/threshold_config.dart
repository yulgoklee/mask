/// ThresholdEngine 가중치 설정
///
/// 가중치 항목을 하드코딩 없이 관리하기 위한 설정 객체.
/// 향후 꽃가루 알레르기 등 신규 항목 추가 시 이 파일만 수정.
/// JSON 직렬화를 지원하여 Firebase Remote Config 또는 로컬 DB 연동 가능.

/// 건강 상태 가중치 항목 (우선순위 순으로 정렬)
/// 복수 해당 시 최상위 1개만 적용
class HealthWeightEntry {
  final String key;
  final double weight;
  final String label;

  const HealthWeightEntry({
    required this.key,
    required this.weight,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'weight': weight,
        'label': label,
      };

  factory HealthWeightEntry.fromJson(Map<String, dynamic> json) =>
      HealthWeightEntry(
        key: json['key'] as String,
        weight: (json['weight'] as num).toDouble(),
        label: json['label'] as String,
      );
}

/// 전체 임계값 연산 설정
class ThresholdConfig {
  /// PM2.5 기준치 (환경부 '나쁨' 진입점)
  final double tBase;

  /// T_final 하한선 (환경부 '좋음' 상한)
  final double tFloor;

  /// 건강 가중치 목록 — 우선순위 내림차순, 최댓값 1개 적용
  final List<HealthWeightEntry> healthWeights;

  /// 야외 활동 시간 가중치
  /// key: 'outdoor_3h_plus' | 'outdoor_1to3h' | 'outdoor_under_1h'
  final Map<String, double> lifestyleWeights;

  /// 마스크 필터 효율 상수
  /// key: 'KF94' | 'KF80'
  final Map<String, double> maskEfficiency;

  const ThresholdConfig({
    required this.tBase,
    required this.tFloor,
    required this.healthWeights,
    required this.lifestyleWeights,
    required this.maskEfficiency,
  });

  // ── 기본 설정 (환경보건학 근거 기반) ──────────────────────────

  static const ThresholdConfig defaults = ThresholdConfig(
    tBase: 35.0,
    tFloor: 15.0,
    healthWeights: [
      HealthWeightEntry(key: 'pregnancy',      weight: 0.35, label: '임신 중'),
      HealthWeightEntry(key: 'skin_treatment', weight: 0.30, label: '피부 시술 후 2주'),
      HealthWeightEntry(key: 'asthma',         weight: 0.25, label: '천식 등 호흡기 질환'),
      HealthWeightEntry(key: 'rhinitis',       weight: 0.20, label: '만성 비염'),
    ],
    lifestyleWeights: {
      'outdoor_3h_plus':  0.15,
      'outdoor_1to3h':    0.05,
      'outdoor_under_1h': 0.00,
    },
    maskEfficiency: {
      'KF94': 0.94,
      'KF80': 0.80,
    },
  );

  // ── JSON 직렬화 ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'tBase': tBase,
        'tFloor': tFloor,
        'healthWeights': healthWeights.map((e) => e.toJson()).toList(),
        'lifestyleWeights': lifestyleWeights,
        'maskEfficiency': maskEfficiency,
      };

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) =>
      ThresholdConfig(
        tBase: (json['tBase'] as num?)?.toDouble() ?? defaults.tBase,
        tFloor: (json['tFloor'] as num?)?.toDouble() ?? defaults.tFloor,
        healthWeights: (json['healthWeights'] as List<dynamic>?)
                ?.map((e) =>
                    HealthWeightEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            defaults.healthWeights,
        lifestyleWeights: (json['lifestyleWeights'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            defaults.lifestyleWeights,
        maskEfficiency: (json['maskEfficiency'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            defaults.maskEfficiency,
      );
}
