import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/onboarding/onboarding_screen.dart';

Widget _buildRow({
  required int currentPage,
  int totalPages = 9,
}) {
  return MaterialApp(
    home: Scaffold(
      body: OnboardingProgressRow(
        currentPage: currentPage,
        totalPages: totalPages,
        onBack: () {},
        onSkip: () {},
      ),
    ),
  );
}

void main() {
  group('OnboardingProgressRow — 건너뛰기 버튼 조건부 표시', () {
    testWidgets('Q1 (page=0): 건너뛰기 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 0));
      expect(find.text('건너뛰기'), findsNothing);
    });

    testWidgets('Q2 (page=1): 건너뛰기 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 1));
      expect(find.text('건너뛰기'), findsNothing);
    });

    testWidgets('Q3 (page=2): 건너뛰기 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 2));
      expect(find.text('건너뛰기'), findsOneWidget);
    });

    testWidgets('Q4 (page=3): 건너뛰기 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 3));
      expect(find.text('건너뛰기'), findsOneWidget);
    });
  });

  group('OnboardingProgressRow — 카운터 조건부 표시', () {
    testWidgets('Q1 (page=0): 카운터 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 0));
      expect(find.textContaining('/ 9'), findsNothing);
    });

    testWidgets('Q2 (page=1): 카운터 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 1));
      expect(find.textContaining('/ 9'), findsNothing);
    });

    testWidgets('Q3 (page=2): 카운터 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 2));
      expect(find.textContaining('/ 9'), findsNothing);
    });

    testWidgets('Q4 (page=3): 카운터 보임 (4 / 9)', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 3));
      expect(find.text('4 / 9'), findsOneWidget);
    });

    testWidgets('Q5 (page=4): 카운터 보임 (5 / 9)', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 4));
      expect(find.text('5 / 9'), findsOneWidget);
    });
  });

  group('OnboardingProgressRow — 뒤로 버튼 조건부 표시', () {
    testWidgets('Q1 (page=0): 뒤로 버튼 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 0));
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('Q2 (page=1): 뒤로 버튼 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 1));
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });
}
