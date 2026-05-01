// ThresholdEngine 가중치 설정
//
// 가중치 항목을 하드코딩 없이 관리하기 위한 설정 객체.
// 향후 신규 항목 추가 시 이 파일과 ThresholdEngine만 수정.
// JSON 직렬화를 지원하여 Firebase Remote Config 또는 로컬 DB 연동 가능.

/// 건강 상태 가중치 항목
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

  /// 건강 가중치 목록 — 카테고리 분리 방식
  final List<HealthWeightEntry> healthWeights;

  /// 연령 구간 가중치
  /// key: 'under_12' | '12_to_49' | '50_to_59' | '60_to_69' | '70_to_79' | '80_plus'
  final Map<String, double> ageWeights;

  /// 호흡기 카테고리 상한 (천식+COPD+비염+알레르기 합산의 최대값)
  final double respiratoryCap;

  /// 심혈관 카테고리 상한 (고혈압+심장+뇌졸중 합산의 최대값)
  final double cardiovascularCap;

  /// 마스크 필터 효율 상수
  /// key: 'KF94' | 'KF80'
  final Map<String, double> maskEfficiency;

  const ThresholdConfig({
    required this.tBase,
    required this.tFloor,
    required this.healthWeights,
    required this.ageWeights,
    required this.respiratoryCap,
    required this.cardiovascularCap,
    required this.maskEfficiency,
  });

  // ── 기본 설정 ────────────────────────────────────────────────
  //
  // 근거 자료:
  //   - WHO 2021 Air Quality Guidelines (PM2.5 단기 15 μg/m³)
  //   - 환경부 PM2.5 4단계 등급 (나쁨 진입점: 35 μg/m³)
  //   - GOLD 2023 / WHO: COPD 환자 대기오염 급성 악화 위험
  //   - One Earth 2024 메타분석: PM2.5 10μg 증가 시 천식 위험 +7.1%
  //   - Lancet GBD 2019: 전 세계 천식 부담 1/3이 PM2.5 기인
  //   - AHA 2021 Scientific Statement: 대기오염과 심혈관 질환 위험
  //   - NEJM 2017 Medicare cohort: 65세+ 단기 노출 시 사망률 +7.3%/10μg
  //   - 임신부 메타분석: PM2.5 노출 증가 시 조산 +12%, 저체중아 +11%
  //   - WHO: 흡연자 폐 손상 누적 — PM2.5 취약성 복합 가중

  static const ThresholdConfig defaults = ThresholdConfig(
    tBase:  35.0,
    tFloor: 15.0,
    respiratoryCap:    0.30, // 호흡기 카테고리 상한
    cardiovascularCap: 0.25, // 심혈관 카테고리 상한
    healthWeights: [
      // ── 호흡기 (합산 상한: respiratoryCap = 0.30) ─────────────
      // One Earth 2024: 천식 환자 PM2.5 급성 악화 위험
      HealthWeightEntry(key: 'asthma',       weight: 0.20, label: '천식'),
      // GOLD 2023: COPD 급성 악화 — 천식보다 높은 기도 손상 위험
      HealthWeightEntry(key: 'copd',         weight: 0.25, label: 'COPD'),
      // 대한비과학회: 비염 기도 과민성 — 오염물질 반응 증폭
      HealthWeightEntry(key: 'rhinitis',     weight: 0.15, label: '비염'),
      // EAACI: 알레르기 환자 PM2.5 기도 염증 반응
      HealthWeightEntry(key: 'allergy',      weight: 0.15, label: '알레르기'),

      // ── 심혈관 (합산 상한: cardiovascularCap = 0.25) ──────────
      // AHA 2021: 고혈압 환자 PM2.5 혈관 산화스트레스 위험
      HealthWeightEntry(key: 'hypertension', weight: 0.15, label: '고혈압'),
      // NEJM + AHA: 심장 질환자 PM2.5 심근허혈·부정맥 트리거
      HealthWeightEntry(key: 'heartDisease', weight: 0.20, label: '심장 질환'),
      // Lancet + 뇌졸중 학회: PM2.5 혈관 염증 — 재발 위험
      HealthWeightEntry(key: 'stroke',       weight: 0.15, label: '뇌졸중'),

      // ── 흡연 이력 (단독, 상한 없음) ───────────────────────────
      // WHO: 흡연자 폐 손상 누적 — PM2.5 취약성 증가
      HealthWeightEntry(key: 'smoking_current', weight: 0.20, label: '현재 흡연'),
      HealthWeightEntry(key: 'smoking_former',  weight: 0.10, label: '과거 흡연'),

      // ── 특별 상태 (고정값) ─────────────────────────────────────
      // 임신부 메타분석: 태아 저산소증·조산 위험
      HealthWeightEntry(key: 'pregnancy',    weight: 0.20, label: '임신'),
    ],
    ageWeights: {
      'under_12':  0.10,
      '12_to_49':  0.00,
      '50_to_59':  0.00, // 50대 가중치 제거 (근거 불충분)
      '60_to_69':  0.06,
      '70_to_79':  0.10,
      '80_plus':   0.13,
    },
    maskEfficiency: {
      'KF94': 0.94,
      'KF80': 0.80,
    },
  );

  // ── JSON 직렬화 ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'tBase':             tBase,
        'tFloor':            tFloor,
        'healthWeights':     healthWeights.map((e) => e.toJson()).toList(),
        'ageWeights':        ageWeights,
        'respiratoryCap':    respiratoryCap,
        'cardiovascularCap': cardiovascularCap,
        'maskEfficiency':    maskEfficiency,
      };

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) =>
      ThresholdConfig(
        tBase:  (json['tBase']  as num?)?.toDouble() ?? defaults.tBase,
        tFloor: (json['tFloor'] as num?)?.toDouble() ?? defaults.tFloor,
        healthWeights: (json['healthWeights'] as List<dynamic>?)
                ?.map((e) =>
                    HealthWeightEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            defaults.healthWeights,
        ageWeights: (json['ageWeights'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            defaults.ageWeights,
        respiratoryCap: (json['respiratoryCap'] as num?)?.toDouble() ??
            defaults.respiratoryCap,
        cardiovascularCap:
            (json['cardiovascularCap'] as num?)?.toDouble() ??
                defaults.cardiovascularCap,
        maskEfficiency: (json['maskEfficiency'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            defaults.maskEfficiency,
      );
}
