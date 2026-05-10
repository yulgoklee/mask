import 'package:flutter/material.dart';

/// 온보딩 공통 배경 그라디언트 (brand 파랑 고정)
///
/// 케어 배경(CareBackground)의 safe 3-stop 정적 버전.
/// stops: [0.0, 0.3, 1.0]
/// colors: [#E8F0FE, #E8F0FE, #F9FAFB]
class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  static const List<Color> _colors = [
    Color(0xFFE8F0FE),
    Color(0xFFE8F0FE),
    Color(0xFFF9FAFB),
  ];

  static const List<double> _stops = [0.0, 0.3, 1.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _colors,
            stops: _stops,
          ),
        ),
        child: child,
      ),
    );
  }
}
