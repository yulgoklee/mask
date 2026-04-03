import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/forecast_models.dart';
import '../../providers/providers.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/grade_badge.dart';

class DustForecastDetailScreen extends ConsumerWidget {
  final String stationName;
  final String sidoName;

  const DustForecastDetailScreen({
    super.key,
    required this.stationName,
    required this.sidoName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            '자세히 보기',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: '12시간 현황'),
              Tab(text: '단기 예보 (3일)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HourlyTab(stationName: stationName),
            _WeeklyTab(sidoName: sidoName),
          ],
        ),
      ),
    );
  }
}

// ── 24시간 현황 탭 ─────────────────────────────────────────

class _HourlyTab extends ConsumerWidget {
  final String stationName;
  const _HourlyTab({required this.stationName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyAsync = ref.watch(hourlyDataProvider(stationName));

    return hourlyAsync.when(
      loading: () => const LoadingStateWidget(message: '시간별 현황 불러오는 중...'),
      error: (e, _) => ErrorStateWidget(
        message: '시간별 현황을 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
        onRetry: () => ref.invalidate(hourlyDataProvider(stationName)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.access_time_outlined,
            message: '시간별 데이터가 없어요.\n측정소를 확인해 주세요.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HourlyTable(items: items),
            const SizedBox(height: 12),
            Text(
              '* 측정소: $stationName  /  현재 기준 12시간 예보',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        );
      },
    );
  }
}

class _HourlyTable extends StatelessWidget {
  final List<HourlyDustData> items;
  const _HourlyTable({required this.items});

  static const _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    return _DataTable(
      header: const Row(
        children: [
          SizedBox(
              width: 66,
              child: Text('시간', style: _tableHeaderStyle)),
          Expanded(
              child: Text('미세먼지\n(PM10)',
                  style: _tableHeaderStyle, textAlign: TextAlign.center)),
          Expanded(
              child: Text('초미세먼지\n(PM2.5)',
                  style: _tableHeaderStyle, textAlign: TextAlign.center)),
        ],
      ),
      rows: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        final isNow = i == 0;
        return _DataRow(
          isHighlighted: isNow,
          isLast: i == items.length - 1,
          child: Row(
            children: [
              SizedBox(
                width: 66,
                child: Text(
                  () {
                    if (isNow) return '지금';
                    if (item.time.hour == 0) {
                      const wd = ['월','화','수','목','금','토','일'];
                      return '${item.time.month}/${item.time.day}'
                          '(${wd[item.time.weekday - 1]})\n00시';
                    }
                    return '${item.time.hour.toString().padLeft(2, '0')}시';
                  }(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                    color: isNow ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: GradeBadge(
                  grade: item.pm10Grade,
                  valueLabel: item.pm10 != null ? '${item.pm10}μg' : null,
                  emojiSize: 16,
                  labelSize: 10,
                ),
              ),
              Expanded(
                child: GradeBadge(
                  grade: item.pm25Grade,
                  valueLabel: item.pm25 != null ? '${item.pm25}μg' : null,
                  emojiSize: 16,
                  labelSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 단기 예보 탭 ───────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  final String sidoName;
  const _WeeklyTab({required this.sidoName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyForecastProvider(sidoName));

    return weeklyAsync.when(
      loading: () => const LoadingStateWidget(message: '단기 예보 불러오는 중...'),
      error: (e, _) => ErrorStateWidget(
        message: '단기 예보를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
        onRetry: () => ref.invalidate(weeklyForecastProvider(sidoName)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.wb_sunny_outlined,
            message: '예보 데이터가 없어요.\n잠시 후 다시 확인해 주세요.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _WeeklyTable(items: items),
            const SizedBox(height: 12),
            const Text(
              '* 출처: 한국환경공단 에어코리아\n'
              '* 에어코리아 API는 오늘·내일·모레 3일 예보만 제공합니다.\n'
              '* 예보는 하루 3회(05시·11시·17시) 업데이트됩니다.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textHint, height: 1.5),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyTable extends StatelessWidget {
  final List<WeeklyForecastData> items;
  const _WeeklyTable({required this.items});

  static const _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  String _dayLabel(DateTime date, int idx) {
    if (idx == 0) return '오늘';
    if (idx == 1) return '내일';
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${days[date.weekday - 1]}  ${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return _DataTable(
      header: const Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('날짜', style: _tableHeaderStyle)),
          Expanded(
              flex: 2,
              child: Text('미세먼지\n(PM10)',
                  style: _tableHeaderStyle, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('초미세먼지\n(PM2.5)',
                  style: _tableHeaderStyle, textAlign: TextAlign.center)),
        ],
      ),
      rows: items.asMap().entries.map((e) {
        final idx = e.key;
        final d = e.value;
        final isToday = idx == 0;
        return _DataRow(
          isHighlighted: isToday,
          isLast: idx == items.length - 1,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  _dayLabel(d.date, idx),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                  flex: 2,
                  child: GradeBadge(grade: d.pm10Grade, labelSize: 11)),
              Expanded(
                  flex: 2,
                  child: GradeBadge(grade: d.pm25Grade, labelSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 공통 테이블 레이아웃 ──────────────────────────────────

class _DataTable extends StatelessWidget {
  final Widget header;
  final List<_DataRow> rows;
  const _DataTable({required this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.divider.withOpacity(0.4),
            child: header,
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final Widget child;
  final bool isHighlighted;
  final bool isLast;
  const _DataRow({
    required this.child,
    required this.isHighlighted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary.withOpacity(0.05) : null,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: child,
    );
  }
}
