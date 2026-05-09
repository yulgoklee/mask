import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import 'care_background.dart';

/// 내 기준 위치 미터
///
/// final_ratio가 개인 임계치 대비 어디 있는지 시각으로 표시.
/// 수치 노출 X (yulgok 정책 — 알고리즘 수치는 표면 X, 펼침에만).
/// 시각 위치 + 점 + 임계치 마크.
class ThresholdMeter extends StatelessWidget {
  /// 0.0 ~ 1.5 정도 (1.0 = 임계치 = 위험 진입점)
  final double ratio;
  final CareRiskLevel level;

  const ThresholdMeter({
    super.key,
    required this.ratio,
    required this.level,
  });

  Color get _dotColor {
    switch (level) {
      case CareRiskLevel.safe:    return DT.safe;
      case CareRiskLevel.caution: return DT.caution;
      case CareRiskLevel.danger:  return DT.danger;
    }
  }

  /// 시각 위치 라벨 (수치 X)
  String get _label {
    switch (level) {
      case CareRiskLevel.safe:    return '내 기준에서 안전';
      case CareRiskLevel.caution: return '내 기준에서 주의 구간';
      case CareRiskLevel.danger:  return '내 기준에서 위험 구간';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시각화용 clamp (0.0 ~ 1.3)
    final visualRatio = ratio.clamp(0.0, 1.3);
    // 트랙 길이 대비 점 위치 (1.0 임계치를 75% 지점으로)
    final dotPosition = (visualRatio / 1.3).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 라벨 ─────────────────────────────────────────
        Text(
          _label,
          style: const TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      DT.gray,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 12),

        // ── 미터 트랙 ────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // 임계치 (1.0) 위치 = 트랙의 약 77% 지점 (1.0/1.3)
            const thresholdAt = 1.0 / 1.3;

            return SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 트랙 (얇은 라인)
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: DT.gray.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // 임계치 마크 (점선 세로)
                  Positioned(
                    left: width * thresholdAt - 0.5,
                    top: 0,
                    bottom: 0,
                    child: CustomPaint(
                      size: const Size(1, 24),
                      painter: _DashedLinePainter(
                        color: DT.gray.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // 현재 위치 점
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    left: (width * dotPosition - 7).clamp(0.0, width - 14),
                    child: Container(
                      width:  14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _dotColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
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
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
