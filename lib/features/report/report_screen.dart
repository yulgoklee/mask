import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/health_calculator.dart';
import '../../providers/defense_providers.dart';

/// 방어 리포트 화면
///
/// 구성:
///  - 기록 없음: 빈 상태 (방패 아이콘 + 안내 + 흐린 샘플 차트)
///  - 기록 있음: 7일 바 차트 + 건강 인사이트 카드 + 주간 통계 카드
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
                padding:
                    const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '방어 리포트',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '마스크를 챙긴 날의 기록이에요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
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
    // dailyTotals는 항상 길이 7인 리스트(List.filled)이므로 isEmpty는 절대 true가 되지 않음.
    // hasData(실제 기록 존재 여부)로 분기해야 빈 상태 maxY가 올바르게 설정됨.
    final maxY = !hasData
        ? 20.0 // 빈 상태: 샘플 데이터(최대 18)에 맞는 고정값
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
                    // 인덱스 0~6: 0이 오늘, 6이 6일 전
                    // x축은 왼쪽이 6일 전 → 오른쪽이 오늘 (reversed)
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
              // i=0 → 6일 전(dailyTotals[6]), i=6 → 오늘(dailyTotals[0])
              final daysAgo = 6 - i;
              final value = hasData ? dailyTotals[daysAgo] : _sampleData[i];
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
    );
  }

  // 빈 상태에서 흐릿하게 보여줄 샘플 데이터
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
          // 통계 3개 가로 배치
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
          // 방패 아이콘 — 은은한 원형 배경 위
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
            '알림을 받고 "챙겼어요"를 누르면\n방어 기록이 쌓이기 시작해요',
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
