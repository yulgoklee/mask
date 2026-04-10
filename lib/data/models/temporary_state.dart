import '../../core/constants/dust_standards.dart';

/// Tier 2 — 기간 상태 (시작일 + 만료일, 자동 만료)
///
/// 임신, 피부 시술 후, 항암 치료 중처럼 일정 기간 동안
/// 마스크 기준이 달라지는 상태를 관리한다.
class TemporaryState {
  final TemporaryStateType type;
  final DateTime startDate;

  /// null 이면 사용자가 수동으로 해제할 때까지 유지
  final DateTime? expiryDate;

  const TemporaryState({
    required this.type,
    required this.startDate,
    this.expiryDate,
  });

  // ── 활성 여부 ────────────────────────────────────────────

  bool get isActive {
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  // ── 마스크 판단 기준 ──────────────────────────────────────

  /// true 이면 PM2.5 등급에 관계없이 항상 마스크 필요
  bool get alwaysMask => type == TemporaryStateType.skinProcedureRecovery;

  /// 이 등급 이상이면 마스크 필요 (alwaysMask=true인 경우 무시됨)
  DustGrade get maskThresholdGrade {
    switch (type) {
      case TemporaryStateType.immunoSuppressed:
        // 좋음(15 이하)에서도 마스크 — good 등급부터 트리거
        return DustGrade.good;
      case TemporaryStateType.pregnancy:
      case TemporaryStateType.withInfant:
      case TemporaryStateType.pollenAllergySeason:
        return DustGrade.normal; // 보통(16+)부터
      case TemporaryStateType.skinProcedureRecovery:
        return DustGrade.good; // alwaysMask=true 이므로 실질적으로 무조건
    }
  }

  String get maskType {
    switch (type) {
      case TemporaryStateType.pregnancy:
      case TemporaryStateType.withInfant:
      case TemporaryStateType.immunoSuppressed:
        return 'KF94';
      case TemporaryStateType.pollenAllergySeason:
      case TemporaryStateType.skinProcedureRecovery:
        return 'KF80';
    }
  }

  String get label => type.label;

  // ── 직렬화 ───────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'startDate': startDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
      };

  factory TemporaryState.fromJson(Map<String, dynamic> json) => TemporaryState(
        type: TemporaryStateType.values[json['type'] as int],
        startDate: DateTime.parse(json['startDate'] as String),
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'] as String)
            : null,
      );

  TemporaryState copyWith({
    TemporaryStateType? type,
    DateTime? startDate,
    Object? expiryDate = _sentinel,
  }) =>
      TemporaryState(
        type: type ?? this.type,
        startDate: startDate ?? this.startDate,
        expiryDate:
            expiryDate == _sentinel ? this.expiryDate : expiryDate as DateTime?,
      );
}

const _sentinel = Object();

// ── 기간 상태 종류 ─────────────────────────────────────────

enum TemporaryStateType {
  pregnancy,
  withInfant,
  pollenAllergySeason,
  skinProcedureRecovery,
  immunoSuppressed;

  String get label {
    switch (this) {
      case TemporaryStateType.pregnancy:
        return '임신 중';
      case TemporaryStateType.withInfant:
        return '영유아 동반';
      case TemporaryStateType.pollenAllergySeason:
        return '꽃가루 알레르기 시즌';
      case TemporaryStateType.skinProcedureRecovery:
        return '피부 시술 후 회복';
      case TemporaryStateType.immunoSuppressed:
        return '면역저하 / 항암 치료';
    }
  }

  String get description {
    switch (this) {
      case TemporaryStateType.pregnancy:
        return '태반 통과 위험 — 보통(16+) 이상 KF94';
      case TemporaryStateType.withInfant:
        return '소아 폐 발달 영향 — 보통(16+) 이상 KF94';
      case TemporaryStateType.pollenAllergySeason:
        return '복합 노출 효과 — 보통(16+) 이상 KF80';
      case TemporaryStateType.skinProcedureRecovery:
        return '미립자·오염물질 상처 자극 — 등급 무관 KF80';
      case TemporaryStateType.immunoSuppressed:
        return '감염 위험 극도 증가 — 좋음(15+)부터 KF94';
    }
  }
}
