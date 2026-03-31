import '../../data/models/dust_data.dart';
import '../../data/models/user_profile.dart';
import '../constants/dust_standards.dart';

/// 개인 프로필 기반 위험도 계산 및 알림 판단
class DustCalculator {
  static DustCalculationResult calculate(UserProfile profile, DustData dust) {
    final pm25 = dust.pm25Value;
    if (pm25 == null) {
      return DustCalculationResult(
        riskLevel: RiskLevel.unknown,
        shouldSendRealtime: false,
        message: '미세먼지 데이터를 불러올 수 없어요.',
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
      maskRequired: maskRequired,
      maskType: _maskType(riskLevel),
    );
  }

  static String? _maskType(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.warning: return 'KF80';
      case RiskLevel.danger:  return 'KF94';
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
        // 보통 이상이면 한 단계 강화
        if (grade.index >= DustGrade.normal.index) {
          return _upgradeGrade(grade);
        }
        return grade;
      case Severity.moderate:
      case Severity.severe:
        // 항상 한 단계 강화
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

  static String _buildMessage(
      RiskLevel risk, int pm25, UserProfile profile) {
    final conditionNote = profile.hasCondition
        ? '(${profile.conditionType.label} 보유자 기준) '
        : '';

    switch (risk) {
      case RiskLevel.low:
        return '${conditionNote}오늘 공기가 맑아요. 마음껏 외출하셔도 좋습니다.';
      case RiskLevel.normal:
        return '${conditionNote}보통 수준이에요. 장시간 야외 활동 시 마스크를 고려하세요.';
      case RiskLevel.warning:
        return '${conditionNote}미세먼지가 나빠요(PM2.5: $pm25). 외출 시 마스크를 착용하세요.';
      case RiskLevel.danger:
        return '${conditionNote}미세먼지가 매우 나빠요(PM2.5: $pm25). 외출을 자제하고, 반드시 마스크를 착용하세요.';
      case RiskLevel.critical:
        return '${conditionNote}미세먼지가 매우 심각해요(PM2.5: $pm25). 가급적 외출을 삼가세요.';
      case RiskLevel.unknown:
        return '미세먼지 정보를 불러올 수 없어요.';
    }
  }
}

class DustCalculationResult {
  final RiskLevel riskLevel;
  final bool shouldSendRealtime;
  final String message;
  final bool maskRequired;
  final String? maskType; // 'KF80' or 'KF94' or null

  const DustCalculationResult({
    required this.riskLevel,
    required this.shouldSendRealtime,
    required this.message,
    required this.maskRequired,
    this.maskType,
  });
}

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
