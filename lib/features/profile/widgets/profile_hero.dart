import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/korean_hero_text.dart';

/// 프로필·결과지 Hero 위젯 (시안 profile-components PHero variant B)
///
/// 구조:
///   greeting (있으면): "지수님,"  16pt w500 gray
///   [SizedBox(4) — greeting+cap 동시 사용 시]
///   cap     (있으면): "내 기준은" 11pt w600 gray letterSpacing 0.04em
///   숫자+단위: Row baseline — 64pt w700 + "㎍/㎥" 23pt w600 gray
///   sub: 16pt w500 gray, KoreanHeroText, marginTop 14
///
/// greeting+cap 동시 사용 가능 — 결과지에서 사용
class ProfileHero extends StatelessWidget {
  final double tFinal;
  final String sub;

  /// 결과지 전용 인사 "지수님," — null이면 숨김
  final String? greeting;

  /// 프로필 표면 캡션 "내 기준은" — null이면 숨김
  final String? cap;

  /// Hero 숫자 사이즈 (기본 64)
  final double heroSize;

  const ProfileHero({
    super.key,
    required this.tFinal,
    required this.sub,
    this.greeting,
    this.cap,
    this.heroSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    // 단위 폰트 크기 = heroSize × 0.36 ≈ 23pt (시안 variant B)
    final unitSize = (heroSize * 0.36).roundToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 인사 (결과지 전용) ────────────────────────────
        if (greeting != null && greeting!.isNotEmpty)
          Text(
            '$greeting,',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: DT.gray,
              letterSpacing: -0.16,
            ),
          ),

        // greeting + cap 동시 사용 시 간격
        if (greeting != null && greeting!.isNotEmpty &&
            cap != null && cap!.isNotEmpty)
          const SizedBox(height: 4),

        // ── Cap (프로필 표면 전용) ─────────────────────────
        if (cap != null && cap!.isNotEmpty)
          Text(
            cap!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DT.gray,
              letterSpacing: 0.44, // 0.04em × 11pt
            ),
          ),

        const SizedBox(height: 8),

        // ── 숫자 + 단위 (Baseline 정렬) ──────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              tFinal.toStringAsFixed(0),
              style: TextStyle(
                fontSize: heroSize,
                fontWeight: FontWeight.w700,
                color: DT.text,
                height: 1.0,
                letterSpacing: -heroSize * 0.035,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '㎍/㎥',
              style: TextStyle(
                fontSize: unitSize,
                fontWeight: FontWeight.w600,
                color: DT.gray,
                letterSpacing: -0.46, // -0.02em × 23pt
              ),
            ),
          ],
        ),

        // ── Sub (페르소나 라벨) ────────────────────────────
        const SizedBox(height: 14),
        KoreanHeroText(
          text: sub,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: DT.gray,
            letterSpacing: -0.16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
