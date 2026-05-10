import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/korean_hero_text.dart';

/// 온보딩 공통 Hero 위젯
///
/// 구조 (CareHero·ProfileHero와 동일한 패턴):
///   cap (있을 때): 작은 상단 레이블 — 14pt w500 gray
///   main: \n 포함 대형 Hero 텍스트 — [heroSize]pt w700 DT.text
///   sub (있을 때): 보조 문구 — 16pt w500 gray (별도 Text, line-height 지원)
///
/// key: `ValueKey('onboarding-hero-$main')` 로 animate 트리거.
class OnboardingHero extends StatelessWidget {
  /// 상단 작은 레이블 (예: "지수만을 위한") — null이면 숨김
  final String? cap;

  /// Hero 주 텍스트 (\n 포함 가능)
  final String main;

  /// 보조 문구 — null이면 숨김
  final String? sub;

  /// Hero 폰트 크기 (splash 64 / disclaimer 48 / welcome P1 56 / P2·P3 40 / analysis 48 / complete 64)
  final double heroSize;

  const OnboardingHero({
    super.key,
    this.cap,
    required this.main,
    this.sub,
    this.heroSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cap ──────────────────────────────────────────────
        if (cap != null && cap!.isNotEmpty) ...[
          Text(
            cap!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DT.gray,
              letterSpacing: -0.14,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // ── Hero ─────────────────────────────────────────────
        KoreanHeroText(
          text: main,
          style: TextStyle(
            fontSize: heroSize,
            fontWeight: FontWeight.w700,
            color: DT.text,
            height: 1.08,
            letterSpacing: -heroSize * 0.035,
          ),
        ).animate(key: ValueKey('onboarding-hero-$main'))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut),

        // ── Sub ───────────────────────────────────────────────
        if (sub != null && sub!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            sub!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: DT.gray,
              letterSpacing: -0.16,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}
