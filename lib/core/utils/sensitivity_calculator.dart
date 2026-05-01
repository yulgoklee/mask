import '../../data/models/user_profile.dart';
import '../engine/threshold_engine.dart';

/// 민감도 계수(S) 관련 유틸리티 — UserProfile v2 기반 경량 래퍼
class SensitivityCalculator {
  SensitivityCalculator._();

  /// S 상한
  static const double sMax = 0.6;

  // ── 메인 API ──────────────────────────────────────────────

  /// 프로필로부터 민감도 계수(S) 반환
  // W_health + W_lifestyle 합산, [0.1, 0.6] clamp
  static double compute(UserProfile profile) {
    const engine = ThresholdEngine();
    final w = engine.computeWHealth(profile) + engine.computeWLifestyle(profile);
    return w.clamp(0.1, 0.6);
  }

  /// W_total(4가중치 합) → 알고리즘 평가 라벨
  ///
  /// 새 알고리즘이 사용자를 어떻게 평가하는지 보여주는 텍스트.
  /// 4가지 가중치(W_age, W_health, W_sensitivity, W_lifestyle) 모두 반영.
  static String label(double wTotal) {
    if (wTotal >= 0.5) return '고위험';
    if (wTotal >= 0.3) return '위험';
    if (wTotal >= 0.1) return '주의';
    return '일반';
  }

  /// sensitivityLevel(0/1/2) → 사용자 자기보고 라벨
  ///
  /// 사용자가 입력한 민감도 단계의 텍스트 표현.
  /// my_body_info_screen 기준 (어미 없음) — 단일 진실원.
  static String sensitivityLevelLabel(int level) {
    return switch (level) {
      1 => '조금 예민',
      2 => '매우 예민',
      _ => '무던함',
    };
  }

}
