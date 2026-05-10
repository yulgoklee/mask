import '../../data/models/dust_data.dart';
import '../../data/models/user_profile.dart';
import '../constants/dust_standards.dart';

// 예보 체크 결과 레코드 타입
typedef ForecastCheckResult = ({bool maskRequired, String? maskType});

/// 개인 프로필 기반 위험도 계산 및 알림 판단
///
/// Tier 1 — T_final 비율 기반 5단계 위험도
class DustCalculator {
  static DustCalculationResult calculate(
    UserProfile profile,
    DustData dust,
  ) {
    final pm25 = dust.pm25Value;
    if (pm25 == null) {
      return const DustCalculationResult(
        riskLevel: RiskLevel.unknown,
        shouldSendRealtime: false,
        message: '미세먼지 데이터를 불러올 수 없어요.',
        heroText: '데이터를 불러오는 중이에요',
        reason: '',
        maskRequired: false,
        tFinal: 35.0,
      );
    }

    // ── Tier 1: final_ratio = max(PM2.5/T_pm25, PM10/T_pm10) ──
    // E-9: 모든 사용자 PM10 반영 (환경부 공식 max 결합 — 서울 사망률 연구 근거)
    // 호흡기 환자는 tFinal 낮음(W_resp 가중치)으로 자동으로 더 강하게 반응
    final tFinalPm25    = profile.tFinal;
    final pm10          = dust.pm10Value;
    final pm10ForCalc   = pm10;
    final ratio         = _computeFinalRatio(pm25: pm25, pm10: pm10ForCalc, tFinalPm25: tFinalPm25);
    final dominant      = _computeDominantPollutant(pm25: pm25, pm10: pm10ForCalc, tFinalPm25: tFinalPm25);

    final RiskLevel riskLevel;
    if (ratio < 0.5)      { riskLevel = RiskLevel.low; }
    else if (ratio < 0.7) { riskLevel = RiskLevel.normal; }
    else if (ratio < 1.0) { riskLevel = RiskLevel.warning; }
    else if (ratio < 1.5) { riskLevel = RiskLevel.danger; }
    else                  { riskLevel = RiskLevel.critical; }

    // maskRequired는 새 RiskLevel.danger 시작점(1.0)과 일치.
    // 새 warning(0.7~1.0)은 "조심" 단계로 마스크 권장 아님.
    final maskRequired = ratio >= 1.0;
    final maskType     = ratio >= 1.5 ? 'KF94' : ratio >= 1.0 ? 'KF80' : null;

    final shouldSendRealtime = ratio >= 1.5;

    final actualGrade = DustStandards.getPm25Grade(pm25);

    // ── 개인화 노트 (Tier 1) ─────────────────────────────────
    final personalNote = _buildPersonalNote(profile);

    // ── heroText ──────────────────────────────────────────────
    final heroText = _buildHeroText(riskLevel);

    return DustCalculationResult(
      riskLevel: riskLevel,
      shouldSendRealtime: shouldSendRealtime,
      message: _buildMessage(riskLevel, pm25, profile),
      heroText: heroText,
      reason: _buildReason(dominant: dominant, pm25: pm25, pm10: pm10ForCalc, pm25Grade: actualGrade.label),
      personalNote: personalNote,
      maskRequired: maskRequired,
      maskType: maskType,
      tFinal: tFinalPm25,
      dominantPollutant: dominant,
    );
  }

  // ── final_ratio 계산 헬퍼 ────────────────────────────────────

  static double _computeFinalRatio({
    required int pm25,
    required int? pm10,
    required double tFinalPm25,
  }) {
    final ratioPm25  = pm25 / tFinalPm25;
    final tFinalPm10 = tFinalPm25 * (80.0 / 35.0);
    final ratioPm10  = pm10 != null ? pm10 / tFinalPm10 : 0.0;
    return ratioPm25 > ratioPm10 ? ratioPm25 : ratioPm10;
  }

