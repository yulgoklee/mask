import '../../core/engine/threshold_config.dart';
import '../../core/engine/threshold_engine.dart';
import '../../data/models/user_profile.dart';
import 'widgets/axis_list.dart';

/// 프로필·결과지 표시용 페르소나 데이터 헬퍼 (계획서 §3 PersonaData.fromProfile)
///
/// ThresholdEngine.breakdown()으로 5축 가중치를 계산하고
/// UI에서 바로 쓸 수 있는 형태로 가공한다.
class PersonaData {
  final String label;           // "호흡기 민감 그룹"
  final String labelDiscovery;  // "호흡기 민감 그룹이에요"
  final double tFinal;
  final double general;         // ThresholdConfig.defaults.tBase = 35.0
  final String name;            // 닉네임 (greeting용)
  final int? age;
  final List<AxisItem> axes;    // 5개 고정 순서
  final double sum;             // wTotal (배경 트리거용)

  const PersonaData({
    required this.label,
    required this.labelDiscovery,
    required this.tFinal,
    required this.general,
    required this.name,
    required this.age,
    required this.axes,
    required this.sum,
  });

  factory PersonaData.fromProfile(UserProfile profile) {
    const eng = ThresholdEngine();
    final bd = eng.breakdown(profile);

    final axesList = [
      AxisItem(
        key: 'respiratory',
        label: '호흡기 민감',
        sub: _respiratoryNote(profile),
        weight: bd.wRespiratory,
        delta: -ThresholdConfig.defaults.tBase * bd.wRespiratory,
        isActive: bd.wRespiratory > 0,
      ),
      AxisItem(
        key: 'cardiovascular',
        label: '심혈관',
        sub: _cardioNote(profile),
        weight: bd.wCardiovascular,
        delta: -ThresholdConfig.defaults.tBase * bd.wCardiovascular,
        isActive: bd.wCardiovascular > 0,
      ),
      AxisItem(
        key: 'smoking',
        label: '흡연',
        sub: _smokingNote(profile),
        weight: bd.wSmoking,
        delta: -ThresholdConfig.defaults.tBase * bd.wSmoking,
        isActive: bd.wSmoking > 0,
      ),
      AxisItem(
        key: 'age',
        label: '연령',
        sub: '${profile.age}세',
        weight: bd.wAge,
        delta: -ThresholdConfig.defaults.tBase * bd.wAge,
        isActive: bd.wAge > 0,
      ),
    ];

    return PersonaData(
      label: _resolveLabel(bd, profile, discovery: false),
      labelDiscovery: _resolveLabel(bd, profile, discovery: true),
      tFinal: profile.tFinal,
      general: ThresholdConfig.defaults.tBase,
      name: profile.nickname,
      age: profile.age,
      axes: axesList,
      sum: bd.wTotal,
    );
  }

  // ── 페르소나 라벨 도출 (계획서 §3 표) ───────────────────────

  static String _resolveLabel(
    ThresholdBreakdown bd,
    UserProfile profile, {
    required bool discovery,
  }) {
    if (bd.wRespiratory > 0 || profile.hasRespiratoryCondition) {
      return discovery ? '호흡기 민감 그룹이에요' : '호흡기 민감 그룹';
    }
    if (bd.wCardiovascular > 0) {
      return discovery ? '심혈관 주의 그룹이에요' : '심혈관 주의 그룹';
    }
    if (bd.wSmoking > 0) {
      return discovery ? '흡연 이력이 있는 그룹이에요' : '흡연 이력 그룹';
    }
    if (bd.wAge > 0) {
      return discovery ? '연령 민감 그룹이에요' : '연령 민감 그룹';
    }
    return discovery ? '일반 그룹이에요' : '일반 그룹';
  }

  // ── 축별 sub 노트 ───────────────────────────────────────────

  static String? _respiratoryNote(UserProfile p) {
    final parts = <String>[];
    if (p.asthma) parts.add('천식');
    if (p.rhinitis) parts.add('비염');
    if (p.copd) parts.add('COPD');
    if (p.allergy) parts.add('알레르기');
    return parts.isEmpty ? null : parts.join('·');
  }

  static String? _cardioNote(UserProfile p) {
    final parts = <String>[];
    if (p.hypertension) parts.add('고혈압');
    if (p.heartDisease) parts.add('심장 질환');
    if (p.stroke) parts.add('뇌졸중');
    return parts.isEmpty ? null : parts.join('·');
  }

  static String? _smokingNote(UserProfile p) {
    switch (p.smokingStatus) {
      case SmokingStatus.current:
        return '현재 흡연 중';
      case SmokingStatus.former:
        return '과거 흡연';
      case SmokingStatus.never:
        return null;
    }
  }
}
