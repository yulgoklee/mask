import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/report_models.dart';
import '../providers/report_providers.dart';

// ── WeeklyOverviewCard ────────────────────────────────────
//
// §4.2 "한 주의 그림" 카드.
// weeklyOverviewProvider → List<DayCircleData> 7개를 받아 렌더링.

class WeeklyOverviewCard extends ConsumerWidget {
  const WeeklyOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(weeklyOverviewProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '한 주의 그림',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DT.text,
            ),
          ),
          const SizedBox(height: 16),
          asyncData.when(
            loading: () => _CircleRowPlaceholder(),
            error: (_, __) => const _ErrorText(),
            data: (days) => _CircleRow(days: days),
          ),
        ],
      ),
    );
  }
}

// ── 7개 원 행 ─────────────────────────────────────────────

class _CircleRow extends StatelessWidget {
  final List<DayCircleData> days;

  const _CircleRow({required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: days.map((d) => Expanded(child: _DayCircle(data: d))).toList(),
    );
  }
}

// ── 개별 원(Circle) ──────────────────────────────────────

class _DayCircle extends StatelessWidget {
  final DayCircleData data;

  const _DayCircle({required this.data});

  // final_ratio → 원 배경색
  Color _bgColor(double? ratio) {
    if (ratio == null) return DT.grayLt;
    if (ratio < 0.5) return DT.safeLt;
    if (ratio < 1.0) return DT.primaryLt;
    if (ratio < 1.5) return DT.cautionLt;
    return DT.dangerLt; // danger + critical 모두
  }

  // critical (ratio ≥ 2.0) 여부
  bool _isCritical(double? ratio) => ratio != null && ratio >= 2.0;

  // 요일 라벨 (1=월 ~ 7=일)
  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    final ratio = data.finalRatio;
    final bgColor = _bgColor(ratio);
    final critical = _isCritical(ratio);
    final missing = ratio == null;

    // 원 내부 Border:
    //  - missing: 점선 1px (CustomPaint)
    //  - critical: solid 1px DT.danger
    //  - 그 외: 없음
    //
    // 마스크 링: 원 외곽 2px DT.text (maskWorn=true인 경우)
    // → Container(decoration: BoxDecoration(border: Border.all(color: DT.text, width: 2)))
    //   + 내부에 원(32px)

    const double circleDiameter = 32;

    // 원의 content (내부 dot — 오늘인 경우)
    Widget circleContent = const SizedBox.shrink();
    if (data.isToday && !missing) {
      circleContent = Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: DT.primary,
          shape: BoxShape.circle,
        ),
      );
    }

    // 원 본체 (배경색 + 내부 border + content)
    Widget circleBody;
    if (missing) {
      // 누락: grayLt 배경 + 점선 보더
      circleBody = SizedBox(
        width: circleDiameter,
        height: circleDiameter,
        child: CustomPaint(
          painter: const _DashedCirclePainter(
            color: DT.border,
            strokeWidth: 1,
            dashLength: 3,
            gapLength: 3,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: DT.grayLt,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else if (critical) {
      // critical: dangerLt + 1px DT.danger 보더
      circleBody = Container(
        width: circleDiameter,
        height: circleDiameter,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: DT.danger, width: 1),
        ),
        alignment: Alignment.center,
        child: circleContent,
      );
    } else {
      // normal: 배경색만
      circleBody = Container(
        width: circleDiameter,
        height: circleDiameter,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: circleContent,
      );
    }

    // 마스크 링: 원 외곽 2px DT.text
    // maskWorn=true면 circleBody를 2px border Container로 감싼다.
    // 원 직경은 32px 유지 (border는 outer에 추가됨).
    Widget circleWithRing;
    if (data.maskWorn) {
      circleWithRing = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: DT.text, width: 2),
        ),
        child: circleBody,
      );
    } else {
      circleWithRing = circleBody;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circleWithRing,
        const SizedBox(height: 6),
        Text(
          _weekdayLabel(data.date.weekday),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: DT.gray,
          ),
        ),
      ],
    );
  }
}

// ── 로딩 Placeholder ─────────────────────────────────────

class _CircleRowPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: DT.grayLt,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DT.gray,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── 에러 텍스트 ───────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  const _ErrorText();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(
        child: Text(
          '데이터를 불러오지 못했어요',
          style: TextStyle(fontSize: 13, color: DT.gray),
        ),
      ),
    );
  }
}

// ── DashedCirclePainter ───────────────────────────────────
//
// Flutter BoxDecoration은 점선 보더를 직접 지원하지 않으므로
// CustomPainter로 원형 점선 보더를 그린다.

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    this.dashLength = 4,
    this.gapLength = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // 원의 둘레
    final circumference = 2 * 3.141592653589793 * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    if (dashCount <= 0) return;

    final anglePerUnit = 2 * 3.141592653589793 / dashCount;
    final dashAngle = anglePerUnit * (dashLength / (dashLength + gapLength));

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * anglePerUnit - 3.141592653589793 / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

// 내부에서만 사용하는 별칭 (외부 노출용은 DashedCirclePainter)
typedef _DashedCirclePainter = DashedCirclePainter;
