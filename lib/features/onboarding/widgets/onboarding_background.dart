import 'package:flutter/material.dart';

/// 온보딩 공통 배경 그라디언트 (safe 고정)
///
/// 케어 배경(CareBackground)의 safe 3-stop 정적 버전.
/// stops: [0.0, 0.3, 1.0]
/// colors: [#E0F0E8, #E0F0E8, #F9FAFB]
class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  static const List<Color> _colors = [
    Color(0xFFE0F0E8),
    Color(0xFFE0F0E8),
    Color(0xFFF9FAFB),
  ];

  static const List<double> _stops = [0.0, 0.3, 1.0];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
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
