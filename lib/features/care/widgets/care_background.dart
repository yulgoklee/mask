import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 케어 탭 위험도별 배경 그라디언트
///
/// final_ratio 3분기:
///  - safe    : 연한 청회색·민트 → 흰색
///  - caution : 노란빛 → 흰색
///  - danger  : 살구·산호 → 흰색
///
/// 시안 v3 채택 (2026-05-09). Apple Weather식 — 카드 X, 배경이 컨텍스트 전달.
/// 색 전환 부드럽게 (300ms).
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

  /// 위험도별 그라디언트 색 (위 → 아래)
  /// 시안 v3 의도 — 위험도가 한눈에 보이도록 진하게
  Color get _topColor {
    switch (level) {
      case CareRiskLevel.safe:    return const Color(0xFFB7F0CB); // 명확한 민트
      case CareRiskLevel.caution: return const Color(0xFFFCD980); // 명확한 노랑
      case CareRiskLevel.danger:  return const Color(0xFFFFA8A8); // 명확한 살구
    }
  }

  Color get _midColor {
    switch (level) {
      case CareRiskLevel.safe:    return DT.safeBg;       // #F0FDF4
      case CareRiskLevel.caution: return DT.cautionBg;    // #FFFBEB
      case CareRiskLevel.danger:  return DT.dangerBg;     // #FFF1F2
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
          colors: [
            _topColor,
            _midColor,
            DT.background,
          ],
          stops: const [0.0, 0.35, 0.85],
        ),
      ),
      child: child,
    );
  }
}
