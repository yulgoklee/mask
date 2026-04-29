import '../../data/models/user_profile.dart';
import '../engine/threshold_engine.dart';

/// 민감도 계수(S) 관련 유틸리티 — UserProfile v2 기반 경량 래퍼
class SensitivityCalculator {
  SensitivityCalculator._();

  /// PM2.5 '보통' 상한 (환경부: ≤35 μg/m³)
  static const double tStandard = 35.0;

  /// S 상한
  static const double sMax = 0.6;

  /// S-based 조기 알림 최소 임계
  static const double sThreshold = 0.3;

  // ── 메인 API ──────────────────────────────────────────────

  /// 프로필로부터 민감도 계수(S) 반환
  // W_health + W_lifestyle 합산, [0.1, 0.6] clamp — Phase 3에서 전체 재설계 예정
  static double compute(UserProfile profile) {
    const engine = ThresholdEngine();
    final w = engine.computeWHealth(profile) + engine.computeWLifestyle(profile);
    return w.clamp(0.1, 0.6);
  }

  /// S → 최종 PM2.5 알림 임계치 (μg/m³)
  static double threshold(double s) => tStandard * (1.0 - s);

  /// S → 민감도 레이블 (UI 표시용)
  static String label(double s) {
    if (s >= 0.5) return '매우 높음';
    if (s >= 0.3) return '높음';
    if (s >= 0.1) return '보통';
    return '낮음';
  }

  // ── 공개 가중치 헬퍼 (v2 필드 기반) ──────────────────────
  // result_screen 등에서 사용

  /// 호흡기·건강 상태 가중치 — ThresholdEngine 위임 (우선순위-max)
  static double conditionWeight(UserProfile p) =>
      const ThresholdEngine().computeWHealth(p);

  /// 야외 활동량 가중치 — ThresholdEngine 위임
  static double activityWeight(UserProfile p) =>
      const ThresholdEngine().computeWLifestyle(p);

  /// 주관적 민감도 가중치
  static double sensitivityWeightFromProfile(UserProfile p) {
    if (p.sensitivityLevel == 2) return 0.10;
    if (p.sensitivityLevel == 1) return 0.05;
    return 0.0;
  }

  /// 특별 상태 가중치 (임신 + 피부 시술)
  static double specialStateWeight(UserProfile p) {
    double w = 0.0;
    if (p.gender == 'female' && p.isPregnant) w += 0.30;
    if (p.isSkinTreatmentActive)              w += 0.25;
    return w;
  }

  /// 편의 성향 가중치 (discomfortLevel == 2 → 완화)
  static double prefWeight(UserProfile p) =>
      p.discomfortLevel == 2 ? -0.10 : 0.0;
}
