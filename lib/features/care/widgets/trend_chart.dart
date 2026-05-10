import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';
import 'care_background.dart';

/// 12시간 흐름 라인 차트 (시안 v3 정확)
///
/// 카드 X. 배경에 녹임. hairline grid + 본문색 라인 + 임계치 점선.
/// 현재 시점 도트만 강조. 시간 라벨 5개 (6시·9시·12시·15시·18시).
class TrendChart extends ConsumerWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(protectionChartProvider);

    return chartAsync.when(
      data: (data) => _ChartBody(data: data),
      loading: () => _ChartBody(data: ProtectionChartData.placeholder()),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ChartBody extends ConsumerWidget {
  final ProtectionChartData data;
  const _ChartBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusCard = ref.watch(statusCardProvider);
    final level = CareBackground.levelFromRatio(statusCard.finalRatio);
    final base  = CareBackground.baseColor(level);
    final now   = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더: "오늘 12시간 흐름" + "지금 14시" ──────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              '오늘 12시간 흐름',
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      DT.gray,
              ),
            ),
            Text(
              '지금 ${now.hour}시',
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      DT.gray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── 차트 본체 ────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 120,
          child: CustomPaint(
            painter: _TrendChartPainter(
              points: data.chartPoints,
              base:   base,
              threshold: 1.0, // ratio 1.0 = 임계치
              now: now,
              statusCardThreshold: statusCard.tFinal.round(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color base;
  final double threshold; // ratio 단위 (1.0)
  final DateTime now;
  final int statusCardThreshold; // µg/m³ — 임계치 라벨용

  _TrendChartPainter({
    required this.points,
    required this.base,
    required this.threshold,
    required this.now,
    required this.statusCardThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const padX = 4.0;
    const padTop = 12.0;
    const padBot = 22.0;
    final w = size.width;
    final h = size.height;

    final ratios = points.map((p) => p.finalRatio).toList();
    final maxR = ratios.reduce((a, b) => a > b ? a : b);
    final maxScale = maxR > 1.5 ? maxR : 1.5;

    // x, y 좌표 계산
    final xs = List<double>.generate(
      points.length,
      (i) => padX + (i * (w - padX * 2)) / (points.length - 1),
    );
    final ys = ratios
        .map((r) => padTop + (1 - r / maxScale) * (h - padTop - padBot))
        .toList();

    // ── 1. Hairline grid (3줄, 25%·50%·75%) ─────────────
    final gridPaint = Paint()
      ..color = DT.text.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final g in [0.25, 0.5, 0.75]) {
      final y = padTop + g * (h - padTop - padBot);
      canvas.drawLine(Offset(padX, y), Offset(w - padX, y), gridPaint);
    }

    // ── 2. 임계치 점선 (ratio = 1) ────────────────────────
    final thrY = padTop + (1 - threshold / maxScale) * (h - padTop - padBot);
    final thrPaint = Paint()
      ..color = DT.text.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    _drawDashedLine(canvas, Offset(padX, thrY), Offset(w - padX, thrY), thrPaint);

    // 임계치 라벨 ("내 기준 21")
    final thrText = TextPainter(
      text: TextSpan(
        text: '내 기준 $statusCardThreshold',
        style: TextStyle(
          fontSize:   10,
          fontWeight: FontWeight.w600,
          color:      DT.text.withValues(alpha: 0.55),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    thrText.paint(canvas, Offset(w - padX - thrText.width, thrY - thrText.height - 1));

    // ── 3. 부드러운 path (cardinal-ish) + fill 영역 ─────────
    final path = Path();
    final fillPath = Path();
    path.moveTo(xs[0], ys[0]);
    fillPath.moveTo(xs[0], h - padBot);
    fillPath.lineTo(xs[0], ys[0]);
    for (int i = 0; i < xs.length - 1; i++) {
      final cx1 = (xs[i] + xs[i + 1]) / 2;
      final cy1 = ys[i];
      final cx2 = (xs[i] + xs[i + 1]) / 2;
      final cy2 = ys[i + 1];
      path.cubicTo(cx1, cy1, cx2, cy2, xs[i + 1], ys[i + 1]);
      fillPath.cubicTo(cx1, cy1, cx2, cy2, xs[i + 1], ys[i + 1]);
    }
    fillPath.lineTo(xs.last, h - padBot);
    fillPath.close();

    // fill (base 색 7% opacity)
    canvas.drawPath(fillPath, Paint()..color = base.withValues(alpha: 0.07));

    // 데이터 라인 (본문색 1.75px, opacity 0.85)
    canvas.drawPath(
      path,
      Paint()
        ..color = DT.text.withValues(alpha: 0.85)
        ..strokeWidth = 1.75
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── 4. 현재 시점 도트 (= index 0, "지금") ────────────
    // ChartPoint hour=0이 지금, 이후 +1, +2... 시간
    const nowIdx = 0;
    final nowX = xs[nowIdx];
    final nowY = ys[nowIdx];

    canvas.drawCircle(Offset(nowX, nowY), 9, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(nowX, nowY), 5, Paint()..color = base);

    // "지금" 라벨
    final nowText = TextPainter(
      text: const TextSpan(
        text: '지금',
        style: TextStyle(
          fontSize:   10,
          fontWeight: FontWeight.w700,
          color:      DT.text,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nowText.paint(canvas, Offset(nowX - nowText.width / 2, nowY - 14 - nowText.height));

    // ── 5. 시간 라벨 (5개, 균일 분포) ─────────────────────
    final labelIndices = <int>[];
    if (points.length >= 5) {
      labelIndices.addAll([0, points.length ~/ 4, points.length ~/ 2, points.length * 3 ~/ 4, points.length - 1]);
    } else {
      labelIndices.addAll(List.generate(points.length, (i) => i));
    }

    for (int idx in labelIndices) {
      final hour = (now.hour + idx) % 24;
      final h12  = hour % 12 == 0 ? 12 : hour % 12;
      final ampm = hour < 12 ? '오전' : '오후';
      final label = idx == 0 ? '지금' : '$ampm $h12시';

      // "지금"은 위에서 그려서 스킵
      if (idx == 0) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize:      10.5,
            fontWeight:    FontWeight.w500,
            color:         DT.gray,
            letterSpacing: -0.05,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xs[idx] - tp.width / 2, h - tp.height));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 2.0;
    const gapLength = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final unitX = dx / length;
    final unitY = dy / length;
    final stepX = unitX * (dashLength + gapLength);
    final stepY = unitY * (dashLength + gapLength);
    var current = start;
    var traveled = 0.0;
    while (traveled < length) {
      final next = Offset(
        current.dx + unitX * dashLength,
        current.dy + unitY * dashLength,
      );
      canvas.drawLine(current, next, paint);
      current = Offset(current.dx + stepX, current.dy + stepY);
      traveled += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter old) =>
      old.points != points || old.base != base || old.threshold != threshold;
}
