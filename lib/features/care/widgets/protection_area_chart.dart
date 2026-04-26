import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/dust_standards.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';

class ProtectionAreaChart extends ConsumerStatefulWidget {
  const ProtectionAreaChart({super.key});

  @override
  ConsumerState<ProtectionAreaChart> createState() => _ProtectionAreaChartState();
}

class _ProtectionAreaChartState extends ConsumerState<ProtectionAreaChart> {
  bool _gridExpanded = false;

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(protectionChartProvider);

    return chartAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: Color(0xFFE5E7EB),
          highlightColor: Color(0xFFF9FAFB),
          duration: Duration(milliseconds: 1200),
        ),
        child: _ChartCard(
          data: ProtectionChartData.placeholder(),
          gridExpanded: false,
          onTap: () {},
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => _ChartCard(
        data: data,
        gridExpanded: _gridExpanded,
        onTap: () => setState(() => _gridExpanded = !_gridExpanded),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

// ── 차트 카드 ─────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final ProtectionChartData data;
  final bool gridExpanded;
  final VoidCallback onTap;

  const _ChartCard({
    required this.data,
    required this.gridExpanded,
    required this.onTap,
  });

  // ── ChartPoint → FlSpot 변환 (fl_chart용) ────────────

  List<FlSpot> get _airFlSpots =>
      data.chartPoints.map((p) => FlSpot(p.hour, p.finalRatio)).toList();

  List<FlSpot> get _maskFlSpots => data.chartPoints
      .map((p) => FlSpot(p.hour, p.finalRatio * (1 - data.filterRate)))
      .toList();

  // ── Y축 상한: 최대 ratio의 1.2배, 최소 2.0 ─────────────

  double get _yMax {
    if (data.chartPoints.isEmpty) return 2.0;
    final maxRatio = data.chartPoints
        .map((p) => p.finalRatio)
        .reduce((a, b) => a > b ? a : b);
    return (maxRatio * 1.2).clamp(2.0, 4.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        DT.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildChart(),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve:    Curves.easeOutCubic,
              child: gridExpanded ? _buildGrid() : const SizedBox.shrink(),
            ),
            _buildCta(context),
          ],
        ),
      ),
    );
  }

  // ── 헤더: 카드 제목 + verdict 한 줄 ─────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '앞으로 12시간',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.bold,
              color:      DT.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verdictText(data.verdict),
            style: const TextStyle(
              fontSize: 14,
              color:    DT.gray,
              height:   1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── 차트 본체 ─────────────────────────────────────────

  Widget _buildChart() {
    const threshold = 1.0; // final_ratio 기준선 (§2.9 v4)
    final yMax = _yMax;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: SizedBox(
        height: 200,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: LineChart(
            key: ValueKey(data.generatedAt.millisecondsSinceEpoch),
            LineChartData(
              minX: 0,
              maxX: 12,
              minY: 0,
              maxY: yMax,
              clipData:        const FlClipData.all(),
              gridData:        const FlGridData(show: false),
              borderData:      FlBorderData(show: false),
              titlesData:      _buildTitles(threshold, yMax),
              extraLinesData:  _buildExtraLines(threshold),
              lineBarsData: [
                _buildAirLine(),
                _buildMaskLine(),
              ],
              lineTouchData: _buildTouchData(),
            ),
            duration: const Duration(milliseconds: 800),
            curve:    Curves.easeOut,
          ),
        ),
      ),
    );
  }

  // ── Y축: 0 / 1.0(보라) / yMax  X축: 시간대 라벨 ────────

  FlTitlesData _buildTitles(double threshold, double yMax) {
    // X축 라벨: 현재 시각 기준 상대 시간대
    final now = DateTime.now();
    String _xLabel(int h) {
      if (h == 0) return '지금';
      final target = now.add(Duration(hours: h));
      final hr = target.hour;
      if (hr >= 5  && hr < 12) return '오전';
      if (hr >= 12 && hr < 18) return '낮';
      if (hr >= 18 && hr < 22) return '저녁';
      return '밤';
    }

    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval:   4,
          getTitlesWidget: (val, meta) {
            final h = val.toInt();
            if (h != 0 && h != 4 && h != 8 && h != 12) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _xLabel(h),
                style: const TextStyle(fontSize: 10, color: DT.gray),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles:   true,
          reservedSize: 28,
          getTitlesWidget: (val, meta) {
            final isZero      = val == 0;
            final isThreshold = (val - threshold).abs() < 0.05;
            final isMax       = (val - yMax).abs() < 0.05;
            if (!isZero && !isThreshold && !isMax) return const SizedBox.shrink();
            return Text(
              isThreshold ? '1.0' : val.toInt().toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize:   10,
                color:      isThreshold ? DT.purple : DT.gray,
                fontWeight: isThreshold ? FontWeight.bold : FontWeight.normal,
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 기준선(y=1.0) + 현재 지점 수직선 ────────────────────

  ExtraLinesData _buildExtraLines(double threshold) {
    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y:           threshold,
          color:       DT.purple,
          strokeWidth: 1.5,
          dashArray:   [8, 4],
          label: HorizontalLineLabel(
            show:      true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: DT.purple, fontSize: 11),
            labelResolver: (_) => '내 기준',
          ),
        ),
      ],
      verticalLines: [
        VerticalLine(
          x:           0,
          color:       DT.gray,
          strokeWidth: 1,
          dashArray:   [4, 4],
          label: VerticalLineLabel(
            show:      true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: DT.gray, fontSize: 10),
            labelResolver: (_) => '▼ 지금',
          ),
        ),
      ],
    );
  }

  // ── 대기 곡선: 기준 초과 여부에 따라 색 분기 (§3.3 v4) ──

  LineChartBarData _buildAirLine() {
    final over      = data.isCurrentOverThreshold;
    final lineColor = over ? DT.danger  : DT.primary;
    final areaColor = over
        ? const Color(0x33FEE2E2)  // dangerLt 20%
        : const Color(0x33DBEAFE); // primaryLt 20%
    final airFlSpots = _airFlSpots;

    return LineChartBarData(
      spots:                    airFlSpots,
      isCurved:                 true,
      preventCurveOverShooting: true,
      color:                    lineColor,
      barWidth:                 2.5,
      dotData:                  const FlDotData(show: false),
      belowBarData:             BarAreaData(show: true, color: areaColor),
      dashArray:                airFlSpots.isNotEmpty ? [6, 3] : null,
    );
  }

  // ── KF94 마스크 곡선: 투명 선 + 틸 음영 ─────────────────

  LineChartBarData _buildMaskLine() {
    return LineChartBarData(
      spots:                    _maskFlSpots,
      isCurved:                 true,
      preventCurveOverShooting: true,
      color:                    Colors.transparent,
      barWidth:                 0,
      dotData:                  const FlDotData(show: false),
      belowBarData:             BarAreaData(
        show:  true,
        color: const Color(0x590D9488),
      ),
    );
  }

  // ── 터치 툴팁: ratio 값 (소수점 2자리) ──────────────────

  LineTouchData _buildTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (spots) => spots.map((spot) {
          final isAir = spot.barIndex == 0;
          return LineTooltipItem(
            isAir
                ? '대기 ×${spot.y.toStringAsFixed(2)}'
                : 'KF94 ×${spot.y.toStringAsFixed(2)}',
            TextStyle(
              fontFamily: 'monospace',
              fontSize:   12,
              color:      isAir ? DT.danger : DT.teal,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 시간별 그리드 (tap 토글) ──────────────────────────────

  Widget _buildGrid() {
    final now = DateTime.now();
    return AnimationLimiter(
      child: Column(
        children: [
          const Divider(height: 1, color: DT.border),
          ...List.generate(12, (i) {
            final hour    = now.add(Duration(hours: i + 1));
            final rawPm25 = data.chartPoints.length > i + 1
                ? data.chartPoints[i + 1].rawPm25
                : 0.0;
            final grade   = DustStandards.getPm25Grade(rawPm25.toInt()).label;
            final isNow   = i == 0;

            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 200),
              delay:    Duration(milliseconds: i * 30),
              child: SlideAnimation(
                verticalOffset: 20,
                child: FadeInAnimation(
                  child: _HourlyRow(
                    time:          '+${i + 1}시간 (${hour.hour}시)',
                    pm25:          rawPm25.toInt(),
                    grade:         grade,
                    isHighlighted: isNow,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 하단 링크 ─────────────────────────────────────────────

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 16, 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.go('/report'),
          style: TextButton.styleFrom(
            foregroundColor: DT.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: const Text(
            '지난 7일 평균과 비교하기 ›',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ── 시간별 행 ──────────────────────────────────────────────

class _HourlyRow extends StatelessWidget {
  final String time;
  final int    pm25;
  final String grade;
  final bool   isHighlighted;

  const _HourlyRow({
    required this.time,
    required this.pm25,
    required this.grade,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  48,
      color:   isHighlighted ? DT.primaryLt : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(time, style: const TextStyle(fontSize: 12, color: DT.gray)),
          ),
          Expanded(
            child: Text(
              '$pm25 µg',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:        DT.gradeBadgeBg(grade),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.bold,
                color:      DT.gradeText(grade),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
