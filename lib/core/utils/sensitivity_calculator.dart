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

  /// S → 민감도 레이블 (UI 표시용)
  static String label(double s) {
    if (s >= 0.5) return '매우 높음';
    if (s >= 0.3) return '높음';
    if (s >= 0.1) return '보통';
    return '낮음';
  }

}
