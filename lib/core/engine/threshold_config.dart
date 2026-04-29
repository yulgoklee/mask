// ThresholdEngine 가중치 설정
//
// 가중치 항목을 하드코딩 없이 관리하기 위한 설정 객체.
// 향후 꽃가루 알레르기 등 신규 항목 추가 시 이 파일만 수정.
// JSON 직렬화를 지원하여 Firebase Remote Config 또는 로컬 DB 연동 가능.

/// 건강 상태 가중치 항목 — 합산 방식 (복수 해당 시 모두 누적)
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
  /// PM2.5 기준치 (환경부 '나쁨' 진입점: 35 μg/m³)
  final double tBase;

  /// T_final 하한선 (WHO 2021 단기 권장: 15 μg/m³)
  final double tFloor;

  /// 건강 가중치 목록 — 합산 방식 (해당 항목 모두 누적)
  final List<HealthWeightEntry> healthWeights;

  /// 야외 활동 시간 가중치
  /// key: 'outdoor_3h_plus' | 'outdoor_1to3h' | 'outdoor_under_1h'
  final Map<String, double> lifestyleWeights;

  /// 연령 구간 가중치 (6구간)
  /// key: 'under_12' | '12_to_49' | '50_to_59' | '60_to_69' | '70_to_79' | '80_plus'
  final Map<String, double> ageWeights;

  /// 주관적 민감도 가중치 (3단계)
  /// key: 'level_0' | 'level_1' | 'level_2'
  final Map<String, double> sensitivityWeights;

  /// 마스크 필터 효율 상수
  /// key: 'KF94' | 'KF80'
  final Map<String, double> maskEfficiency;

  const ThresholdConfig({
    required this.tBase,
    required this.tFloor,
    required this.healthWeights,
    required this.lifestyleWeights,
    required this.ageWeights,
    required this.sensitivityWeights,
    required this.maskEfficiency,
  });

  // ── 기본 설정 ────────────────────────────────────────────────
  //
  // 근거 자료:
  //   - WHO 2021 Air Quality Guidelines (PM2.5 연간 5 μg/m³, 단기 15 μg/m³)
  //   - 환경부 PM2.5 4단계 등급 (좋음 ≤15, 보통 16~35, 나쁨 36~75, 매우나쁨 >75)
  //   - 대한천식알레르기학회 가이드라인 (천식 환자 실내외 노출 저감 권고)
  //   - NEJM 2017 Medicare cohort (65세+ 단기 노출 시 사망률 +7.3%/10μg)
  //   - One Earth 2024 메타분석 (PM2.5 10μg 증가 시 천식 위험 +7.1%)
  //   - Lancet GBD 2019 (전 세계 천식 부담 1/3이 PM2.5 기인)
  //   - 임신부 메타분석 (PM2.5 노출 증가 시 조산 +12%, 저체중아 +11%)

  static const ThresholdConfig defaults = ThresholdConfig(
    tBase:  35.0,
    tFloor: 15.0,
    healthWeights: [
      HealthWeightEntry(key: 'asthma',         weight: 0.20, label: '천식 등 호흡기 질환'),
      HealthWeightEntry(key: 'rhinitis',        weight: 0.15, label: '만성 비염'),
      HealthWeightEntry(key: 'pregnancy',       weight: 0.20, label: '임신 중'),
      HealthWeightEntry(key: 'skin_treatment',  weight: 0.10, label: '피부 시술 후 2주'),
    ],
    lifestyleWeights: {
      'outdoor_3h_plus':  0.07,
      'outdoor_1to3h':    0.03,
      'outdoor_under_1h': 0.00,
    },
    ageWeights: {
      'under_12':  0.10,
      '12_to_49':  0.00,
      '50_to_59':  0.03,
      '60_to_69':  0.06,
      '70_to_79':  0.10,
      '80_plus':   0.13,
    },
    sensitivityWeights: {
      'level_0': 0.00,
      'level_1': 0.02,
      'level_2': 0.05,
    },
    maskEfficiency: {
      'KF94': 0.94,
      'KF80': 0.80,
    },
  );

  // ── JSON 직렬화 ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'tBase':              tBase,
        'tFloor':             tFloor,
        'healthWeights':      healthWeights.map((e) => e.toJson()).toList(),
        'lifestyleWeights':   lifestyleWeights,
        'ageWeights':         ageWeights,
        'sensitivityWeights': sensitivityWeights,
        'maskEfficiency':     maskEfficiency,
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
        ageWeights: (json['ageWeights'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            defaults.ageWeights,
        sensitivityWeights:
            (json['sensitivityWeights'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
                defaults.sensitivityWeights,
        maskEfficiency: (json['maskEfficiency'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            defaults.maskEfficiency,
      );
}
