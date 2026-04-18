import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/health_calculator.dart';
import '../../providers/defense_providers.dart';

/// 방어 리포트 화면
///
/// 구성:
///  - 방어율 카드 (Phase 5 신규)
///  - 30일 달력 (Phase 5 신규)
///  - 7일 바 차트
///  - 건강 인사이트 카드
///  - 주간 통계 카드
///  - 기록 없음: 빈 상태
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyStatsProvider);
    final hasData = stats.count > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 헤더 ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '방어 기록',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '마스크를 챙긴 날의 기록이에요',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // 공유 버튼
                    const _ShareButton(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Phase 5: 방어율 카드 ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DefenseRateCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Phase 5: 30일 달력 ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DefenseCalendar(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── 7일 바 차트 ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WeeklyBarChart(
                  dailyTotals: stats.dailyTotals,
                  hasData: hasData,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (hasData) ...[
              // ── 건강 인사이트 카드 ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _InsightCard(stats: stats),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── 주간 통계 카드 ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WeeklyStatsCard(stats: stats),
                ),
              ),
            ] else ...[
              // ── 빈 상태 안내 ──────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _EmptyState(),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Phase 5: 방어율 카드 ─────────────────────────────────────────

class _DefenseRateCard extends ConsumerWidget {
  const _DefenseRateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 7일 기준 방어율 사용
    final rateAsync = ref.watch(defenseRateProvider(7));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: rateAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => const SizedBox(
          height: 80,
          child: Center(
            child: Text('데이터를 불러올 수 없어요',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
        data: (rateStats) => Row(
          children: [
            // 원형 진행 바
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: rateStats.confirmedRate,
                    strokeWidth: 7,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                  Text(
                    rateStats.ratePercent,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🛡️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '최근 7일 방어율',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rateStats.metaphorText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rateStats.subText(7),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 5: 30일 달력 ──────────────────────────────────────────

class _DefenseCalendar extends ConsumerWidget {
  const _DefenseCalendar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(defenseCalendarProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30일 방어 달력',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              // 범례
              Row(
                children: [
                  _LegendDot(
                      color: AppColors.success, label: '챙김'),
                  const SizedBox(width: 10),
                  _LegendDot(
                      color: AppColors.coral, label: '놓침'),
                  const SizedBox(width: 10),
                  _LegendDot(
                      color: AppColors.surfaceVariant, label: '맑음'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 달력 본체
          calendarAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 80,
              child: Center(
                child: Text('달력을 불러올 수 없어요',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            data: (days) => _CalendarGrid(days: days),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<DefenseCalendarDay> days;

  const _CalendarGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    // 오늘부터 과거 순으로 정렬 (index 0 = 오늘)
    // defenseCalendarProvider는 최신→과거 순으로 반환
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((day) => _CalendarCell(day: day)).toList(),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DefenseCalendarDay day;

  const _CalendarCell({required this.day});

  Color get _bgColor {
    switch (day.status) {
      case CalendarDayStatus.defended:
        return AppColors.success;
      case CalendarDayStatus.missed:
        return AppColors.coral;
      case CalendarDayStatus.clean:
        return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(6),
          border: day.isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.date.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                day.isToday ? FontWeight.bold : FontWeight.normal,
            color: day.status == CalendarDayStatus.clean
                ? AppColors.textSecondary
                : Colors.white,
          ),
        ),
      ),
    );
  }

  String get _tooltip {
    final m = day.date.month;
    final d = day.date.day;
    switch (day.status) {
      case CalendarDayStatus.defended:
        return '$m/$d 마스크 챙김 (알림 ${day.notifCount}회)';
      case CalendarDayStatus.missed:
        return '$m/$d 마스크 놓침 (알림 ${day.notifCount}회)';
      case CalendarDayStatus.clean:
        return '$m/$d 위험 알림 없음';
    }
  }
}

// ── Phase 5: 공유 버튼 ──────────────────────────────────────────

class _ShareButton extends ConsumerWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAsync = ref.watch(defenseRateProvider(7));
    final stats = ref.watch(weeklyStatsProvider);

    return IconButton(
      onPressed: () async {
        final rate = rateAsync.valueOrNull ?? DefenseRateStats.empty;
        final shareText = _buildShareText(rate, stats);
        await Clipboard.setData(ClipboardData(text: shareText));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('클립보드에 복사됐어요 📋'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      icon: const Icon(
        Icons.ios_share_outlined,
        color: AppColors.textSecondary,
        size: 22,
      ),
      tooltip: '기록 공유',
    );
  }

  String _buildShareText(DefenseRateStats rate, WeeklyStats weekly) {
    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.writeln('🛡️ 마스크 알람이 방어 리포트');
    buffer.writeln(
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} 기준');
    buffer.writeln();
    buffer.writeln('📊 최근 7일 방어율: ${rate.ratePercent}');
    buffer.writeln(rate.subText(7));
    buffer.writeln();
    buffer.writeln('이번 주 착용 횟수: ${weekly.count}번');
    buffer.writeln('연속 실천: ${weekly.streakDays}일');
    buffer.writeln();
    buffer.writeln(rate.metaphorText);
    return buffer.toString();
  }
}

// ── 7일 바 차트 ─────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<double> dailyTotals; // index 0 = 오늘, 6 = 6일 전
  final bool hasData;

  const _WeeklyBarChart({
    required this.dailyTotals,
    required this.hasData,
  });

  static const _dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  String _dayLabel(int daysAgo) {
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    return _dayLabels[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final maxY = !hasData
        ? 20.0
        : (dailyTotals.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(5.0, double.infinity);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '7일 착용 기록',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: hasData ? 1.0 : 0.35,
              child: BarChart(
                BarChartData(
                  maxY: hasData ? maxY : 20,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          final daysAgo = 6 - idx;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _dayLabel(daysAgo),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (i) {
                    final daysAgo = 6 - i;
                    final value =
                        hasData ? dailyTotals[daysAgo] : _sampleData[i];
                    final isToday = daysAgo == 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _sampleData = [5.0, 12.0, 8.0, 15.0, 10.0, 18.0, 7.0];
}

// ── 건강 인사이트 카드 ───────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final WeeklyStats stats;
  const _InsightCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cigText = HealthCalculator.primaryInsight(stats.totalUg);
    final subwayRides = HealthCalculator.toSubwayRides(stats.totalUg);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '이번 주 방어 효과',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cigText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '지하철 30분 탑승 ${subwayRides.toStringAsFixed(1)}번치 미세먼지',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}

// ── 주간 통계 카드 ───────────────────────────────────────────────

class _WeeklyStatsCard extends StatelessWidget {
  final WeeklyStats stats;
  const _WeeklyStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final streakMsg = HealthCalculator.streakMessage(stats.streakDays);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: '🎯',
                value: '${stats.count}번',
                label: '이번 주 착용',
              ),
              _divider(),
              _StatItem(
                icon: '💨',
                value: '${stats.totalUg.toStringAsFixed(0)}μg',
                label: '총 방어 질량',
              ),
              _divider(),
              _StatItem(
                icon: '🔥',
                value: '${stats.streakDays}일',
                label: '연속 실천',
              ),
            ],
          ),
          if (stats.streakDays > 0) ...[
            const Divider(height: 28, color: AppColors.divider),
            Text(
              streakMsg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppColors.divider,
      );
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ── 빈 상태 ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🛡️', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '아직 방어 기록이 없어요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '알림을 받고 "마스크 챙겼어요"를 누르면\n방어 기록이 쌓이기 시작해요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
