import '../../data/models/user_profile.dart';
import 'threshold_config.dart';

/// 초개인화 임계값 연산 엔진
///
/// 공식: T_final = clamp(
///          T_base × (1 - W_age - W_health),
///          T_floor, T_base
///       )
///
/// W_age   : 연령 구간 단일 매핑 (under_12 / 60+ / 80+ 만 가중치 부여)
/// W_health: 카테고리 분리 합산
///   W_respiratory    = min(천식+COPD+비염+알레르기, respiratoryCap 0.30)
///   W_cardiovascular = min(고혈압+심장+뇌졸중, cardiovascularCap 0.25)
///   W_smoking        = 현재 0.20 / 과거 0.10 / 비흡연 0
class ThresholdEngine {
  final ThresholdConfig config;

  const ThresholdEngine({this.config = ThresholdConfig.defaults});

  // ── W_age ────────────────────────────────────────────────────

  /// 연령 구간 가중치 반환
  double computeWAge(UserProfile profile) {
    final age = profile.age;
    if (age < 12) return config.ageWeights['under_12']  ?? 0.0;
    if (age < 50) return config.ageWeights['12_to_49']  ?? 0.0;
    if (age < 60) return config.ageWeights['50_to_59']  ?? 0.0;
    if (age < 70) return config.ageWeights['60_to_69']  ?? 0.0;
    if (age < 80) return config.ageWeights['70_to_79']  ?? 0.0;
    return           config.ageWeights['80_plus']       ?? 0.0;
  }

  // ── W_health (카테고리 분리) ──────────────────────────────────

  /// 건강 상태 가중치 — 카테고리 분리 합산
  double computeWHealth(UserProfile profile) {
    return _computeWRespiratory(profile)
        + _computeWCardiovascular(profile)
        + _computeWSmoking(profile);
  }

  /// 호흡기 카테고리 (상한: respiratoryCap)
  /// 진단명 가중치 + 잠재 신호 가중치 합산 → cap 적용
  double _computeWRespiratory(UserProfile profile) {
    double raw = 0.0;
    final hw = config.healthWeights;
    if (profile.asthma)   raw += _weight(hw, 'asthma');
    if (profile.copd)     raw += _weight(hw, 'copd');
    if (profile.rhinitis) raw += _weight(hw, 'rhinitis');
    if (profile.allergy)  raw += _weight(hw, 'allergy');

    // 잠재 신호 (1.1.0+, 이중 카운팅 룰 R1 — 진단명 우선)
    raw += _computeRespiratorySignals(profile);

    final cap = config.respiratoryCap;
    return raw > cap ? cap : raw;
  }

  /// 잠재 신호 호흡기 가중치 (R1 이중 카운팅 방지)
  ///
  /// 매핑 (Phase 2 v0):
  ///  - signal_a1 (콧물·코막힘 4일+) ↔ rhinitis·allergy 진단명
  ///  - signal_b1 (야간 천식)         ↔ asthma 진단명
  ///  - signal_c1 (운동 후 호흡)      ↔ asthma 진단명
  ///  - signal_d3 (만성 가래 기침)    ↔ copd 진단명
  /// 진단명이 켜진 신호는 0 (R1).
  double _computeRespiratorySignals(UserProfile profile) {
    if (profile.signalAnswers.isEmpty) return 0.0;
    double raw = 0.0;
    final sw = config.signalWeights;
    if (profile.signalAnswers[SignalId.a1] == true
        && !profile.rhinitis && !profile.allergy) {
      raw += sw[SignalId.a1] ?? 0.0;
    }
    if (profile.signalAnswers[SignalId.b1] == true && !profile.asthma) {
      raw += sw[SignalId.b1] ?? 0.0;
    }
    if (profile.signalAnswers[SignalId.c1] == true && !profile.asthma) {
      raw += sw[SignalId.c1] ?? 0.0;
    }
    if (profile.signalAnswers[SignalId.d3] == true && !profile.copd) {
      raw += sw[SignalId.d3] ?? 0.0;
    }
    return raw;
  }

  /// 심혈관 카테고리 (상한: cardiovascularCap)
  double _computeWCardiovascular(UserProfile profile) {
    double raw = 0.0;
    final hw = config.healthWeights;
    if (profile.hypertension) raw += _weight(hw, 'hypertension');
    if (profile.heartDisease) raw += _weight(hw, 'heartDisease');
    if (profile.stroke)       raw += _weight(hw, 'stroke');
    final cap = config.cardiovascularCap;
    return raw > cap ? cap : raw;
  }

  /// 흡연 이력 가중치 (단독, 상한 없음)
  double _computeWSmoking(UserProfile profile) {
    final hw = config.healthWeights;
    switch (profile.smokingStatus) {
      case SmokingStatus.current: return _weight(hw, 'smoking_current');
      case SmokingStatus.former:  return _weight(hw, 'smoking_former');
      case SmokingStatus.never:   return 0.0;
    }
  }

