import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/constants/design_tokens.dart';
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

class _ChartCard extends StatelessWidget {
  final ProtectionChartData data;
  final bool gridExpanded;
  final VoidCallback onTap;

  const _ChartCard({
    required this.data,
    required this.gridExpanded,
    required this.onTap,
  });

  double get _yMax {
    final spots = data.airSpots;
    if (spots.isEmpty) return data.tFinal * 2;
    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.2).clamp(data.tFinal * 2, 200);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DT.white,
          borderRadius: BorderRadius.circular(20),
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
              curve: Curves.easeOutCubic,
              child: gridExpanded ? _buildGrid() : const SizedBox.shrink(),
            ),
            _buildCta(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text(
            '12시간 예보',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DT.text),
          ),
          const Spacer(),
          _LegendItem(color: DT.primary, label: '현재 대기', isDot: false),
          const SizedBox(width: 12),
          _LegendItem(color: DT.teal, label: 'KF94 착용 시', isDot: true),
          const SizedBox(width: 12),
          _LegendItem(color: DT.purple, label: '내 기준', isDot: false, isDashed: true),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final yMax = _yMax;
    final tFinal = data.tFinal;

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
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: _buildTitles(tFinal, yMax),
              extraLinesData: _buildExtraLines(tFinal),
              lineBarsData: [
                _buildAirLine(tFinal),
                _buildMaskLine(tFinal),
              ],
              lineTouchData: _buildTouchData(),
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
  }

  FlTitlesData _buildTitles(double tFinal, double yMax) {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 4,
          getTitlesWidget: (val, meta) {
            final label = switch (val.toInt()) {
              0  => '지금',
              4  => '+4시간',
              8  => '+8시간',
              12 => '+12시간',
              _  => '',
            };
            if (label.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label, style: const TextStyle(fontSize: 10, color: DT.gray)),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (val, meta) {
            final isZero = val == 0;
            final isTFinal = (val - tFinal).abs() < 1;
            final isMax = (val - yMax).abs() < 1;
            if (!isZero && !isTFinal && !isMax) return const SizedBox.shrink();
            return Text(
              val.toInt().toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: isTFinal ? DT.purple : DT.gray,
                fontWeight: isTFinal ? FontWeight.bold : FontWeight.normal,
              ),
            );
          },
        ),
      ),
    );
  }

  ExtraLinesData _buildExtraLines(double tFinal) {
    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: tFinal,
          color: DT.purple,
          strokeWidth: 1.5,
          dashArray: [8, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: DT.purple, fontSize: 11),
            labelResolver: (line) => '내 기준 ${line.y.toInt()}µg',
          ),
        ),
      ],
      verticalLines: [
        VerticalLine(
          x: 0,
          color: DT.gray,
          strokeWidth: 1,
          dashArray: [4, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: DT.gray, fontSize: 10),
            labelResolver: (_) => '▼ 지금',
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildAirLine(double tFinal) {
    final overThreshold = data.isCurrentOverThreshold;
    final lineColor = overThreshold ? DT.danger : DT.primary;
    final areaAbove = overThreshold
        ? const Color(0x99FEE2E2)
        : const Color(0x66DBEAFE);

    return LineChartBarData(
      spots: data.airSpots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: lineColor,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: areaAbove),
      dashArray: data.airSpots.isNotEmpty ? [6, 3] : null,
    );
  }

  LineChartBarData _buildMaskLine(double tFinal) {
    return LineChartBarData(
      spots: data.maskSpots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: Colors.transparent,
      barWidth: 0,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: const Color(0x590D9488),
      ),
    );
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (spots) => spots.map((spot) {
          final isAir = spot.barIndex == 0;
          return LineTooltipItem(
            isAir
                ? '대기 ${spot.y.toInt()}µg'
                : 'KF94 ${spot.y.toInt()}µg',
            TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: isAir ? DT.danger : DT.teal,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid() {
    final now = DateTime.now();
    return AnimationLimiter(
      child: Column(
        children: [
          const Divider(height: 1, color: DT.border),
          ...List.generate(12, (i) {
            final hour = now.add(Duration(hours: i + 1));
            final pm25 = data.airSpots.length > i + 1
                ? data.airSpots[i + 1].y
                : 0.0;
            final grade = _gradeFromValue(pm25);
            final isNow = i == 0;

            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 200),
              delay: Duration(milliseconds: i * 30),
              child: SlideAnimation(
                verticalOffset: 20,
                child: FadeInAnimation(
                  child: _HourlyRow(
                    time: '+${i + 1}시간 (${hour.hour}시)',
                    pm25: pm25.toInt(),
                    grade: grade,
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

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.go('/report'),
          style: TextButton.styleFrom(
            foregroundColor: DT.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: const Text('지난 7일 평균과 비교하기 →', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  String _gradeFromValue(double pm25) {
    if (pm25 <= 15) return '좋음';
    if (pm25 <= 35) return '보통';
    if (pm25 <= 75) return '나쁨';
    return '매우나쁨';
  }
}

class _HourlyRow extends StatelessWidget {
  final String time;
  final int pm25;
  final String grade;
  final bool isHighlighted;

  const _HourlyRow({
    required this.time,
    required this.pm25,
    required this.grade,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: isHighlighted ? DT.primaryLt : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(time, style: const TextStyle(fontSize: 12, color: DT.gray)),
          ),
          Expanded(
            child: Text(
              pm25.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: DT.gradeBadgeBg(grade),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: DT.gradeText(grade),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDot;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDot,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isDot
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : Container(width: 16, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: DT.gray)),
      ],
    );
  }
}
