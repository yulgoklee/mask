import 'package:animated_digit/animated_digit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/profile_providers.dart';
import 'models/report_models.dart';
import 'providers/report_providers.dart';

class ReportTab extends ConsumerWidget {
  const ReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: const Text(
                  '리포트',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DT.text),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PeriodSelector().animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ReportSummaryCard(period: period)
                      .animate(delay: 50.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 16),
                  DailyBarChartCard(period: period)
                      .animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 16),
                  MaskCalendarCard(period: period)
                      .animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 16),
                  HighlightCard(period: period)
                      .animate(delay: 200.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. PeriodSelector ─────────────────────────────────────

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPeriodProvider);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: DT.grayLt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 8) / 3;
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: tabWidth,
                margin: EdgeInsets.only(
                  left: ReportPeriod.values.indexOf(selected) * tabWidth,
                ),
                decoration: BoxDecoration(
                  color: DT.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x14000000))],
                ),
              ),
              Row(
                children: ReportPeriod.values.map((p) => Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(selectedPeriodProvider.notifier).state = p,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected == p ? FontWeight.bold : FontWeight.normal,
                          color: selected == p ? DT.text : DT.gray,
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 2. ReportSummaryCard ──────────────────────────────────

class ReportSummaryCard extends ConsumerWidget {
  final ReportPeriod period;
  const ReportSummaryCard({super.key, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider(period));

    return summaryAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(baseColor: Color(0xFFE5E7EB), highlightColor: Color(0xFFF9FAFB), duration: Duration(milliseconds: 1200)),
        child: _SummaryContent(data: ReportSummaryData(totalDays: 7, dangerDays: 0, maskWornDays: 0, defenseRate: 0, dominantGrade: '좋음')),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _SummaryContent(key: ValueKey(period), data: data),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final ReportSummaryData data;
  const _SummaryContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DT.gradeCardBg(data.dominantGrade),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.summaryText,
            style: const TextStyle(fontSize: 15, color: DT.text, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: DT.border),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCell(label: '위험일', value: data.dangerDays, unit: '일', color: DT.danger),
              _VertDivider(),
              _StatCell(label: '마스크 착용', value: data.maskWornDays, unit: '일', color: DT.safe),
              _VertDivider(),
              _StatCell(label: '방어율', value: data.defenseRate.toInt(), unit: '%', color: DT.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;

  const _StatCell({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedDigitWidget(
                value: value,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                textStyle: TextStyle(fontFamily: 'monospace', fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(fontSize: 12, color: DT.gray)),
              ),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: DT.gray)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: DT.border);
}

// ── 3. DailyBarChartCard ──────────────────────────────────

class DailyBarChartCard extends ConsumerWidget {
  final ReportPeriod period;
  const DailyBarChartCard({super.key, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dailyBarProvider(period));
    final profile = ref.watch(profileProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000))],
      ),
      child: dataAsync.when(
        loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => const SizedBox(height: 180),
        data: (bars) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _BarChartContent(key: ValueKey(period), bars: bars, tFinal: profile.tFinal),
        ),
      ),
    );
  }
}

class _BarChartContent extends StatelessWidget {
  final List<DailyBarData> bars;
  final double tFinal;

  const _BarChartContent({super.key, required this.bars, required this.tFinal});

  Color _barColor(String grade) => switch (grade) {
    '좋음'    => DT.safe,
    '보통'    => DT.primary,
    '나쁨'    => DT.caution,
    '매우나쁨' => DT.danger,
    _         => DT.gray,
  };

