import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/location_providers.dart';
import 'models/report_models.dart';
import 'providers/report_providers.dart';
import 'widgets/insight_card.dart';
import 'widgets/trend_line.dart';
import 'widgets/weekly_overview_card.dart';

class ReportTab extends ConsumerWidget {
  const ReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(locationStateProvider).station;

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 타이틀 + 부제목 ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '리포트',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DT.text,
                      ),
                    ),
                    if (station != null && station.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$station · 최근 7일',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: DT.gray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // ── 카드 목록 ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // [카드 4] ReportSummaryCard (§4.6 순서: 먼저)
                  const ReportSummaryCard()
                      .animate(delay: 50.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 16),
                  // [카드 1] WeeklyOverviewCard
                  const WeeklyOverviewCard()
                      .animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 16),
                  // [카드 2] InsightCard (데이터 없으면 SizedBox.shrink)
                  const InsightCard()
                      .animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 8),
                  // [카드 3] TrendLine (데이터 없으면 SizedBox.shrink)
                  const TrendLine()
                      .animate(delay: 200.ms).fadeIn(duration: 300.ms),
                  // [여백]
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

// ── ReportSummaryCard ─────────────────────────────────────
//
// §4.5 단순화된 요약 카드.
// 방어율 셀 제거 (Lead 결정 1번). 위험일 + 마스크 착용일만 표시.
// dominantGrade = final_ratio 기반 (§4.5).

class ReportSummaryCard extends ConsumerWidget {
  const ReportSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider);

    return summaryAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: DT.border,
          highlightColor: DT.background,
          duration: Duration(milliseconds: 1200),
        ),
        child: const _SummaryContent(
          data: ReportSummaryData(
            totalDays: 7,
            dangerDays: 0,
            maskWornDays: 0,
            defenseRate: 0,
            dominantGrade: '좋음',
          ),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DT.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTokens.shadowCard,
        ),
        child: const Text(
          '요약을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          style: TextStyle(fontSize: 14, color: DT.gray, height: 1.5),
        ),
      ),
      data: (data) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _SummaryContent(
          key: ValueKey('${data.dangerDays}_${data.maskWornDays}_${data.dominantGrade}'),
          data: data,
        ),
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
        boxShadow: AppTokens.shadowCard,
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
              _StatCell(
                label: '위험일',
                value: data.dangerDays,
                unit: '일',
                color: DT.danger,
              ),
              _VertDivider(),
              _StatCell(
                label: '마스크 착용',
                value: data.maskWornDays,
                unit: '일',
                color: DT.safe,
              ),
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

  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

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
                textStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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
