import '../../data/models/user_profile.dart';
import 'threshold_config.dart';

/// 초개인화 임계값 연산 엔진
///
/// 공식: T_final = clamp(
///          T_base × (1 - W_age - W_health - W_sensitivity - W_lifestyle),
///          T_floor, T_base
///       )
///
/// W_age        : 연령 6구간 단일 매핑
/// W_health     : 건강 상태 합산 (복수 해당 시 모두 누적)
/// W_sensitivity: 주관적 민감도 3단계 단일 매핑
/// W_lifestyle  : 야외 활동 시간 단일 매핑
class ThresholdEngine {
  final ThresholdConfig config;

  const ThresholdEngine({this.config = ThresholdConfig.defaults});

  // ── W_age ────────────────────────────────────────────────────

  /// 연령 구간 가중치 반환 (6구간 단일 매핑)
  double computeWAge(UserProfile profile) {
    final age = profile.age;
    if (age < 12) return config.ageWeights['under_12']  ?? 0.0;
    if (age < 50) return config.ageWeights['12_to_49']  ?? 0.0;
    if (age < 60) return config.ageWeights['50_to_59']  ?? 0.0;
    if (age < 70) return config.ageWeights['60_to_69']  ?? 0.0;
    if (age < 80) return config.ageWeights['70_to_79']  ?? 0.0;
    return           config.ageWeights['80_plus']       ?? 0.0;
  }

  // ── W_health ─────────────────────────────────────────────────

  /// 건강 상태 가중치 반환 — 합산 방식 (해당 항목 모두 누적)
  ///
  /// 임신은 gender 가드 유지: female 또는 미선택(empty)인 경우만 적용.
  double computeWHealth(UserProfile profile) {
    double total = 0.0;
    for (final entry in config.healthWeights) {
      switch (entry.key) {
        case 'asthma':
          if (profile.respiratoryStatus & 2 != 0) total += entry.weight;
        case 'rhinitis':
          if (profile.respiratoryStatus & 1 != 0) total += entry.weight;
        case 'pregnancy':
          if ((profile.gender == 'female' || profile.gender.isEmpty) &&
              profile.isPregnant) {
            total += entry.weight;
          }
        case 'skin_treatment':
          if (profile.isSkinTreatmentActive) total += entry.weight;
      }
    }
    return total;
  }

  // ── W_sensitivity ────────────────────────────────────────────

  /// 주관적 민감도 가중치 반환 (3단계 단일 매핑)
  double computeWSensitivity(UserProfile profile) {
    final key = 'level_${profile.sensitivityLevel}';
    return config.sensitivityWeights[key] ?? 0.0;
  }

  // ── W_lifestyle ──────────────────────────────────────────────

  /// 야외 활동 시간 가중치 반환
  double computeWLifestyle(UserProfile profile) {
    final lw = config.lifestyleWeights;
    if (profile.outdoorMinutes == 2) return lw['outdoor_3h_plus']  ?? 0.0;
    if (profile.outdoorMinutes == 1) return lw['outdoor_1to3h']    ?? 0.0;
    return                                  lw['outdoor_under_1h'] ?? 0.0;
  }

  // ── T_final ──────────────────────────────────────────────────

  /// 최종 PM2.5 알림 임계치 계산
  ///
  /// 내부 정밀도 유지: double 반환. 표시 시 toInt() 적용은 호출자 책임.
  double computeTFinal(UserProfile profile) {
    final wAge         = computeWAge(profile);
    final wHealth      = computeWHealth(profile);
    final wSensitivity = computeWSensitivity(profile);
    final wLifestyle   = computeWLifestyle(profile);
    final raw = config.tBase * (1.0 - wAge - wHealth - wSensitivity - wLifestyle);
    return raw.clamp(config.tFloor, config.tBase);
  }

  /// 최종 PM10 알림 임계치 계산
  ///
  /// 환산 근거: 환경부 '보통' 상한 비율 (PM10 80 / PM2.5 35)
  double computeTFinalPm10(UserProfile profile) {
    return computeTFinal(profile) * (80.0 / 35.0);
  }

  // ── 마스크 등급 추천 ─────────────────────────────────────────

  /// W_health 기반 권장 마스크 등급
  ///
  /// 천식(0.20) 이상 고위험군 → KF94, 그 외 → KF80
  String recommendedMaskType(UserProfile profile) {
    final wHealth = computeWHealth(profile);
    if (wHealth >= (config.healthWeights
            .firstWhere((e) => e.key == 'asthma',
                orElse: () =>
                    const HealthWeightEntry(key: 'asthma', weight: 0.20, label: ''))
            .weight)) {
      return 'KF94';
    }
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
    final wAge         = computeWAge(profile);
    final wHealth      = computeWHealth(profile);
    final wSensitivity = computeWSensitivity(profile);
    final wLifestyle   = computeWLifestyle(profile);
    final wTotal       = wAge + wHealth + wSensitivity + wLifestyle;
    final tFinalRaw    = config.tBase * (1.0 - wTotal);
    final tFinal       = tFinalRaw.clamp(config.tFloor, config.tBase);
    return ThresholdBreakdown(
      wAge:         wAge,
      wHealth:      wHealth,
      wSensitivity: wSensitivity,
      wLifestyle:   wLifestyle,
      wTotal:       wTotal,
      tFinalRaw:    tFinalRaw,
      tFinal:       tFinal,
      maskType:     recommendedMaskType(profile),
    );
  }
}

/// T_final 연산 상세 내역 (UI 표시 / 디버깅용)
class ThresholdBreakdown {
  final double wAge;
  final double wHealth;
  final double wSensitivity;
  final double wLifestyle;
  final double wTotal;      // 4개 가중치 합
  final double tFinalRaw;   // clamp 적용 전 원본값
  final double tFinal;      // clamp 적용 후 최종값
  final String maskType;

  const ThresholdBreakdown({
    required this.wAge,
    required this.wHealth,
    required this.wSensitivity,
    required this.wLifestyle,
    required this.wTotal,
    required this.tFinalRaw,
    required this.tFinal,
    required this.maskType,
  });

  bool get floorApplied => tFinalRaw < 15.0;

  @override
  String toString() =>
      'T_final=$tFinal (raw=$tFinalRaw, '
      'W_age=$wAge W_h=$wHealth W_s=$wSensitivity W_l=$wLifestyle '
      'W_total=$wTotal${floorApplied ? ' → floor 적용' : ''}, mask=$maskType)';
}
