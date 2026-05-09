import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/widgets/report_hero.dart';

/// `KoreanHeroText`가 단어 경계에서 `\n`을 삽입하므로
/// 단순 textContaining 대신 줄바꿈을 정규화해서 매칭한다.
Finder findHeroText(String pattern) => find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data?.replaceAll('\n', ' ').contains(pattern) ?? false),
    );

void main() {
  group('ReportHero 위젯', () {
    Widget buildWidget(WeekReportState state, int dangerHours) {
      return MaterialApp(
        home: Scaffold(
          body: ReportHero(state: state, dangerHours: dangerHours),
        ),
      );
    }

    testWidgets('empty 상태 — 데이터 쌓이는 중 카피', (tester) async {
      await tester.pumpWidget(buildWidget(WeekReportState.empty, 0));
      expect(findHeroText('아직 데이터가 쌓이는 중이에요'), findsOneWidget);
      expect(find.textContaining('며칠 더 지나면'), findsOneWidget);
    });

    testWidgets('safe 상태 — 내 기준을 넘은 시간은 없었어요', (tester) async {
      await tester.pumpWidget(buildWidget(WeekReportState.safe, 0));
      expect(findHeroText('내 기준을 넘은 시간은 없었어요'), findsOneWidget);
    });

    testWidgets('normal 상태 dangerHours=6 — 6시간 위험에 노출됐어요', (tester) async {
      await tester.pumpWidget(buildWidget(WeekReportState.normal, 6));
      expect(findHeroText('6시간 위험에 노출됐어요'), findsOneWidget);
    });

    testWidgets('normal 상태 dangerHours=3 — 3시간 위험에 노출됐어요', (tester) async {
      await tester.pumpWidget(buildWidget(WeekReportState.normal, 3));
      expect(findHeroText('3시간 위험에 노출됐어요'), findsOneWidget);
    });

    testWidgets('empty 상태는 보조 텍스트 표시, safe/normal은 보조 텍스트 없음',
        (tester) async {
      // safe
      await tester.pumpWidget(buildWidget(WeekReportState.safe, 0));
      expect(find.textContaining('며칠 더 지나면'), findsNothing);

      // normal
      await tester.pumpWidget(buildWidget(WeekReportState.normal, 2));
      expect(find.textContaining('며칠 더 지나면'), findsNothing);
    });
  });
}
