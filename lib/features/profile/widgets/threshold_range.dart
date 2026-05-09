import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 단일 트랙 + 두 마커 임계치 범위 위젯 (시안 profile-components PThresholdRange variant B)
///
/// 구조 (Stack 56h):
///   트랙 4h, radius 2, rgba(17,24,39, 0.10)
///   강조 영역 (myThreshold ~ general): accentColor with alpha 0.5
///   일반 마커: 12px circle, white fill + 1.5px border DT.gray2
///   내 기준 마커: 16px circle, accentColor fill + boxShadow white 0.85 spreadRadius 4
///   라벨 (마커 위 28pt 위치): "나 N" 12pt w700 accent / "일반 35" 11pt w500 DT.gray2
///   양 끝 라벨: "0" / "100㎍/㎥" 11pt w500 DT.gray2
///   캡션: 13pt w500 DT.gray
class ThresholdRange extends StatelessWidget {
  final double myThreshold;
  final double general;
  final Color accentColor;
  final int max;

  const ThresholdRange({
    super.key,
    required this.myThreshold,
    required this.general,
    required this.accentColor,
    this.max = 100,
  });

  /// 퍼센트 동적 계산 (J-1)
  /// ((general - my) / general * 100).round()
  int get _pct => ((general - myThreshold) / general * 100).round();

  @override
  Widget build(BuildContext context) {
    final myFrac = myThreshold / max;
    final genFrac = general / max;
    final pct = _pct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 트랙 영역 (LayoutBuilder로 픽셀 정렬) ────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final trackW = constraints.maxWidth;
            final myX = trackW * myFrac;
            final genX = trackW * genFrac;

            // 트랙 세로 중심 offset (총 56h 중 트랙 = 상단 38px 위치)
            const trackTop = 36.0;
            const trackH = 4.0;
            const myMarkerR = 8.0;  // 16px diameter / 2
            const genMarkerR = 6.0; // 12px diameter / 2

            return SizedBox(
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── 라벨 (마커 위) ──────────────────────────
                  // "나 N" — 내 기준 마커 중심 위
                  Positioned(
                    top: 0,
                    left: myX - 24,
                    child: SizedBox(
                      width: 48,
                      child: Text(
                        '나 ${myThreshold.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: -0.06,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  // "일반 35" — 일반 마커 중심 위
                  Positioned(
                    top: 0,
                    left: genX - 24,
                    child: SizedBox(
                      width: 48,
                      child: Text(
                        '일반 ${general.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: DT.gray2,
                          letterSpacing: -0.055,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),

                  // ── 트랙 베이스 ──────────────────────────────
                  Positioned(
                    top: trackTop,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: trackH,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── 강조 영역 (myThreshold ~ general) ────────
                  Positioned(
                    top: trackTop,
                    left: myX,
                    width: genX - myX,
                    child: Container(
                      height: trackH,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── 일반 마커 (12px circle) ──────────────────
                  Positioned(
                    top: trackTop + trackH / 2 - genMarkerR,
                    left: genX - genMarkerR,
                    child: Container(
                      width: genMarkerR * 2,
                      height: genMarkerR * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: DT.gray2,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // ── 내 기준 마커 (16px circle, 강조) ─────────
                  Positioned(
                    top: trackTop + trackH / 2 - myMarkerR,
                    left: myX - myMarkerR,
                    child: Container(
                      width: myMarkerR * 2,
                      height: myMarkerR * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.85),
                            spreadRadius: 4,
                            blurRadius: 0,
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

        // ── 양 끝 라벨 ───────────────────────────────────────
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: DT.gray2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              '$max㎍/㎥',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: DT.gray2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),

        // ── 캡션 ─────────────────────────────────────────────
        const SizedBox(height: 10),
        Text(
          pct > 0
              ? '일반 기준보다 $pct% 낮아요'
              : '일반 기준과 비슷해요',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: DT.gray,
            letterSpacing: -0.065,
          ),
        ),
      ],
    );
  }
}
