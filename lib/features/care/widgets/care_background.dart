import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 케어 탭 위험도별 배경 그라디언트 (시안 v3 정확)
///
/// 6-stop, 매우 옅은 톤 (위→아래 자연 페이드).
/// 내부적으로 `#F9FAFB` 으로 부드럽게 수렴.
enum CareRiskLevel {
  safe,    // ratio < 0.7
  caution, // 0.7 <= ratio < 1.0
  danger,  // ratio >= 1.0
}

class CareBackground extends StatelessWidget {
  final CareRiskLevel level;
  final Widget child;

  const CareBackground({
    super.key,
    required this.level,
    required this.child,
  });

  /// final_ratio → CareRiskLevel
  static CareRiskLevel levelFromRatio(double? ratio) {
    if (ratio == null) return CareRiskLevel.safe;
    if (ratio >= 1.0) return CareRiskLevel.danger;
    if (ratio >= 0.7) return CareRiskLevel.caution;
    return CareRiskLevel.safe;
  }

  /// 시안 v3 정확한 6-stop 그라디언트
  List<Color> get _colors {
    switch (level) {
      case CareRiskLevel.safe:
        return const [
          Color(0xFFE6F4EE),
          Color(0xFFEEF7F2),
          Color(0xFFF4FAF6),
          Color(0xFFF8FBF9),
          Color(0xFFFAFBFA),
          Color(0xFFF9FAFB),
        ];
      case CareRiskLevel.caution:
        return const [
          Color(0xFFFEF3D6),
          Color(0xFFFEF6E1),
          Color(0xFFFDF8EA),
          Color(0xFFFBFAF1),
          Color(0xFFFAFAF6),
          Color(0xFFF9FAFB),
        ];
      case CareRiskLevel.danger:
        return const [
          Color(0xFFFBE3DA),
          Color(0xFFFBE7DF),
          Color(0xFFFBEDE6),
          Color(0xFFFAF1EC),
          Color(0xFFFAF6F2),
          Color(0xFFF9FAFB),
        ];
    }
  }

  List<double> get _stops {
    switch (level) {
      case CareRiskLevel.safe:    return const [0.0, 0.28, 0.52, 0.72, 0.88, 1.0];
      case CareRiskLevel.caution: return const [0.0, 0.26, 0.48, 0.70, 0.86, 1.0];
      case CareRiskLevel.danger:  return const [0.0, 0.22, 0.44, 0.64, 0.84, 1.0];
    }
  }

  /// 위험도 베이스 색 (다른 위젯에서 참조)
  static Color baseColor(CareRiskLevel level) {
    switch (level) {
      case CareRiskLevel.safe:    return DT.safe;
      case CareRiskLevel.caution: return DT.caution;
      case CareRiskLevel.danger:  return DT.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _colors,
          stops: _stops,
        ),
      ),
      child: child,
    );
  }
}