  /// 과거 시점의 final_ratio를 현재 프로필 기준으로 재계산.
  ///
  /// 리포트 인사이트 카드에서 과거 AQI 기록에 현재 T_final을 적용해
  /// 당시 위험 수준을 소급 평가할 때 사용한다.
  ///
  /// ```
  /// final_ratio = max(pm25 / T_final, pm10 / (T_final × 80/35))
  /// ```
  ///
  /// [tFinalPm25] 현재 프로필의 개인 PM2.5 임계치 (> 0 이어야 함)
  /// [pm25]       과거 시점 PM2.5 측정값 (null 또는 0이면 0.0 으로 처리)
  /// [pm10]       과거 시점 PM10 측정값 (null이면 PM10 비율을 0.0 으로 처리)
  static double computeHistoricalFinalRatio({
    required double tFinalPm25,
    required int? pm25,
    required int? pm10,
  }) {
    if (tFinalPm25 <= 0) return 0.0;
    final safePm25 = (pm25 ?? 0).clamp(0, double.maxFinite.toInt());
    return _computeFinalRatio(
      pm25: safePm25,
      pm10: pm10,
      tFinalPm25: tFinalPm25,
    );
  }

  static DominantPollutant _computeDominantPollutant({
    required int pm25,
    required int? pm10,
    required double tFinalPm25,
  }) {
    if (pm10 == null) return DominantPollutant.pm25;
    final ratioPm25  = pm25 / tFinalPm25;
    final tFinalPm10 = tFinalPm25 * (80.0 / 35.0);
    final ratioPm10  = pm10 / tFinalPm10;
    return ratioPm10 > ratioPm25 ? DominantPollutant.pm10 : DominantPollutant.pm25;
  }

  static String _buildReason({
    required DominantPollutant dominant,
    required int pm25,
    required int? pm10,
    required String pm25Grade,
  }) {
    if (dominant == DominantPollutant.pm10 && pm10 != null) {
      return '미세먼지 $pm10μg/m³ · 지배 / 초미세먼지 $pm25μg/m³ · $pm25Grade';
    }
    return '초미세먼지 $pm25μg/m³ · $pm25Grade';
  }

  // ── 예보 등급 기반 마스크 판단 (내일 예보 알림용) ────────────

  /// 내일 예보 등급 + 개인 T_final 기준으로 마스크 필요 여부 계산
  static ForecastCheckResult forecastCheck({
    required String gradeName,
    required UserProfile profile,
  }) {
    final actualGrade = DustGrade.fromString(gradeName) ?? DustGrade.good;

    // Tier 1 기본 판단 (나쁨 이상)
    bool maskRequired = actualGrade.index >= DustGrade.bad.index;
    String? maskType = maskRequired ? 'KF80' : null;

    // Tier 1 — T_final 기반 조기 판단
    // 예보에서는 등급 기준값(μg/m³) 사용
    final gradeValue = _gradeToMidPm25(actualGrade);
    final tFinal = profile.tFinal;
    if (gradeValue >= tFinal) {
      maskRequired = true;
      final sType = gradeValue >= tFinal * 1.5 ? 'KF94' : 'KF80';
      maskType = _stricterMaskType(maskType, sType);
    }

    return (maskRequired: maskRequired, maskType: maskType);
  }

  // ── 등급 대표 PM2.5 값 (예보 T_final 비교용) ─────────────────
  static double _gradeToMidPm25(DustGrade grade) {
    switch (grade) {
      case DustGrade.good:    return 10.0;
      case DustGrade.normal:  return 25.0;
      case DustGrade.bad:     return 55.0;
      case DustGrade.veryBad: return 90.0;
    }
  }

  // ── 홈 카드 행동 결론 문구 ─────────────────────────────────

