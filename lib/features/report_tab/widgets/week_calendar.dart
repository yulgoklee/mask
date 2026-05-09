import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/report_models.dart';

/// 주간 캘린더 (7개 정사각형 셀 + 요일 라벨)
///
/// 폭 82% 처리는 위젯 내부에서 FractionallySizedBox로 처리.
class WeekCalendar extends StatelessWidget {
  final List<DayCalendarData> days;
  final double gap;

  const WeekCalendar({
    super.key,
    required this.days,
    this.gap = 6,
  });

  /// final_ratio → 캘린더 셀 색상 (6-stop 팔레트)
  static Color ratioToCalColor(double ratio) {
    if (ratio < 0.30) return const Color(0xFFDDEDE3);
    if (ratio < 0.60) return const Color(0xFFE9F2DE);
    if (ratio < 0.85) return const Color(0xFFFBEFCD);
    if (ratio < 1.00) return const Color(0xFFF8E1B5);
    if (ratio < 1.30) return const Color(0xFFF5C9AE);
    return const Color(0xFFEFAE94);
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.82,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 셀 행
          Row(
            children: days.map((d) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: d.hasData && d.peakRatio != null
                      ? _FilledCell(ratio: d.peakRatio!)
                      : const _EmptyCell(),
                ),
              ),
            )).toList(),
          ),
          SizedBox(height: gap + 4),
          // 요일 라벨 행
          Row(
            children: days.map((d) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
                child: Text(
                  d.weekdayLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                    color:      DT.gray,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _FilledCell extends StatelessWidget {
  final double ratio;

  const _FilledCell({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WeekCalendar.ratioToCalColor(ratio),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DT.text.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
    );
  }
}

/// dashed border CustomPainter (데이터 없는 셀)
class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const radius = 12.0;
    const dashLen = 4.0;
    const gapLen  = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    _drawDashedPath(canvas, path, paint, dashLen, gapLen);
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, double dashLen, double gapLen) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLen : gapLen;
        if (draw) {
          final extractedPath = metric.extractPath(distance, distance + len);
          canvas.drawPath(extractedPath, paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) => false;
}
