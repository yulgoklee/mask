import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile.dart';

/// 민감도 계수(S) 관련 유틸리티 — UserProfile v2 기반 경량 래퍼
///
/// 핵심 계산은 UserProfile.sensitivityIndex / UserProfile.tFinal 에 내장됨.
/// 이 클래스는 외부 API (prefs 저장, 마스크 타입, 레이블) + 공개 가중치 헬퍼만 제공.
class SensitivityCalculator {
  SensitivityCalculator._();

  /// PM2.5 '보통' 상한 (환경부: ≤35 μg/m³)
  static const double tStandard = 35.0;

  /// S 상한
  static const double sMax = 0.6;

  /// S-based 조기 알림 최소 임계
  static const double sThreshold = 0.3;

  // ── SharedPreferences 키 ───────────────────────────────────
  static const String _prefKeyS         = 'sensitivity_score_s';
  static const String _prefKeyThreshold = 'sensitivity_threshold';

  // ── 메인 API ──────────────────────────────────────────────

  /// 프로필로부터 민감도 계수(S) 반환 (UserProfile.sensitivityIndex 위임)
  static double compute(UserProfile profile) => profile.sensitivityIndex;

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

  /// S → "일반인 대비 X.X배 민감" 배율
  static double sensitivityMultiplier(double s) {
    if (s >= 1.0) return double.infinity;
    return 1.0 / (1.0 - s);
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

  // ── 공개 가중치 헬퍼 (v2 필드 기반) ──────────────────────
  // onboarding_result_screen, result_screen 등에서 사용

  /// 호흡기 상태 가중치
  static double conditionWeight(UserProfile p) {
    if (p.respiratoryStatus == 2) return 0.3;
    if (p.respiratoryStatus == 1) return 0.15;
    return 0.0;
  }

  /// 야외 활동량 가중치
  static double activityWeight(UserProfile p) {
    if (p.outdoorMinutes == 2) return 0.2;
    if (p.outdoorMinutes == 1) return 0.1;
    return 0.0;
  }

  /// 주관적 민감도 가중치
  static double sensitivityWeightFromProfile(UserProfile p) {
    if (p.sensitivityLevel == 2) return 0.2;
    if (p.sensitivityLevel == 1) return 0.1;
    return 0.0;
  }

  /// 특별 상태 가중치 (임신 + 피부 시술)
  static double specialStateWeight(UserProfile p) {
    double w = 0.0;
    if (p.gender == 'female' && p.isPregnant) w += 0.30;
    if (p.recentSkinTreatment)               w += 0.25;
    return w;
  }

  /// 편의 성향 가중치 (discomfortLevel == 2 → 완화)
  static double prefWeight(UserProfile p) =>
      p.discomfortLevel == 2 ? -0.10 : 0.0;
}
