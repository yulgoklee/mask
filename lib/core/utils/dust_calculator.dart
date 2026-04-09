import '../../data/models/dust_data.dart';
import '../../data/models/user_profile.dart';
import '../constants/dust_standards.dart';

/// 개인 프로필 기반 위험도 계산 및 알림 판단
class DustCalculator {
  static DustCalculationResult calculate(UserProfile profile, DustData dust) {
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

    final grade = DustStandards.getPm25Grade(pm25);

    // 1. 연령 취약 여부 → 한 단계 강화
    DustGrade effectiveGrade = grade;
    if (profile.ageGroup.isVulnerable) {
      effectiveGrade = _upgradeGrade(grade);
    }

    // 2. 기저질환 여부 → 기준 강화
    if (profile.hasCondition) {
      effectiveGrade = _applyCondition(effectiveGrade, profile.severity);
    }

    // 3. 민감도 설정 반영
    if (profile.sensitivity == SensitivityLevel.high) {
      effectiveGrade = _upgradeGrade(effectiveGrade);
    } else if (profile.sensitivity == SensitivityLevel.low) {
      effectiveGrade = _downgradeGrade(effectiveGrade);
    }

    final riskLevel = _gradeToRisk(effectiveGrade);
    final maskRequired = riskLevel == RiskLevel.warning ||
        riskLevel == RiskLevel.danger ||
        riskLevel == RiskLevel.critical;

    final shouldSendRealtime = grade == DustGrade.veryBad &&
        riskLevel != RiskLevel.low &&
        riskLevel != RiskLevel.normal;

    return DustCalculationResult(
      riskLevel: riskLevel,
      shouldSendRealtime: shouldSendRealtime,
      message: _buildMessage(riskLevel, pm25, profile),
      heroText: _buildHeroText(riskLevel),
      reason: 'PM2.5 $pm25μg/m³ · ${grade.label}',
      personalNote: _buildPersonalNote(profile),
      maskRequired: maskRequired,
      maskType: _maskType(riskLevel),
    );
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

  // ── 개인화 맥락 한 줄 (적용된 기준 설명) ─────────────────────

  static String? _buildPersonalNote(UserProfile profile) {
    if (profile.hasCondition) {
      return '${profile.conditionType.label} 보유자 기준 적용';
    }
    if (profile.ageGroup.isVulnerable) {
      return '${profile.ageGroup.label} 민감 연령 기준 적용';
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
        return '$display, 오늘 마스크를 꼭 챙기세요.\nPM2.5 ${pm25}μg/m³로 나빠요.';
      case RiskLevel.danger:
        return '$display, 오늘 외출 시 마스크 필수예요.\nPM2.5 ${pm25}μg/m³로 매우 나빠요.';
      case RiskLevel.critical:
        return '$display, 오늘은 외출을 자제해주세요.\nPM2.5 ${pm25}μg/m³로 매우 심각해요.';
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
  final String? personalNote; // 개인화 맥락: "호흡기 질환 기준 적용" (null이면 숨김)
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