  double get _yMax {
    if (bars.isEmpty) return tFinal * 2;
    final maxVal = bars.map((b) => b.pm25Avg).reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.2).clamp(tFinal * 2, 200);
  }

  String _xLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final yMax = _yMax;
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: tFinal,
                color: DT.purple,
                strokeWidth: 1.5,
                dashArray: [6, 3],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(color: DT.purple, fontSize: 11),
                  labelResolver: (_) => '내 기준',
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, meta) {
                  if (val == 0 || (val - tFinal).abs() < 1 || (val - yMax).abs() < 1) {
                    return Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: (val - tFinal).abs() < 1 ? DT.purple : DT.gray,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i >= 0 && i < bars.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_xLabel(bars[i].date),
                          style: const TextStyle(fontSize: 10, color: DT.gray)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: List.generate(bars.length, (i) {
            final b = bars[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: b.pm25Avg,
                  color: _barColor(b.grade),
                  width: bars.length <= 1 ? 80 : bars.length <= 3 ? 60 : 32,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final b = bars[group.x];
                return BarTooltipItem(
                  '${_xLabel(b.date)}\nPM2.5 ${b.pm25Avg.toInt()}µg\n${b.grade}${b.maskWorn ? '\n😷 착용' : ''}',
                  const TextStyle(fontSize: 12, color: DT.text),
                );
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      ),
    );
  }
}

// ── 4. MaskCalendarCard ───────────────────────────────────

class MaskCalendarCard extends ConsumerWidget {
  final ReportPeriod period;
  const MaskCalendarCard({super.key, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calAsync = ref.watch(calendarProvider(period));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('마스크 착용 기록', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DT.text)),
          const SizedBox(height: 16),
          calAsync.when(
            loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (days) => _CalendarRow(days: days),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(color: DT.safeLt, label: '착용'),
              const SizedBox(width: 12),
              _Legend(color: DT.dangerLt, label: '미착용'),
              const SizedBox(width: 12),
              _Legend(color: DT.grayLt, label: '기록없음'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarRow extends StatelessWidget {
  final List<CalendarDayData> days;
  const _CalendarRow({required this.days});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Row(
        children: List.generate(days.length, (i) {
          final day = days[i];
          return AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 200),
            delay: Duration(milliseconds: i * 50),
            child: ScaleAnimation(
              scale: 0.85,
              child: FadeInAnimation(
                child: Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: day.isInSelectedPeriod ? 1.0 : 0.3,
                    child: _CalendarCell(data: day),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final CalendarDayData data;
  const _CalendarCell({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = switch (data.status) {
      CalendarDayStatus.worn    => DT.safeLt,
      CalendarDayStatus.notWorn => DT.dangerLt,
      CalendarDayStatus.noData  => DT.grayLt,
    };
    final icon = switch (data.status) {
      CalendarDayStatus.worn    => '😷',
      CalendarDayStatus.notWorn => '✕',
      CalendarDayStatus.noData  => '–',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: data.isToday ? Border.all(color: DT.primary, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: data.status == CalendarDayStatus.worn ? 16 : 12,
                  color: data.status == CalendarDayStatus.notWorn ? DT.danger : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.isToday ? '오늘' : '${data.date.month}/${data.date.day}',
            style: TextStyle(
              fontSize: 10,
              color: data.isToday ? DT.primary : DT.gray,
              fontWeight: data.isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (data.isToday)
            Container(
              width: 4, height: 4,
              decoration: const BoxDecoration(color: DT.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: DT.gray)),
      ],
    );
  }
}

// ── 5. HighlightCard ──────────────────────────────────────

class HighlightCard extends ConsumerWidget {
  final ReportPeriod period;
  const HighlightCard({super.key, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(highlightProvider(period));

    return dataAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (!data.isAllSafe && data.pm25Max == 0) return const SizedBox.shrink();
        return _HighlightContent(data: data);
      },
    );
  }
}

class _HighlightContent extends StatelessWidget {
  final HighlightData data;
  const _HighlightContent({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isAllSafe) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DT.safeBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000))],
        ),
        child: const Text('이 기간 위험한 날이 없었어요 🎉',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DT.safe)),
      );
    }

    final dateStr = '${data.date.month}월 ${data.date.day}일 (${_weekday(data.date)})';

    return Container(
      decoration: BoxDecoration(
        color: DT.dangerBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000))],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 140,
            decoration: const BoxDecoration(
              color: DT.danger,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚡ 이 기간 가장 나쁜 날',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DT.danger)),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedDigitWidget(
                        value: data.pm25Max.toInt(),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 36, fontWeight: FontWeight.bold, color: DT.danger),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(' µg/m³', style: TextStyle(fontSize: 14, color: DT.gray)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.maskWorn ? '😷 마스크를 착용하셨어요 ✓' : '마스크를 챙기지 못한 날이에요',
                    style: TextStyle(fontSize: 13, color: data.maskWorn ? DT.safe : DT.gray),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime dt) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dt.weekday - 1];
  }
}
