import '../../data/models/dust_data.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../constants/dust_standards.dart';

// 예보 체크 결과 레코드 타입
typedef ForecastCheckResult = ({bool maskRequired, String? maskType});

/// 개인 프로필 기반 위험도 계산 및 알림 판단
///
/// 3-tier 구조:
///   Tier 1 — 고정 프로필 (나이, 기저질환, 민감도)
///   Tier 2 — 기간 상태  (임신, 시술 후, 항암 등)
///   Tier 3 — 오늘의 상황 (야외 운동, 몸 상태 안 좋음)
///
/// 세 티어 중 가장 엄격한 기준이 최종 결과에 반영된다.
class DustCalculator {
  static DustCalculationResult calculate(
    UserProfile profile,
    DustData dust, {
    List<TemporaryState> temporaryStates = const [],
    List<TodaySituation> todaySituations = const [],
  }) {
    final pm25 = dust.pm25Value;
    if (pm25 == null) {
      return const DustCalculationResult(
        riskLevel: RiskLevel.unknown,
        shouldSendRealtime: false,
        message: '미세먼지 데이터를 불러올 수 없어요.',
        heroText: '데이터를 불러오는 중이에요',
        reason: '',
        maskRequired: false,
      );
    }

    final actualGrade = DustStandards.getPm25Grade(pm25);

    // ── Tier 1: 고정 프로필 기반 등급 조정 ─────────────────────

    DustGrade effectiveGrade = actualGrade;

    if (profile.isVulnerableAge) {
      effectiveGrade = _upgradeGrade(effectiveGrade);
    }
    if (profile.hasCondition) {
      effectiveGrade = _applyCondition(effectiveGrade, profile.severity);
    }
    if (profile.sensitivity == SensitivityLevel.high) {
      effectiveGrade = _upgradeGrade(effectiveGrade);
    } else if (profile.sensitivity == SensitivityLevel.low) {
      effectiveGrade = _downgradeGrade(effectiveGrade);
    }

    final riskLevel = _gradeToRisk(effectiveGrade);
    bool maskRequired = riskLevel == RiskLevel.warning ||
        riskLevel == RiskLevel.danger ||
        riskLevel == RiskLevel.critical;
    String? maskType = _maskType(riskLevel);

    final shouldSendRealtime = actualGrade == DustGrade.veryBad &&
        riskLevel != RiskLevel.low &&
        riskLevel != RiskLevel.normal;

    // ── Tier 2: 기간 상태 ────────────────────────────────────

    String? tier2Note;
    for (final state in temporaryStates.where((s) => s.isActive)) {
      final needsMask = state.alwaysMask ||
          actualGrade.index >= state.maskThresholdGrade.index;
      if (needsMask) {
        maskRequired = true;
        maskType = _stricterMaskType(maskType, state.maskType);
        tier2Note ??= state.label;
      }
    }

    // ── Tier 3: 오늘의 상황 ──────────────────────────────────

    String? tier3Note;
    for (final situation in todaySituations.where((s) => s.isActive)) {
      final needsMask =
          actualGrade.index >= situation.maskThresholdGrade.index;
      if (needsMask) {
        maskRequired = true;
        maskType = _stricterMaskType(maskType, situation.maskType);
        tier3Note ??= situation.label;
      }
    }

    // ── 개인화 노트 (우선순위: Tier2 > Tier3 > Tier1) ───────────

    final personalNote =
        tier2Note ?? tier3Note ?? _buildPersonalNote(profile);

    // ── 행동 결론 heroText ────────────────────────────────────
    // 공기 자체는 괜찮지만 취약 상태 때문에 마스크가 필요한 경우
    // 기존 heroText 대신 명확한 문구로 교체

    final baseHeroText = _buildHeroText(riskLevel);
    final heroText = (!_gradeRequiresMask(riskLevel) && maskRequired)
        ? '오늘 마스크 챙기세요'
        : baseHeroText;

    return DustCalculationResult(
      riskLevel: riskLevel,
      shouldSendRealtime: shouldSendRealtime,
      message: _buildMessage(riskLevel, pm25, profile),
      heroText: heroText,
      reason: '초미세먼지 $pm25μg/m³ · ${actualGrade.label}',
      personalNote: personalNote,
      maskRequired: maskRequired,
      maskType: maskType,
    );
  }

