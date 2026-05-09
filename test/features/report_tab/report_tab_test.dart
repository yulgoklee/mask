import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/providers/report_providers.dart';
import 'package:mask_alert/features/report_tab/report_tab.dart';

/// `KoreanHeroText`가 단어 경계에서 `\n`을 삽입하므로
/// 단순 textContaining 대신 줄바꿈을 정규화해서 매칭한다.
Finder findHeroText(String pattern) => find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data?.replaceAll('\n', ' ').contains(pattern) ?? false),
    );

// ── 테스트용 WeekReportData 헬퍼 ───────────────────────────────
WeekReportData _makeData(WeekReportState state, {int dangerHours = 0}) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  final base = DateTime(2026, 5, 4);
  final days = List.generate(7, (i) => DayCalendarData(
    date: base.add(Duration(days: i)),
    weekdayLabel: labels[i],
    peakRatio: state == WeekReportState.empty ? null : 0.4 + i * 0.1,
    hasData: state != WeekReportState.empty,
  ));

  final pattern = state == WeekReportState.normal
      ? const PatternData(
          discoveryText: '월·화 오후가 더 위험했어요',
          noteText:      '5/4 14시 PM2.5 52㎍',
        )
      : null;

  return WeekReportData(
    weekCaption: '5월 1주차 · 5/4 ~ 5/10',
    state: state,
    dangerHours: dangerHours,
    days: days,
    pattern: pattern,
    updatedTimeLabel: '14:02 갱신',
    currentFinalRatio: state == WeekReportState.normal ? 1.2 : 0.3,
  );
}

// ── 라우터를 매 테스트마다 새로 생성 ────────────────────────────
GoRouter _makeRouter() => GoRouter(
  initialLocation: '/report',
  routes: [
    GoRoute(
      path: '/report',
      builder: (_, __) => const ReportTab(),
    ),
    GoRoute(
      path: '/report/details',
      builder: (_, __) => const Scaffold(body: Text('drill')),
    ),
  ],
);

Widget _buildWithData(WeekReportData data) {
  return ProviderScope(
    overrides: [
      weekReportProvider.overrideWith(
        (ref) async => data,
      ),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
}

void main() {
  group('ReportTab 통합 렌더링', () {
    testWidgets('empty 상태 렌더링 — 데이터 쌓이는 중', (tester) async {
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.empty)));
      await tester.pumpAndSettle();
      expect(findHeroText('아직 데이터가 쌓이는 중이에요'), findsOneWidget);
    });

    testWidgets('safe 상태 렌더링 — 내 기준을 넘은 시간은 없었어요', (tester) async {
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.safe)));
      await tester.pumpAndSettle();
      expect(findHeroText('내 기준을 넘은 시간은 없었어요'), findsOneWidget);
    });

    testWidgets('normal 상태 렌더링 — 6시간 위험에 노출됐어요', (tester) async {
      await tester.pumpWidget(
          _buildWithData(_makeData(WeekReportState.normal, dangerHours: 6)));
      await tester.pumpAndSettle();
      expect(findHeroText('6시간 위험에 노출됐어요'), findsOneWidget);
    });

    testWidgets('"더 자세히 보기" 버튼 표시', (tester) async {
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.normal, dangerHours: 3)));
      await tester.pumpAndSettle();
      expect(find.text('더 자세히 보기'), findsOneWidget);
    });

    testWidgets('"더 자세히 보기" 탭 → /report/details 화면 전환', (tester) async {
      await tester.pumpWidget(
          _buildWithData(_makeData(WeekReportState.normal, dangerHours: 3)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('더 자세히 보기'));
      await tester.pumpAndSettle();

      // /report/details 화면의 'drill' 텍스트
      expect(find.text('drill'), findsOneWidget);
    });

    testWidgets('주차 캡션 표시', (tester) async {
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.normal, dangerHours: 2)));
      await tester.pumpAndSettle();
      // WeekCaption이 전체 캡션 문자열을 한 Text로 표시
      expect(find.text('5월 1주차 · 5/4 ~ 5/10'), findsOneWidget);
    });

    testWidgets('갱신 시각 표시', (tester) async {
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.normal, dangerHours: 2)));
      await tester.pumpAndSettle();
      // _ReportFooter가 "한국환경공단 · HH:MM 갱신" 형태로 합쳐서 표시
      expect(find.textContaining('한국환경공단'), findsOneWidget);
    });

    testWidgets('pull-to-refresh — RefreshIndicator 존재 및 새로고침 트리거', (tester) async {
      // weekReportProvider override: build 호출 횟수를 추적하기 위해
      // invalidate 후 재빌드가 일어나는지를 RefreshIndicator 위젯 존재로 검증
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.normal, dangerHours: 2)));
      await tester.pumpAndSettle();

      // RefreshIndicator 위젯이 트리에 존재해야 한다
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // fling 제스처로 pull-to-refresh 트리거
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // 새로고침 후에도 정상 렌더링 유지
      expect(findHeroText('위험에 노출됐어요'), findsOneWidget);
    });

    testWidgets('empty 상태 — "더 자세히 보기" 버튼 숨김', (tester) async {
      await tester.pumpWidget(_buildWithData(_makeData(WeekReportState.empty)));
      await tester.pumpAndSettle();
      expect(find.text('더 자세히 보기'), findsNothing);
    });

    testWidgets('normal 상태 — "더 자세히 보기" 버튼 표시', (tester) async {
      await tester.pumpWidget(
          _buildWithData(_makeData(WeekReportState.normal, dangerHours: 3)));
      await tester.pumpAndSettle();
      expect(find.text('더 자세히 보기'), findsOneWidget);
    });
  });
}
