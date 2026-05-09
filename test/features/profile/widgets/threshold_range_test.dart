import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/design_tokens.dart';
import 'package:mask_alert/features/profile/widgets/threshold_range.dart';

Widget buildRange({
  double myThreshold = 21.0,
  double general = 35.0,
  Color? accentColor,
  int max = 100,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ThresholdRange(
        myThreshold: myThreshold,
        general: general,
        accentColor: accentColor ?? DT.safe,
        max: max,
      ),
    ),
  );
}

void main() {
  group('ThresholdRange 캡션 — 퍼센트 동적 계산', () {
    // J-1: ((general - my) / general * 100).round()
    testWidgets('myThreshold=21, general=35 → "40% 낮아요" 캡션', (tester) async {
      await tester.pumpWidget(buildRange(myThreshold: 21, general: 35));
      expect(find.textContaining('40% 낮아요'), findsOneWidget);
    });

    testWidgets('myThreshold=28, general=35 → "20% 낮아요" 캡션', (tester) async {
      await tester.pumpWidget(buildRange(myThreshold: 28, general: 35));
      // ((35-28)/35*100).round() = (7/35*100).round() = 20
      expect(find.textContaining('20% 낮아요'), findsOneWidget);
    });

    testWidgets('myThreshold=35, general=35 → 비슷해요 캡션 (마커 겹침)', (tester) async {
      await tester.pumpWidget(buildRange(myThreshold: 35, general: 35));
      expect(find.textContaining('비슷해요'), findsOneWidget);
      expect(find.textContaining('낮아요'), findsNothing);
    });
  });

  group('ThresholdRange 양 끝 라벨', () {
    testWidgets('"0" 라벨 표시', (tester) async {
      await tester.pumpWidget(buildRange());
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('"100㎍/㎥" 라벨 표시', (tester) async {
      await tester.pumpWidget(buildRange());
      expect(find.text('100㎍/㎥'), findsOneWidget);
    });
  });

  group('ThresholdRange 마커 라벨', () {
    testWidgets('"나 21" 라벨 표시', (tester) async {
      await tester.pumpWidget(buildRange(myThreshold: 21, general: 35));
      expect(find.text('나 21'), findsOneWidget);
    });

    testWidgets('"일반 35" 라벨 표시', (tester) async {
      await tester.pumpWidget(buildRange(myThreshold: 21, general: 35));
      expect(find.text('일반 35'), findsOneWidget);
    });
  });
}