  // ── 예보 등급 기반 마스크 판단 (내일 예보 알림용) ────────────

  /// 내일 예보 등급 + 취약 상태를 고려해 마스크 필요 여부 계산
  ///
  /// - 일반 기준: 나쁨(36+) 이상
  /// - Tier 2 기준: 상태별 임계치에 따라 보통(16+)부터 가능
  /// - 오늘의 상황(Tier 3)은 예보에 미적용 (내일 상황은 알 수 없음)
  static ForecastCheckResult forecastCheck({
    required String gradeName,
    required UserProfile profile,
    List<TemporaryState> temporaryStates = const [],
  }) {
    final actualGrade = DustGrade.fromString(gradeName) ?? DustGrade.good;

    // Tier 1 기본 판단 (나쁨 이상)
    bool maskRequired = actualGrade.index >= DustGrade.bad.index;
    String? maskType = maskRequired ? 'KF80' : null;

    // Tier 1 — 연령/기저질환/민감도 보정
    DustGrade effectiveGrade = actualGrade;
    if (profile.isVulnerableAge) {
      effectiveGrade = _upgradeGrade(effectiveGrade);
    }
    if (profile.hasCondition) {
      effectiveGrade = _applyCondition(effectiveGrade, profile.severity);
    }
    if (profile.sensitivity == SensitivityLevel.high) {
      effectiveGrade = _upgradeGrade(effectiveGrade);
    }
    final tier1Risk = _gradeToRisk(effectiveGrade);
    if (_gradeRequiresMask(tier1Risk)) {
      maskRequired = true;
      maskType = _stricterMaskType(maskType, _maskType(tier1Risk));
    }

    // Tier 2 — 기간 상태 임계치 확인
    for (final state in temporaryStates.where((s) => s.isActive)) {
      if (state.alwaysMask ||
          actualGrade.index >= state.maskThresholdGrade.index) {
        maskRequired = true;
        maskType = _stricterMaskType(maskType, state.maskType);
      }
    }

    return (maskRequired: maskRequired, maskType: maskType);
  }

  // ── 홈 카드 행동 결론 문구 ─────────────────────────────────