  double _weight(List<HealthWeightEntry> entries, String key) =>
      entries
          .firstWhere((e) => e.key == key,
              orElse: () =>
                  const HealthWeightEntry(key: '', weight: 0.0, label: ''))
          .weight;

  // ── T_final ──────────────────────────────────────────────────

  /// 최종 PM2.5 알림 임계치 계산
  double computeTFinal(UserProfile profile) {
    final wAge    = computeWAge(profile);
    final wHealth = computeWHealth(profile);
    final raw = config.tBase * (1.0 - wAge - wHealth);
    return raw.clamp(config.tFloor, config.tBase);
  }

  /// 최종 PM10 알림 임계치 계산
  ///
  /// 환산 근거: 환경부 '보통' 상한 비율 (PM10 80 / PM2.5 35)
  double computeTFinalPm10(UserProfile profile) {
    return computeTFinal(profile) * (80.0 / 35.0);
  }

  // ── 마스크 등급 추천 ─────────────────────────────────────────

  /// 호흡기 환자 또는 W_health ≥ 0.20 → KF94
  String recommendedMaskType(UserProfile profile) {
    if (profile.hasRespiratoryCondition) return 'KF94';
    if (computeWHealth(profile) >= 0.20) return 'KF94';
    return 'KF80';
  }

  // ── 노출량 계산 ──────────────────────────────────────────────

  /// 마스크 착용 시 실제 흡입 농도 (μg/m³)
  double filteredExposure(double pm25, String maskType) {
    final efficiency = config.maskEfficiency[maskType] ?? 0.80;
    return pm25 * (1.0 - efficiency);
  }

  /// 마스크 미착용 대비 방어한 농도 (μg/m³)
  double blockedExposure(double pm25, String maskType) {
    final efficiency = config.maskEfficiency[maskType] ?? 0.80;
    return pm25 * efficiency;
  }

  // ── 트리거 판단 ──────────────────────────────────────────────

  /// 현재 PM2.5가 개인 임계값 이상인지 (알림 트리거 조건)
  bool isDangerZone(double currentPm25, double tFinal) =>
      currentPm25 >= tFinal;

  /// PM10 재난 알림 트리거 여부 (환경부 '매우 나쁨' 기준: ≥150)
  bool isPm10Emergency(int? pm10Value) =>
      pm10Value != null && pm10Value >= 150;

  /// PM2.5 재난 알림 트리거 여부 (야간 방해금지 예외 기준: ≥75)
  bool isPm25Emergency(double pm25) => pm25 >= 75.0;

  // ── 디버그 정보 ──────────────────────────────────────────────

  ThresholdBreakdown breakdown(UserProfile profile) {
    final wAge           = computeWAge(profile);
    final wRespiratory   = _computeWRespiratory(profile);
    final wCardiovascular = _computeWCardiovascular(profile);
    final wSmoking       = _computeWSmoking(profile);
    final wTotal         = wAge + wRespiratory + wCardiovascular + wSmoking;
    final tFinalRaw      = config.tBase * (1.0 - wTotal);
    final tFinal         = tFinalRaw.clamp(config.tFloor, config.tBase);
    return ThresholdBreakdown(
      wAge:              wAge,
      wRespiratory:      wRespiratory,
      wCardiovascular:   wCardiovascular,
      wSmoking:          wSmoking,
      wTotal:            wTotal,
      tFinalRaw:         tFinalRaw,
      tFinal:            tFinal,
      maskType:          recommendedMaskType(profile),
    );
  }
}

/// T_final 연산 상세 내역 (UI 표시 / 디버깅용)
class ThresholdBreakdown {
  final double wAge;
  final double wRespiratory;
  final double wCardiovascular;
  final double wSmoking;
  final double wTotal;    // 전체 가중치 합
  final double tFinalRaw; // clamp 적용 전 원본값
  final double tFinal;    // clamp 적용 후 최종값
  final String maskType;

  const ThresholdBreakdown({
    required this.wAge,
    required this.wRespiratory,
    required this.wCardiovascular,
    required this.wSmoking,
    required this.wTotal,
    required this.tFinalRaw,
    required this.tFinal,
    required this.maskType,
  });

  double get wHealth => wRespiratory + wCardiovascular + wSmoking;

  bool get floorApplied => tFinalRaw < 15.0;

  @override
  String toString() =>
      'T_final=$tFinal (raw=$tFinalRaw, '
      'W_age=$wAge W_resp=$wRespiratory W_cardio=$wCardiovascular '
      'W_smoke=$wSmoking '
      'W_total=$wTotal${floorApplied ? ' → floor 적용' : ''}, mask=$maskType)';
}
