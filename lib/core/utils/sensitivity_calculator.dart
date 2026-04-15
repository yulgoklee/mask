import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile.dart';

/// 개인 프로필 → 민감도 계수(S) 계산
///
/// ────────────────────────────────────────────────────────
///  공식: S = clamp(w1 + w2 + w3 + w_spec + w_pref, 0.0, 0.6)
///
///   w1     — 기저질환 가중치
///            없음: 0.0 / 경증: 0.2 / 중등도·중증: 0.3
///
///   w2     — 야외 활동량 가중치
///            낮음: 0.0 / 보통: 0.1 / 높음: 0.2
///
///   w3     — 주관적 민감도 가중치
///            낮음: 0.0 / 보통: 0.1 / 높음: 0.2
///
///   w_spec — 특별 상태 가중치
///            피부 시술 후 2주: +0.25 / 영유아·고령자 부양: +0.15
///
///   w_pref — 편의 성향 가중치 (마스크 답답함 → T_final 소폭 완화)
///            답답함 있음: -0.08  (T_final 상향 → 덜 자주 울림)
///
///  최종 알림 임계치: T_final = T_standard × (1 − S)
///  T_standard = 35 μg/m³  (PM2.5 '보통' 상한, 환경부 기준)
///
///  예시: S = 0.5  →  T_final = 35 × 0.5 = 17.5 μg/m³
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

  // ── SharedPreferences 키 ───────────────────────────────────
  static const String _prefKeyS         = 'sensitivity_score_s';
  static const String _prefKeyThreshold = 'sensitivity_threshold';

  // ── 메인 API ──────────────────────────────────────────────

  /// 프로필로부터 민감도 계수(S) 계산
  static double compute(UserProfile profile) {
    final w1    = _conditionWeight(profile);
    final w2    = _activityWeight(profile.activityLevel);
    final w3    = _sensitivityWeight(profile.sensitivity);
    final wSpec = _specialStateWeight(profile);
    final wPref = _prefWeight(profile);
    return (w1 + w2 + w3 + wSpec + wPref).clamp(0.0, sMax);
  }

  /// S → 최종 PM2.5 알림 임계치 (μg/m³)
  static double threshold(double s) => tStandard * (1.0 - s);

  /// S → 마스크 권장 등급 문자열 ('KF80' / 'KF94' / null)
  static String? maskType(double s) {
    if (s >= 0.4) return 'KF94';
    if (s >= sThreshold) return 'KF80';
    return null;
  }

  // ── SharedPreferences 저장 / 로드 ─────────────────────────

  /// 프로필로부터 S·T_final 계산 후 prefs에 저장
  static Future<void> saveToPrefs(
      SharedPreferences prefs, UserProfile profile) async {
    final s = compute(profile);
    await prefs.setDouble(_prefKeyS, s);
    await prefs.setDouble(_prefKeyThreshold, threshold(s));
  }

  static double? loadS(SharedPreferences prefs) =>
      prefs.getDouble(_prefKeyS);

  static double? loadThreshold(SharedPreferences prefs) =>
      prefs.getDouble(_prefKeyThreshold);

  /// S → "일반인 대비 X.X배 민감" 배율
  static double sensitivityMultiplier(double s) {
    if (s >= 1.0) return double.infinity;
    return 1.0 / (1.0 - s);
  }

  /// S → 민감도 레이블 (UI 표시용)
  static String label(double s) {
    if (s >= 0.5) return '매우 높음';
    if (s >= 0.3) return '높음';
    if (s >= 0.1) return '보통';
    return '낮음';
  }

  // ── 가중치 계산 (공개 API) ────────────────────────────────

  static double conditionWeight(UserProfile profile) =>
      _conditionWeight(profile);
  static double activityWeight(ActivityLevel level) =>
      _activityWeight(level);
  static double sensitivityWeight(SensitivityLevel level) =>
      _sensitivityWeight(level);
  static double specialStateWeight(UserProfile profile) =>
      _specialStateWeight(profile);
  static double prefWeight(UserProfile profile) =>
      _prefWeight(profile);

  // ── 가중치 계산 (내부) ───────────────────────────────────

  static double _conditionWeight(UserProfile profile) {
    if (!profile.hasCondition) return 0.0;
    return profile.severity == Severity.mild ? 0.2 : 0.3;
  }

  static double _activityWeight(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.low:    return 0.0;
      case ActivityLevel.normal: return 0.1;
      case ActivityLevel.high:   return 0.2;
    }
  }

  static double _sensitivityWeight(SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.low:    return 0.0;
      case SensitivityLevel.normal: return 0.1;
      case SensitivityLevel.high:   return 0.2;
    }
  }

  /// w_spec — 특별 상태 가중치 (누적 가능)
  static double _specialStateWeight(UserProfile profile) {
    double w = 0.0;
    if (profile.hasSkinProcedure) w += 0.25; // 피부 시술 후 2주 → 매우 민감
    if (profile.hasDependents)    w += 0.15; // 영유아·고령자 부양 → 보호 강화
    return w;
  }

  /// w_pref — 마스크 불편 성향 (T_final 소폭 완화)
  /// 답답함이 심하면 알림 기준을 약간 올려줌 (강제보다는 편의 반영)
  static double _prefWeight(UserProfile profile) =>
      profile.maskDiscomfort ? -0.08 : 0.0;
}
