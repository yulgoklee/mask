import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../care/widgets/care_background.dart';
import '../../providers/dust_providers.dart';
import '../../providers/profile_providers.dart';
import '../../core/utils/dust_calculator.dart';
import 'models/report_models.dart';
import 'providers/report_providers.dart';
import 'widgets/week_calendar.dart';

/// 리포트 탭 Drill-down 화면 (/report/details)
///
/// slideUp 전환으로 진입. 히트맵 + 일별 상세 + 자료원.
class ReportDrillScreen extends ConsumerWidget {
  const ReportDrillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drillAsync  = ref.watch(drillReportProvider);
    final weekAsync   = ref.watch(weekReportProvider);
    final dustAsync   = ref.watch(dustDataProvider);
    final profile     = ref.watch(profileProvider);

    // CareBackground 레벨 — dustDataProvider에서 직접 계산
    double currentRatio = 0.0;
    dustAsync.whenData((dust) {
      if (dust != null) {
        currentRatio = DustCalculator.computeHistoricalFinalRatio(
          tFinalPm25: profile.tFinal,
          pm25: dust.pm25Value,
          pm10: dust.pm10Value,
        );
      }
    });
    // weekReportProvider에서도 가져올 수 있으면 우선 사용
    weekAsync.whenData((w) => currentRatio = w.currentFinalRatio);

    final level = CareBackground.levelFromRatio(currentRatio);

    // drillData fallback
    final drillData = drillAsync.valueOrNull ?? DrillReportData(
      heatmap: DrillHeatmapData(
        grid: List.generate(7, (_) => List<double?>.filled(24, null)),
        weekdayLabels: const ['월', '화', '수', '목', '금', '토', '일'],
      ),
      dayRows: [],
      weekCaption: '',
    );

    return Scaffold(
      body: CareBackground(
        level: level,
        child: SafeArea(
          child: Column(
            children: [
              // ── Sticky 헤더: back + 제목 ──────────────────
              _DrillHeader(weekCaption: drillData.weekCaption),

              // ── 본문 (스크롤) ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. 요일 × 시간대 히트맵 ──────────
                      const _DrillSection(title: '요일 × 시간대'),
                      _HeatmapGrid(data: drillData.heatmap),
                      const SizedBox(height: 28),

                      // ── 2. 일별 상세 ─────────────────────
                      if (drillData.dayRows.isNotEmpty) ...[
                        const _DrillSection(title: '일별 상세'),
                        ...drillData.dayRows.map((r) => _DayRow(row: r)),
                        const SizedBox(height: 28),
                      ],

                      // ── 3. 자료원 ─────────────────────────
                      const _DrillSection(title: '자료원'),
                      const _SourceRow(
                        title: '한국환경공단 AirKorea',
                        sub:   '실시간 PM2.5·PM10 측정망 · 전국 약 600개소',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '* 본 앱은 참고용 정보를 제공합니다. '
                        '의료적 진단이나 처방을 대체하지 않습니다.',
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                          color:      DT.gray2,
                          height:     1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sticky 헤더 ────────────────────────────────────────────────

class _DrillHeader extends StatelessWidget {
  final String weekCaption;

  const _DrillHeader({required this.weekCaption});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 22,
                color: DT.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '이번 주 자세히',
              style: TextStyle(
                fontSize:      17,
                fontWeight:    FontWeight.w700,
                color:         DT.text,
                letterSpacing: -0.34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 라벨 ──────────────────────────────────────────────────

class _DrillSection extends StatelessWidget {
  final String title;

  const _DrillSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize:      13,
          fontWeight:    FontWeight.w700,
          color:         DT.gray,
          letterSpacing: 0.52,
        ),
      ),
    );
  }
}

// ── 히트맵 그리드 (7×24, CustomPainter) ────────────────────────

class _HeatmapGrid extends StatelessWidget {
  final DrillHeatmapData data;

  const _HeatmapGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const labelW = 18.0;
      const gap    = 2.0;
      const cellH  = 14.0;
      final availW = constraints.maxWidth - labelW - gap;
      final cellW  = (availW - gap * 23) / 24;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7 rows
          ...List.generate(data.weekdayLabels.length, (wIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: labelW,
                    child: Text(
                      data.weekdayLabels[wIdx],
                      style: const TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w500,
                        color:      DT.gray,
                      ),
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Row(
                      children: List.generate(24, (hIdx) {
                        final ratio = data.grid[wIdx][hIdx];
                        return Padding(
                          padding: EdgeInsets.only(right: hIdx < 23 ? gap : 0),
                          child: Container(
                            width: cellW,
                            height: cellH,
                            decoration: BoxDecoration(
                              color: ratio != null
                                  ? WeekCalendar.ratioToCalColor(ratio)
                                  : DT.grayLt,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
          // 시간 라벨 행
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: labelW + gap),
            child: Row(
              children: [0, 6, 12, 18].map((h) {
                return Expanded(
                  flex: h == 18 ? (24 - 18) : 6,
                  child: Text(
                    '$h시',
                    style: const TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w500,
                      color:      DT.gray2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}

// ── 일별 상세 행 ───────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final DrillDayRow row;

  const _DayRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final pm25str = row.peakPm25 != null ? '${row.peakPm25}㎍' : '—';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DT.text.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: 날짜 + 서브 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.dateLabel,
                  style: const TextStyle(
                    fontSize:      14,
                    fontWeight:    FontWeight.w600,
                    color:         DT.text,
                    letterSpacing: -0.14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '위험 시간 ${row.hoursRange} · PM2.5 최고 $pm25str',
                  style: const TextStyle(
                    fontSize:      12,
                    fontWeight:    FontWeight.w500,
                    color:         DT.gray,
                    letterSpacing: -0.06,
                  ),
                ),
              ],
            ),
          ),
          // 우측: PM2.5 최고값 (K-2 결정)
          Text(
            pm25str,
            style: const TextStyle(
              fontSize:      14,
              fontWeight:    FontWeight.w700,
              color:         DT.text,
              letterSpacing: -0.14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 자료원 행 ──────────────────────────────────────────────────

class _SourceRow extends StatelessWidget {
  final String title;
  final String sub;

  const _SourceRow({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize:      14,
              fontWeight:    FontWeight.w600,
              color:         DT.text,
              letterSpacing: -0.14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w500,
              color:      DT.gray,
              height:     1.5,
            ),
          ),
        ],
      ),
    );
  }
}
