import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/async_state_widgets.dart';
import '../care/widgets/care_background.dart';
import 'models/report_models.dart';
import 'providers/report_providers.dart';
import 'widgets/pattern_line.dart';
import 'widgets/report_hero.dart';
import 'widgets/week_calendar.dart';
import 'widgets/week_caption.dart';

// ── 리포트 탭 (시안 v2) ──────────────────────────────────────

class ReportTab extends ConsumerWidget {
  const ReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weekReportProvider);

    if (reportAsync.hasError) {
      return Scaffold(
        backgroundColor: DT.background,
        body: ErrorStateWidget(
          message: '리포트를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
          onRetry: () => ref.invalidate(weekReportProvider),
        ),
      );
    }

    // 로딩 중이거나 데이터 없으면 empty 상태로 표시
    final weekData = reportAsync.valueOrNull ?? WeekReportData.empty();
    final level = CareBackground.levelFromRatio(weekData.currentFinalRatio);

    return Scaffold(
      body: CareBackground(
        level: level,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(weekReportProvider);
            },
            child: LayoutBuilder(
              builder: (context, viewport) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    // viewport 전체 높이 — Spacer 동작 + footer 하단 고정
                    height: viewport.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ① 주차 캡션
                          WeekCaption(text: weekData.weekCaption),
                          const SizedBox(height: 10),

                          // ② Hero (양 — 8 비중)
                          ReportHero(
                            state:       weekData.state,
                            dangerHours: weekData.dangerHours,
                            heroSize:    64,
                          ),
                          const SizedBox(height: 52),

                          // ③ Calendar (5 비중)
                          WeekCalendar(days: weekData.days),
                          const SizedBox(height: 36),

                          // ④ Pattern (3 비중)
                          PatternLine(pattern: weekData.pattern),

                          // 화면 하단까지 빈 공간 (footer 바닥 고정)
                          const Spacer(),

                          // ⑤ Footer
                          _ReportFooter(
                            updatedTimeLabel: weekData.updatedTimeLabel,
                            isEmpty:
                                weekData.state == WeekReportState.empty,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── 하단 푸터 (자료원 + 더 자세히 보기) ─────────────────────

class _ReportFooter extends StatelessWidget {
  final String updatedTimeLabel;

  /// empty 상태이면 "더 자세히 보기" 버튼을 숨긴다.
  final bool isEmpty;

  const _ReportFooter({
    required this.updatedTimeLabel,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 좌측: 한국환경공단 · 갱신 시각
        Text(
          '한국환경공단 · $updatedTimeLabel',
          style: const TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w500,
            color:      DT.gray2,
          ),
        ),
        // 우측: 더 자세히 보기 → (empty 상태에서는 숨김)
        if (isEmpty)
          const SizedBox.shrink()
        else
          GestureDetector(
            onTap: () => context.push('/report/details'),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '더 자세히 보기',
                    style: TextStyle(
                      fontSize:      14,
                      fontWeight:    FontWeight.w600,
                      color:         DT.text,
                      letterSpacing: -0.14,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: DT.text),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
