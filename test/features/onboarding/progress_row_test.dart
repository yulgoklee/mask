import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/onboarding/onboarding_screen.dart';

Widget _buildRow({
  required int currentPage,
  int totalPages = 6,
  String stageName = '기본정보',
}) {
  return MaterialApp(
    home: Scaffold(
      body: OnboardingProgressRow(
        currentPage: currentPage,
        totalPages: totalPages,
        stageName: stageName,
        onBack: () {},
        onSkip: () {},
      ),
    ),
  );
}

void main() {
  group('OnboardingProgressRow — 건너뛰기 버튼 조건부 표시', () {
    testWidgets('기본정보 (page=0): 건너뛰기 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 0, stageName: '기본정보'));
      expect(find.text('(선택 항목) 건너뛰기'), findsNothing);
    });

    testWidgets('호흡기 (page=1): 건너뛰기 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 1, stageName: '호흡기'));
      expect(find.text('(선택 항목) 건너뛰기'), findsOneWidget);
    });

    testWidgets('심혈관 (page=2): 건너뛰기 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 2, stageName: '심혈관'));
      expect(find.text('(선택 항목) 건너뛰기'), findsOneWidget);
    });

    testWidgets('흡연 (page=3): 건너뛰기 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 3, stageName: '흡연'));
      expect(find.text('(선택 항목) 건너뛰기'), findsOneWidget);
    });
  });

  group('OnboardingProgressRow — 단계명 표시', () {
    testWidgets('기본정보 (page=0): "기본정보" 라벨 표시', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 0, stageName: '기본정보'));
      expect(find.text('기본정보'), findsOneWidget);
    });

    testWidgets('호흡기 (page=1): "호흡기" 라벨 표시', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 1, stageName: '호흡기'));
      expect(find.text('호흡기'), findsOneWidget);
    });

    testWidgets('심혈관 (page=2): "심혈관" 라벨 표시', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 2, stageName: '심혈관'));
      expect(find.text('심혈관'), findsOneWidget);
    });

    testWidgets('흡연 (page=3): "흡연" 라벨 표시', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 3, stageName: '흡연'));
      expect(find.text('흡연'), findsOneWidget);
    });
  });

  group('OnboardingProgressRow — 뒤로 버튼 조건부 표시', () {
    testWidgets('기본정보 (page=0): 뒤로 버튼 보이지 않음', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 0, stageName: '기본정보'));
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('호흡기 (page=1): 뒤로 버튼 보임', (tester) async {
      await tester.pumpWidget(_buildRow(currentPage: 1, stageName: '호흡기'));
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });
}