  static String _buildHeroText(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:      return '오늘은 마스크 없어도 돼요';
      case RiskLevel.normal:   return '오늘은 대체로 괜찮아요';
      case RiskLevel.warning:  return '오늘 마스크 챙기세요';
      case RiskLevel.danger:   return '오늘 마스크 필수예요';
      case RiskLevel.critical: return '오늘 외출을 자제해주세요';
      case RiskLevel.unknown:  return '데이터를 불러오는 중이에요';
    }
  }

  static bool _gradeRequiresMask(RiskLevel risk) =>
      risk == RiskLevel.warning ||
      risk == RiskLevel.danger ||
      risk == RiskLevel.critical;

  // ── 개인화 맥락 한 줄 (적용된 기준 설명) ─────────────────────

  static String? _buildPersonalNote(UserProfile profile) {
    if (profile.hasCondition) {
      return '${profile.conditionType.label} 보유자 기준 적용';
    }
    if (profile.isVulnerableAge) {
      final ageLabel = profile.age != null
          ? '${profile.age}세'
          : profile.ageGroup.label;
      return '$ageLabel 민감 연령 기준 적용';
    }
    if (profile.sensitivity == SensitivityLevel.high) {
      return '고민감도 설정 기준 적용';
    }
    if (profile.sensitivity == SensitivityLevel.low) {
      return '저민감도 설정 기준 적용';
    }
    return null;
  }

  // ── 기존 message (알림 fallback 용) ──────────────────────────

  static String _buildMessage(RiskLevel risk, int pm25, UserProfile profile) {
    final display = profile.displayName;
    switch (risk) {
      case RiskLevel.low:
        return '$display, 오늘 공기가 맑아요 😊\n마음껏 외출하셔도 좋아요.';
      case RiskLevel.normal:
        return '오늘은 보통 수준이에요.\n장시간 야외 활동 시 마스크를 고려하세요.';
      case RiskLevel.warning:
        return '$display, 오늘 마스크를 꼭 챙기세요.\nPM2.5 $pm25μg/m³로 나빠요.';
      case RiskLevel.danger:
        return '$display, 오늘 외출 시 마스크 필수예요.\nPM2.5 $pm25μg/m³로 매우 나빠요.';
      case RiskLevel.critical:
        return '$display, 오늘은 외출을 자제해주세요.\nPM2.5 $pm25μg/m³로 매우 심각해요.';
      case RiskLevel.unknown:
        return '미세먼지 정보를 불러올 수 없어요.';
    }
  }

  // ── 내부 헬퍼 ─────────────────────────────────────────────

  static String? _maskType(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.warning:  return 'KF80';
      case RiskLevel.danger:   return 'KF94';
      case RiskLevel.critical: return 'KF94';
      default: return null;
    }
  }

  /// KF94 > KF80 > null 순으로 더 엄격한 마스크 타입 반환
  static String? _stricterMaskType(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    if (a == 'KF94' || b == 'KF94') return 'KF94';
    return 'KF80';
  }

  static DustGrade _upgradeGrade(DustGrade grade) {
    final idx = grade.index;
    if (idx >= DustGrade.values.length - 1) return grade;
    return DustGrade.values[idx + 1];
  }

  static DustGrade _downgradeGrade(DustGrade grade) {
    final idx = grade.index;
    if (idx <= 0) return grade;
    return DustGrade.values[idx - 1];
  }

  static DustGrade _applyCondition(DustGrade grade, Severity severity) {
    switch (severity) {
      case Severity.mild:
        if (grade.index >= DustGrade.normal.index) {
          return _upgradeGrade(grade);
        }
        return grade;
      case Severity.moderate:
      case Severity.severe:
        return _upgradeGrade(grade);
    }
  }

  static RiskLevel _gradeToRisk(DustGrade grade) {
    switch (grade) {
      case DustGrade.good:    return RiskLevel.low;
      case DustGrade.normal:  return RiskLevel.normal;
      case DustGrade.bad:     return RiskLevel.warning;
      case DustGrade.veryBad: return RiskLevel.critical;
    }
  }
}

// ── 계산 결과 ──────────────────────────────────────────────

class DustCalculationResult {
  final RiskLevel riskLevel;
  final bool shouldSendRealtime;
  final String message;       // 기존 하위 호환용 (알림 fallback)
  final String heroText;      // 홈 카드 행동 결론: "오늘 마스크 필요해요"
  final String reason;        // 데이터 근거: "PM2.5 45μg/m³ · 나쁨"
  final String? personalNote; // 개인화 맥락: "임신 중" (null이면 숨김)
  final bool maskRequired;
  final String? maskType;     // 'KF80' or 'KF94' or null

  const DustCalculationResult({
    required this.riskLevel,
    required this.shouldSendRealtime,
    required this.message,
    required this.heroText,
    required this.reason,
    this.personalNote,
    required this.maskRequired,
    this.maskType,
  });
}

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
      case RiskLevel.unknown:  return '알수없음';
      case RiskLevel.low:      return '안전';
      case RiskLevel.normal:   return '보통';
      case RiskLevel.warning:  return '주의';
      case RiskLevel.danger:   return '나쁨';
      case RiskLevel.critical: return '매우나쁨';
    }
  }
}
