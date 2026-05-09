import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/widgets/pattern_line.dart';

void main() {
  group('PatternLine 위젯', () {
    testWidgets('pattern=null → SizedBox.shrink (크기 없음)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PatternLine(pattern: null))),
      );
      // SizedBox.shrink는 크기 0이므로 텍스트가 전혀 없어야 함
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('discoveryText 표시', (tester) async {
      const pattern = PatternData(
        discoveryText: '월·화 오후가 더 위험했어요',
        noteText:      '5/4 14시 PM2.5 52㎍',
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PatternLine(pattern: pattern))),
      );
      expect(find.text('월·화 오후가 더 위험했어요'), findsOneWidget);
    });

    testWidgets('noteText 표시', (tester) async {
      const pattern = PatternData(
        discoveryText: '월·화 오후가 더 위험했어요',
        noteText:      '5/4 14시 PM2.5 52㎍',
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PatternLine(pattern: pattern))),
      );
      expect(find.text('5/4 14시 PM2.5 52㎍'), findsOneWidget);
    });
  });
}
