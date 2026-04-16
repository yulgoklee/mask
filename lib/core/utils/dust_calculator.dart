import '../../data/models/dust_data.dart';
import '../../data/models/user_profile.dart';

/// 개인 프로필 기반 위험도 계산 및 알림 판단 (v2)
///
/// T_final(개인 임계값)을 기준으로 PM2.5 수치를 직접 비교합니다.
/// 이전 버전의 DustGrade 업/다운 방식을 대체합니다.
class DustCalculator {
  static DustCalculationResult calculate(UserProfile profile, DustData dust) {
    final pm25 = dust.pm25Value;
    if (pm25 == null) {
      return DustCalculationResult(
        riskLevel: RiskLevel.unknown,
        shouldSendRealtime: false,
        message: '미세먼지 데이터를 불러올 수 없어요.',
        maskRequired: false,
        tFinal: profile.tFinal,
      );
    }

    final t = profile.tFinal;
    final ratio = pm25 / t; // 임계값 대비 비율

    // ── 위험도 결정 ──────────────────────────────────────────
    // ratio < 0.5        → 안전 (low)
    // 0.5 ≤ ratio < 1.0  → 보통 (normal)
    // 1.0 ≤ ratio < 1.5  → 주의 (warning)
    // 1.5 ≤ ratio < 2.0  → 나쁨 (danger)
    // ratio ≥ 2.0        → 매우나쁨 (critical)
    final RiskLevel riskLevel;
    if (ratio < 0.5) {
      riskLevel = RiskLevel.low;
    } else if (ratio < 1.0) {
      riskLevel = RiskLevel.normal;
    } else if (ratio < 1.5) {
      riskLevel = RiskLevel.warning;
    } else if (ratio < 2.0) {
      riskLevel = RiskLevel.danger;
    } else {
      riskLevel = RiskLevel.critical;
    }

    final maskRequired = riskLevel == RiskLevel.warning ||
        riskLevel == RiskLevel.danger ||
        riskLevel == RiskLevel.critical;

    // 임계값 2배 초과 시 실시간 경보
    final shouldSendRealtime = ratio >= 2.0;

    return DustCalculationResult(
      riskLevel: riskLevel,
      shouldSendRealtime: shouldSendRealtime,
      message: _buildMessage(riskLevel, pm25, t, profile),
      maskRequired: maskRequired,
      maskType: _maskType(riskLevel),
      tFinal: t,
    );
  }

  static String? _maskType(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.warning:  return 'KF80';
      case RiskLevel.danger:   return 'KF94';
      case RiskLevel.critical: return 'KF94';
      default: return null;
    }
  }

  /// 개인화 알림 메시지 생성
  static String _buildMessage(
      RiskLevel risk, int pm25, double tFinal, UserProfile profile) {
    final name = profile.displayName;

    // 상황별 접두 멘트 (activityTags 활용)
    final String contextPrefix = _contextPrefix(profile);

    // 특수 상황 근거 문구
    final String specialNote = _specialNote(profile);

    switch (risk) {
      case RiskLevel.low:
        return '$contextPrefix$name, 오늘 공기가 맑아요. '
            '마음껏 외출하셔도 좋아요. (PM2.5 ${pm25}μg/m³)';
      case RiskLevel.normal:
        return '$contextPrefix$name, 보통 수준이에요. '
            '장시간 야외 활동 시 마스크를 고려해 보세요.';
      case RiskLevel.warning:
        return '$contextPrefix$name, KF80 마스크를 챙겨주세요. '
            'PM2.5 ${pm25}μg/m³으로 기준선(${tFinal.toStringAsFixed(0)}μg/m³)을 넘었어요.$specialNote';
      case RiskLevel.danger:
        return '$contextPrefix$name, KF94 마스크가 필요해요. '
            'PM2.5 ${pm25}μg/m³으로 기준선의 1.5배예요.$specialNote';
      case RiskLevel.critical:
        return '$contextPrefix$name, 오늘은 외출을 자제해 주세요. '
            'PM2.5 ${pm25}μg/m³으로 기준선의 2배를 넘었어요. '
            'KF94 마스크를 반드시 착용하세요.$specialNote';
      case RiskLevel.unknown:
        return '미세먼지 정보를 불러올 수 없어요.';
    }
  }

  /// activityTags 기반 상황별 접두 멘트
  static String _contextPrefix(UserProfile profile) {
    if (profile.activityTags.contains(ActivityTag.exercise)) {
      return '야외 운동을 즐기시는 ';
    }
    if (profile.activityTags.contains(ActivityTag.walk)) {
      return '산책을 좋아하시는 ';
    }
    if (profile.activityTags.contains(ActivityTag.commute)) {
      return '출퇴근하시는 ';
    }
    return '';
  }

  /// 임신/질환 등 특수 상황 근거 문구
  static String _specialNote(UserProfile profile) {
    if (profile.gender == 'female' && profile.isPregnant) {
      return '\n태아를 위해 반드시 마스크를 착용해 주세요.';
    }
    if (profile.respiratoryStatus >= 1) {
      return '\n호흡기가 예민하신 분은 특히 주의가 필요해요.';
    }
    return '';
  }
}

// ── 결과 모델 ────────────────────────────────────────────

class DustCalculationResult {
  final RiskLevel riskLevel;
  final bool shouldSendRealtime;
  final String message;
  final bool maskRequired;
  final String? maskType;  // 'KF80', 'KF94', or null
  final double tFinal;     // 이번 계산에 사용된 개인 임계값

  const DustCalculationResult({
    required this.riskLevel,
    required this.shouldSendRealtime,
    required this.message,
    required this.maskRequired,
    required this.tFinal,
    this.maskType,
  });
}

// ── 위험 등급 ────────────────────────────────────────────

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

  String get emoji {
    switch (this) {
      case RiskLevel.unknown:  return '❓';
      case RiskLevel.low:      return '😊';
      case RiskLevel.normal:   return '🙂';
      case RiskLevel.warning:  return '😷';
      case RiskLevel.danger:   return '⚠️';
      case RiskLevel.critical: return '🚨';
    }
  }
}
