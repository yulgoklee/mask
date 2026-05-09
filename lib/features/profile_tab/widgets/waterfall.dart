import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../profile/widgets/axis_list.dart';

/// 임계치 산정 흐름 Waterfall (시안 profile-screens PWaterfall variant A)
///
/// 구조:
///   _StepNode('일반 기준', sub: '환경공단', value: 35)
///   각 active axis → _ConnArrow + _DeltaRow(label, note, delta)
///   _StepNode('내 기준', value: tFinal, big: true, color: accent)
///
/// D-2 확정: _ConnArrow = CustomPainter 점선(dash [2,3]) + 화살표 머리
/// D-1 확정: _DeltaRow 좌측 인덴트 실선 1dp, DT.text alpha 0.18
class Waterfall extends StatelessWidget {
  final double general;       // 35.0
  final double tFinal;
  final List<AxisItem> axes;  // 내부에서 isActive 필터
  final Color accent;

  const Waterfall({
    super.key,
    required this.general,
    required this.tFinal,
    required this.axes,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final reductions = axes.where((a) => a.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 시작 노드: 일반 기준 ─────────────────────────────
        _StepNode(
          label: '일반 기준',
          sub: '환경공단',
          value: general.toStringAsFixed(0),
          big: false,
        ),

        // ── 각 가중치 축 ─────────────────────────────────────
        ...reductions.map((r) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ConnArrow(),
                _DeltaRow(
                  label: r.label,
                  note: r.sub,
                  delta: r.delta,
                  weight: r.weight,
                ),
              ],
            )),

        // ── 연결 화살표 + 최종 노드 ─────────────────────────
        const _ConnArrow(),
        _StepNode(
          label: '내 기준',
          value: tFinal.toStringAsFixed(0),
          big: true,
          labelColor: accent,
        ),
      ],
    );
  }
}

// ── 단계 노드 (일반 기준 / 내 기준) ──────────────────────────────

class _StepNode extends StatelessWidget {
  final String label;
  final String? sub;
  final String value;
  final bool big;
  final Color? labelColor;

  const _StepNode({
    required this.label,
    this.sub,
    required this.value,
    this.big = false,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // 좌: 라벨 + 부제
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: big ? 15 : 14,
                  fontWeight: big ? FontWeight.w700 : FontWeight.w600,
                  color: labelColor ?? DT.text,
                  letterSpacing: -0.14,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(width: 8),
                Text(
                  sub!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DT.gray2,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
        // 우: 수치 + 단위
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: big ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: DT.text,
                letterSpacing: big ? -0.44 : -0.36,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '㎍/㎥',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: DT.gray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 점선 연결 화살표 (D-2: CustomPainter dash [2,3] + 화살표 머리) ──

class _ConnArrow extends StatelessWidget {
  const _ConnArrow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CustomPaint(
            size: const Size(12, 28),
            painter: _DashedArrowPainter(),
          ),
        ),
      ),
    );
  }
}

class _DashedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const strokeColor = Color(0xFF111827); // DT.text 동일값
    final linePaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.50)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;

    // 점선 상단(0) → 화살표 시작 바로 위(size.height - 6)
    _drawDashedPath(
      canvas,
      linePaint,
      Offset(cx, 0),
      Offset(cx, size.height - 6),
      dashOn: 2,
      dashOff: 3,
    );

    // 화살표 머리 (시안: M-10,20 L-6,26 L-2,20 → 상대 좌표 → size 기준)
    // cx 기준: 좌 -4px, 중 0px, 우 +4px
    final arrowPath = Path()
      ..moveTo(cx - 4, size.height - 8)
      ..lineTo(cx, size.height)
      ..lineTo(cx + 4, size.height - 8);
    canvas.drawPath(arrowPath, arrowPaint);
  }

  /// 점선 그리기 헬퍼 (dashOn/dashOff px 단위)
  void _drawDashedPath(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end, {
    required double dashOn,
    required double dashOff,
  }) {
    final total = (end - start).distance;
    final dir = (end - start) / total;
    double drawn = 0;
    bool drawing = true;

    while (drawn < total) {
      final segLen = drawing ? dashOn : dashOff;
      final segEnd = drawn + segLen;
      if (drawing) {
        canvas.drawLine(
          start + dir * drawn,
          start + dir * segEnd.clamp(0, total),
          paint,
        );
      }
      drawn = segEnd;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── DeltaRow (가중치 축 감소분) ──────────────────────────────────

class _DeltaRow extends StatelessWidget {
  final String label;
  final String? note;
  final double delta;
  final double weight;

  const _DeltaRow({
    required this.label,
    this.note,
    required this.delta,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    // D-1: 좌측 인덴트 16dp + 실선 1dp DT.text alpha 0.18
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 1,
            margin: const EdgeInsets.only(left: 6),
            color: DT.text.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // 좌: 라벨 + note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '− $label',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DT.text,
                            letterSpacing: -0.065,
                          ),
                        ),
                        if (note != null && note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$note · 가중치 ${weight.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: DT.gray2,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            '가중치 ${weight.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: DT.gray2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 우: delta 수치
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        delta.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DT.text,
                          letterSpacing: -0.16,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '㎍/㎥',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: DT.gray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
