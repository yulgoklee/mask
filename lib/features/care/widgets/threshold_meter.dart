import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import 'care_background.dart';

/// 내 기준 위치 미터 (시안 v3 정확)
///
/// 라벨 ("내 기준에서 어느 정도인지") + 트랙 + 채워진 라인 +
/// 임계치 눈금 + "내 기준 N" 라벨 + 현재 위치 점 + 양 끝 라벨.
class ThresholdMeter extends StatelessWidget {
  final double pm25;
  final double threshold; // 개인 임계치
  final CareRiskLevel level;

  const ThresholdMeter({
    super.key,
    required this.pm25,
    required this.threshold,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final base = CareBackground.baseColor(level);
    final max = (threshold * 2).clamp(threshold * 1.2, double.infinity).toDouble();
    final maxClamped = (pm25 * 1.2 > max) ? pm25 * 1.2 : max;

    final pos    = (pm25 / maxClamped).clamp(0.0, 1.0);
    final tPos   = (threshold / maxClamped).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 라벨 ─────────────────────────────────────────
        const Text(
          '내 기준에서 어느 정도인지',
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      DT.gray,
          ),
        ),
        const SizedBox(height: 10),

        // ── 미터 본체 (높이 36) ──────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 36,
              child: Stack(
                children: [
                  // 트랙 (얇은 라인, hairline)
                  Positioned(
                    top: 18,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: DT.text.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                  // 채워진 라인 (현재 위치까지) opacity 55%
                  Positioned(
                    top: 18,
                    left: 0,
                    width: (width * pos).clamp(0.0, width),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                  // 임계치 눈금 (1px 세로 라인, 14px height)
                  Positioned(
                    top: 12,
                    left: width * tPos - 0.5,
                    child: Container(
                      width: 1,
                      height: 14,
                      color: DT.text.withValues(alpha: 0.45),
                    ),
                  ),

                  // 임계치 라벨 ("내 기준 21")
                  Positioned(
                    top: 0,
                    left: (width * tPos - 30).clamp(0.0, width - 60),
                    width: 60,
                    child: Text(
                      '내 기준 ${threshold.round()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize:      11,
                        fontWeight:    FontWeight.w600,
                        color:         DT.text,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ),

                  // 현재 위치 점 (14px, white shadow 4px)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve:    Curves.easeOutCubic,
                    top: 12,
                    left: (width * pos - 7).clamp(0.0, width - 14),
                    child: Container(
                      width:  14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: base,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.85),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 4),

        // ── 양 끝 라벨 (0 / max ㎍/㎥) ────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '0',
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      DT.gray,
              ),
            ),
            Text(
              '${maxClamped.round()}㎍/㎥',
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      DT.gray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
