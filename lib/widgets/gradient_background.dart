import 'package:flutter/material.dart';

/// 공통 그라디언트 배경 — 케어/프로필/온보딩 3종 통합 베이스.
///
/// 패턴: SizedBox.expand → [Animated]Container → BoxDecoration(LinearGradient)
/// stops 기본값 [0.0, 0.3, 1.0] (시안 기준 6-stop 그라디언트의 실제 3-stop 정의)
///
/// - `colors`: 그라디언트 색상 리스트 (3개 권장: top, mid, bottom)
/// - `stops`: 색상 위치 (기본 `[0.0, 0.3, 1.0]`)
/// - `animated`: true면 AnimatedContainer로 색 변경 시 트랜지션
/// - `duration`: animated일 때 트랜지션 시간 (기본 400ms)
class GradientBackground extends StatelessWidget {
  final List<Color> colors;
  final List<double> stops;
  final bool animated;
  final Duration duration;
  final Widget child;

  const GradientBackground({
    super.key,
    required this.colors,
    this.stops = const [0.0, 0.3, 1.0],
    this.animated = true,
    this.duration = const Duration(milliseconds: 400),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ),
    );

    return SizedBox.expand(
      child: animated
          ? AnimatedContainer(
              duration: duration,
              curve: Curves.easeInOut,
              decoration: decoration,
              child: child,
            )
          : DecoratedBox(
              decoration: decoration,
              child: child,
            ),
    );
  }
}
