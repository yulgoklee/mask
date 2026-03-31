import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/dust_standards.dart';

class DustGaugeWidget extends StatelessWidget {
  final int? value;
  final String label; // 'PM2.5' or 'PM10'
  final DustGrade grade;

  const DustGaugeWidget({
    super.key,
    required this.value,
    required this.label,
    required this.grade,
  });

  bool get _isPm25 => label == 'PM2.5';
  String get _koreanLabel => _isPm25 ? '초미세먼지' : '미세먼지';
  double get _max => _isPm25 ? 150.0 : 300.0;

  // 구간 경계값 (0~1 비율)
  List<double> get _thresholds => _isPm25
      ? [15 / 150, 35 / 150, 75 / 150, 1.0]
      : [30 / 300, 80 / 300, 150 / 300, 1.0];

  double get _progress => ((value ?? 0) / _max).clamp(0.0, 1.0);

  Color get _gradeColor {
    switch (grade) {
      case DustGrade.good:    return AppColors.dustGood;
      case DustGrade.normal:  return AppColors.dustNormal;
      case DustGrade.bad:     return AppColors.dustBad;
      case DustGrade.veryBad: return AppColors.dustVeryBad;
    }
  }

  static const _segmentColors = [
    AppColors.dustGood,
    AppColors.dustNormal,
    AppColors.dustBad,
    AppColors.dustVeryBad,
  ];
  static const _segmentLabels = ['좋음', '보통', '나쁨', '매우나쁨'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: _gradeColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gradeColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Text(_koreanLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _gradeColor)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _gradeColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(grade.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 반원 게이지
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = w / 2 + 10;
            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(w, h),
                    painter: _SemiCirclePainter(
                      progress: _progress,
                      thresholds: _thresholds,
                      segmentColors: _segmentColors,
                    ),
                  ),
                  // 수치: 원래 위치(bottom:14), 숫자-단위 간격만 0으로
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value != null ? '$value' : '-',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _gradeColor),
                        ),
                        Text('μg/m³',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color: _gradeColor.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 2),
          // 구간 라벨 (좋음 ~ 매우나쁨)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) => Expanded(
              child: Text(
                _segmentLabels[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : i == 3
                        ? TextAlign.right
                        : TextAlign.center,
                overflow: TextOverflow.visible,
                style: TextStyle(
                    fontSize: 9,
                    color: _segmentColors[i],
                    fontWeight: FontWeight.w600),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class _SemiCirclePainter extends CustomPainter {
  final double progress;        // 0.0 ~ 1.0
  final List<double> thresholds; // 4개 구간 경계 (비율)
  final List<Color> segmentColors;

  _SemiCirclePainter({
    required this.progress,
    required this.thresholds,
    required this.segmentColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height; // 중심: 하단 중앙
    final radius = size.width / 2 - 10;
    const sw = 14.0; // strokeWidth
    const gap = 0.04;

    // Flutter canvas: y축 아래 방향 → 시계방향이 양수
    // 반원: π(왼쪽)에서 시작해 시계방향(위로)으로 π 만큼 돌면 0(오른쪽)
    // startAngle = π + prevRatio * π, sweepAngle = +fraction * π

    // 배경 트랙
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi, pi, false,
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw + 2
        ..strokeCap = StrokeCap.butt,
    );

    // 세그먼트
    double prevRatio = 0.0;
    for (int i = 0; i < 4; i++) {
      final endRatio = thresholds[i];
      final startAngle = pi + prevRatio * pi + (i > 0 ? gap / 2 : 0);
      final sweepAngle = (endRatio - prevRatio) * pi - (i < 3 ? gap : 0);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle, sweepAngle, false,
        Paint()
          ..color = segmentColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
      prevRatio = endRatio;
    }

    // 바늘: progress 0 → 왼쪽(π+0=π), progress 1 → 오른쪽(π+π=2π=0)
    final needleAngle = pi + progress * pi;
    final needleLen = radius - sw / 2 - 2;
    final nx = cx + needleLen * cos(needleAngle);
    final ny = cy + needleLen * sin(needleAngle);

    canvas.drawLine(
      Offset(cx, cy), Offset(nx, ny),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(_SemiCirclePainter old) =>
      old.progress != progress;
}
