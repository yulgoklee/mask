import '../../data/models/user_profile.dart';
import 'threshold_config.dart';

/// 초개인화 임계값 연산 엔진 (Stage 1 Core Engine)
///
/// 공식: T_final = T_base × (1 - W_health - W_lifestyle)
///       max(계산값, T_floor) → 하한 15 μg/m³ 보장
///
/// W_health  : 건강 상태 가중치 — 복수 해당 시 최댓값 1개만 적용 (우선순위 기반)
/// W_lifestyle: 야외 활동 시간 가중치
class ThresholdEngine {
  final ThresholdConfig config;

  const ThresholdEngine({this.config = ThresholdConfig.defaults});

  // ── W_health ────────────────────────────────────────────────

  /// 건강 상태 가중치 반환
  ///
  /// config.healthWeights 순서(우선순위 내림차순)로 순회하며
  /// 처음 해당하는 항목의 weight만 반환 (복수 해당 시 최댓값 1개).
  double computeWHealth(UserProfile profile) {
    for (final entry in config.healthWeights) {
      switch (entry.key) {
        case 'pregnancy':
          if ((profile.gender == 'female' || profile.gender.isEmpty) &&
              profile.isPregnant) {
            return entry.weight;
          }
        case 'skin_treatment':
          if (profile.isSkinTreatmentActive) return entry.weight;
        case 'asthma':
          if (profile.respiratoryStatus & 2 != 0) return entry.weight;
        case 'rhinitis':
          if (profile.respiratoryStatus & 1 != 0) return entry.weight;
        // 향후 신규 항목 추가 시 여기에 case 추가
      }
    }
    return 0.0;
  }

  // ── W_lifestyle ─────────────────────────────────────────────

  /// 야외 활동 시간 가중치 반환
  double computeWLifestyle(UserProfile profile) {
    final lw = config.lifestyleWeights;
    if (profile.outdoorMinutes == 2) {
      return lw['outdoor_3h_plus'] ?? 0.15;
    }
    if (profile.outdoorMinutes == 1) {
      return lw['outdoor_1to3h'] ?? 0.05;
    }
    return lw['outdoor_under_1h'] ?? 0.0;
  }

  // ── T_final ─────────────────────────────────────────────────

  /// 최종 PM2.5 알림 임계치 계산
  ///
  /// 하한선 적용: max(calculated, T_floor)
  double computeTFinal(UserProfile profile) {
    final wHealth    = computeWHealth(profile);
    final wLifestyle = computeWLifestyle(profile);
    final raw        = config.tBase * (1.0 - wHealth - wLifestyle);
    return raw.clamp(config.tFloor, config.tBase);
  }

  /// 최종 PM10 알림 임계치 계산
  ///
  /// 환산 근거: 환경부 '보통' 상한 비율 (PM10 80 / PM2.5 35)
  /// T_final_pm10 = T_final_pm25 × (80 / 35)
  double computeTFinalPm10(UserProfile profile) {
    return computeTFinal(profile) * (80.0 / 35.0);
  }

  // ── 마스크 등급 추천 ─────────────────────────────────────────

  /// W_health 기반 권장 마스크 등급
  ///
  /// 임신 / 시술 / 천식 → KF94
  /// 비염 / 일반 → KF80
  String recommendedMaskType(UserProfile profile) {
    final wHealth = computeWHealth(profile);
    // 기준: 천식(0.25) 이상 고위험군 → KF94
    if (wHealth >= config.healthWeights
        .firstWhere(
          (e) => e.key == 'asthma',
          orElse: () => const HealthWeightEntry(
              key: 'asthma', weight: 0.25, label: ''),
        )
        .weight) {
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

  /// PM10 재난 알림 트리거 여부 (야간 방해금지 예외 기준)
  bool isPm10Emergency(int? pm10Value) =>
      pm10Value != null && pm10Value >= 150; // 환경부 '매우 나쁨' 기준

  /// PM2.5 재난 알림 트리거 여부 (야간 방해금지 예외 기준: 75 μg/m³)
  bool isPm25Emergency(double pm25) => pm25 >= 75.0;

  // ── 디버그 정보 ──────────────────────────────────────────────

  ThresholdBreakdown breakdown(UserProfile profile) {
    final wH = computeWHealth(profile);
    final wL = computeWLifestyle(profile);
    final tFinal = computeTFinal(profile);
    return ThresholdBreakdown(
      tBase: config.tBase,
      wHealth: wH,
      wLifestyle: wL,
      tCalculated: config.tBase * (1.0 - wH - wL),
      tFinal: tFinal,
      floorApplied: tFinal == config.tFloor,
      maskType: recommendedMaskType(profile),
    );
  }
}

/// T_final 연산 상세 내역 (UI 표시 / 디버깅용)
class ThresholdBreakdown {
  final double tBase;
  final double wHealth;
  final double wLifestyle;
  final double tCalculated;
  final double tFinal;
  final bool floorApplied;
  final String maskType;

  const ThresholdBreakdown({
    required this.tBase,
    required this.wHealth,
    required this.wLifestyle,
    required this.tCalculated,
    required this.tFinal,
    required this.floorApplied,
    required this.maskType,
  });

  @override
  String toString() =>
      'T_final=$tFinal (T_base=$tBase × (1 - W_h=$wHealth - W_l=$wLifestyle)'
      '${floorApplied ? ' → floor 적용' : ''}, mask=$maskType)';
}
