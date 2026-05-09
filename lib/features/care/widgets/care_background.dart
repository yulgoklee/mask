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

  /// 시안 그라디언트 — 3-stop, 위 30%까지 진한 톤 유지 + 70% 페이드 영역.
  ///
  /// 위 30%는 topColor 그대로, 0.30~1.0 구간에서 `#F9FAFB`로 점진 페이드.
  /// 페이드 영역이 70%라 위→아래 변화가 명확히 보이고, 끝까지 색이 살아있음.
  List<Color> get _colors {
    switch (level) {
      case CareRiskLevel.safe:
        return const [
          Color(0xFFE0F0E8),
          Color(0xFFE0F0E8),
          Color(0xFFF9FAFB),
        ];
      case CareRiskLevel.caution:
        return const [
          Color(0xFFFDEDC4),
          Color(0xFFFDEDC4),
          Color(0xFFF9FAFB),
        ];
      case CareRiskLevel.danger:
        return const [
          Color(0xFFF9D8C8),
          Color(0xFFF9D8C8),
          Color(0xFFF9FAFB),
        ];
    }
  }

  List<double> get _stops => const [0.0, 0.3, 1.0];

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
