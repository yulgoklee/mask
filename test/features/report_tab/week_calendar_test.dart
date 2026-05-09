import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/widgets/week_calendar.dart';

void main() {
  // 테스트용 7일 데이터 헬퍼
  List<DayCalendarData> makeDays({bool allHasData = true, List<double?>? ratios}) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final base = DateTime(2026, 5, 4); // 월요일 기준
    return List.generate(7, (i) {
      final ratio = ratios?[i];
      return DayCalendarData(
        date: base.add(Duration(days: i)),
        weekdayLabel: labels[i],
        peakRatio: allHasData ? (ratio ?? 0.4) : (i < 2 ? null : ratio ?? 0.4),
        hasData: allHasData || i >= 2,
      );
    });
  }

  Widget buildWidget(List<DayCalendarData> days) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: WeekCalendar(days: days),
        ),
      ),
    );
  }

  group('WeekCalendar 위젯', () {
    testWidgets('7개 요일 라벨 모두 렌더링', (tester) async {
      await tester.pumpWidget(buildWidget(makeDays()));
      for (final label in ['월', '화', '수', '목', '금', '토', '일']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('hasData=false 셀은 CustomPaint로 렌더링', (tester) async {
      final days = makeDays(allHasData: false, ratios: List.filled(7, null));
      // hasData=false: 처음 2개
      await tester.pumpWidget(buildWidget(days));
      // CustomPainter(_DashedRectPainter)를 사용하는 CustomPaint 위젯 존재해야 함
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ratio 0.10 → 안전 색(0xFFDDEDE3) 반환', (tester) async {
      final color = WeekCalendar.ratioToCalColor(0.10);
      expect(color, const Color(0xFFDDEDE3));
    });

    testWidgets('ratio 0.40 → (0xFFE9F2DE) 반환', (tester) async {
      final color = WeekCalendar.ratioToCalColor(0.40);
      expect(color, const Color(0xFFE9F2DE));
    });

    testWidgets('ratio 0.70 → (0xFFFBEFCD) 반환', (tester) async {
      final color = WeekCalendar.ratioToCalColor(0.70);
      expect(color, const Color(0xFFFBEFCD));
    });

    testWidgets('ratio 0.90 → (0xFFF8E1B5) 반환', (tester) async {
      final color = WeekCalendar.ratioToCalColor(0.90);
      expect(color, const Color(0xFFF8E1B5));
    });

    testWidgets('ratio 1.10 → (0xFFF5C9AE) 반환', (tester) async {
      final color = WeekCalendar.ratioToCalColor(1.10);
      expect(color, const Color(0xFFF5C9AE));
    });

    testWidgets('ratio 1.50 → 위험 색(0xFFEFAE94) 반환', (tester) async {
      final color = WeekCalendar.ratioToCalColor(1.50);
      expect(color, const Color(0xFFEFAE94));
    });
  });
}
