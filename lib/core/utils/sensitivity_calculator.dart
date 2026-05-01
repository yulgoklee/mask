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

  /// wTotal → 위험도 레이블 (UI 표시용)
  static String label(double wTotal) {
    if (wTotal >= 0.5) return '고위험';
    if (wTotal >= 0.3) return '위험';
    if (wTotal >= 0.1) return '주의';
    return '일반';
  }

  /// sensitivityLevel (0/1/2) → 체감 민감도 레이블 (단일 소스)
  static String sensitivityLevelLabel(int level) {
    return switch (level) {
      1 => '조금 예민',
      2 => '매우 예민',
      _ => '무던함',
    };
  }

}