  static String _buildHeroText(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:      return '오늘은 마스크 없어도 돼요';
      case RiskLevel.normal:   return '오늘은 대체로 괜찮아요';
      case RiskLevel.warning:  return '오늘 마스크 챙기는 게 좋아요';
      case RiskLevel.danger:   return '오늘 마스크 필수예요';
      case RiskLevel.critical: return '오늘 외출을 자제해주세요';
      case RiskLevel.unknown:  return '데이터를 불러오는 중이에요';
    }
  }

  /// 긴박 UI(펄스, 강조 등)가 필요한 등급 여부.
  /// danger 이상에서만 true — warning(0.7~1.0)은 "조심" 수준으로 긴박 UI 제외.
  static bool gradeRequiresUrgentUI(RiskLevel risk) =>
      risk == RiskLevel.danger || risk == RiskLevel.critical;

  // ── 개인화 맥락 한 줄 ─────────────────────────────────────

  static String? _buildPersonalNote(UserProfile profile) {
    if (profile.hasRespiratoryCondition) return '호흡기 질환 기준 적용';
    if (profile.isVulnerableAge) return '${profile.age}세 민감 연령 기준 적용';
    return null;
  }

  // ── 기존 message ──────────────────────────────────────────

  static String _buildMessage(RiskLevel risk, int pm25, UserProfile profile) {
    final display = profile.displayName;
    final p = display.isNotEmpty ? '$display, ' : '';
    switch (risk) {
      case RiskLevel.low:
        return '$p오늘 공기가 맑아요.\n마음껏 외출하셔도 좋아요 😊';
      case RiskLevel.normal:
        return '오늘은 보통 수준이에요.\n장시간 야외라면 마스크를 고려해보세요.';
      case RiskLevel.warning:
        return '$p오늘 마스크 챙겨가세요.\n초미세먼지 $pm25μg/m³, 조금 나빠요.';
      case RiskLevel.danger:
        return '$p지금 마스크 필수예요.\n초미세먼지 $pm25μg/m³, 매우 나빠요.';
      case RiskLevel.critical:
        return '$p오늘은 외출을 줄여주세요.\n초미세먼지 $pm25μg/m³, 심각한 수준이에요.';
      case RiskLevel.unknown:
        return '미세먼지 정보를 가져오고 있어요.';
    }
  }

  // ── 내부 헬퍼 ─────────────────────────────────────────────

  /// KF94 > KF80 > null 순으로 더 엄격한 마스크 타입 반환
  static String? _stricterMaskType(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    if (a == 'KF94' || b == 'KF94') return 'KF94';
    return 'KF80';
  }
}

// ── 계산 결과 ──────────────────────────────────────────────

class DustCalculationResult {
  final RiskLevel riskLevel;
  final bool shouldSendRealtime;
  final String message;                  // 기존 하위 호환용 (알림 fallback)
  final String heroText;                 // 홈 카드 행동 결론: "오늘 마스크 필요해요"
  final String reason;                   // 데이터 근거: "PM2.5 45μg/m³ · 나쁨"
  final String? personalNote;            // 개인화 맥락: "임신 중" (null이면 숨김)
  final bool maskRequired;
  final String? maskType;                // 'KF80' or 'KF94' or null
  final double tFinal;                   // 개인 PM2.5 임계치
  final DominantPollutant dominantPollutant; // 위험도 결정 오염원

  const DustCalculationResult({
    required this.riskLevel,
    required this.shouldSendRealtime,
    required this.message,
    required this.heroText,
    required this.reason,
    this.personalNote,
    required this.maskRequired,
    this.maskType,
    required this.tFinal,
    this.dominantPollutant = DominantPollutant.pm25,
  });
}

// ── DominantPollutant ─────────────────────────────────────

enum DominantPollutant { pm25, pm10 }

// ── RiskLevel ─────────────────────────────────────────────

enum RiskLevel {
  unknown,
  low,
  normal,
  warning,
  danger,
  critical;

  String get label {
    switch (this) {
      case RiskLevel.unknown:  return '-';
      case RiskLevel.low:      return '낮음';
      case RiskLevel.normal:   return '보통';
      case RiskLevel.warning:  return '주의';
      case RiskLevel.danger:   return '위험';
      case RiskLevel.critical: return '매우위험';
    }
  }
}
