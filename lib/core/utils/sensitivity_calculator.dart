import '../../data/models/user_profile.dart';

/// 개인 프로필 → 민감도 계수(S) 계산
///
/// ────────────────────────────────────────────────────────
///  공식: S = min(w1 + w2 + w3, 0.6)
///
///   w1 — 기저질환 가중치
///        없음: 0.0 / 경증: 0.2 / 중등도·중증: 0.3
///
///   w2 — 야외 활동량 가중치
///        낮음(주 1~2회): 0.0 / 보통(매일 외출): 0.1 / 높음: 0.2
///
///   w3 — 주관적 민감도 가중치
///        낮음: 0.0 / 보통: 0.1 / 높음: 0.2
///
///  최종 알림 임계치: T_final = T_standard × (1 − S)
///  T_standard = 35 μg/m³  (PM2.5 '보통' 상한, 환경부 기준)
///
///  예시: S = 0.5  →  T_final = 35 × 0.5 = 17.5 μg/m³
///        (일반인 기준 36 μg/m³보다 18.5 낮은 수치에서 알림)
/// ────────────────────────────────────────────────────────
class SensitivityCalculator {
  SensitivityCalculator._();

  /// PM2.5 '보통' 상한 (환경부: ≤35 μg/m³)
  static const double tStandard = 35.0;

  /// S 상한 — 0.6 초과 시 알림이 너무 잦아짐
  static const double sMax = 0.6;

  /// S-based 조기 알림 최소 임계
  /// S < sThreshold 이면 기존 등급(Grade) 로직만 사용
  static const double sThreshold = 0.3;

  // ── 메인 API ──────────────────────────────────────────────

  /// 프로필로부터 민감도 계수(S) 계산
  static double compute(UserProfile profile) {
    final w1 = _conditionWeight(profile);
    final w2 = _activityWeight(profile.activityLevel);
    final w3 = _sensitivityWeight(profile.sensitivity);
    return (w1 + w2 + w3).clamp(0.0, sMax);
  }

  /// S → 최종 PM2.5 알림 임계치 (μg/m³)
  static double threshold(double s) => tStandard * (1.0 - s);

  /// S → 마스크 권장 등급 문자열 ('KF80' / 'KF94' / null)
  static String? maskType(double s) {
    if (s >= 0.4) return 'KF94';
    if (s >= sThreshold) return 'KF80';
    return null;
  }

  /// S → 민감도 레이블 (UI 표시용)
  static String label(double s) {
    if (s >= 0.5) return '매우 높음';
    if (s >= 0.3) return '높음';
    if (s >= 0.1) return '보통';
    return '낮음';
  }

  // ── 가중치 계산 ───────────────────────────────────────────

  /// w1 — 기저질환 가중치
  ///  없음: 0.0 / 경증: 0.2 / 중등도·중증: 0.3
  static double _conditionWeight(UserProfile profile) {
    if (!profile.hasCondition) return 0.0;
    return profile.severity == Severity.mild ? 0.2 : 0.3;
  }

  /// w2 — 야외 활동량 가중치
  ///  낮음: 0.0 / 보통: 0.1 / 높음: 0.2
  static double _activityWeight(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.low:
        return 0.0;
      case ActivityLevel.normal:
        return 0.1;
      case ActivityLevel.high:
        return 0.2;
    }
  }

  /// w3 — 주관적 민감도 가중치
  ///  낮음: 0.0 / 보통: 0.1 / 높음: 0.2
  static double _sensitivityWeight(SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.low:
        return 0.0;
      case SensitivityLevel.normal:
        return 0.1;
      case SensitivityLevel.high:
        return 0.2;
    }
  }
}
