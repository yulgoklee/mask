/// TrendLine 위젯 테스트 — 리포트 탭 단계 3
///
/// §6 단계 3 + §8 테스트 매트릭스 기준으로 작성.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/providers/report_providers.dart';
import 'package:mask_alert/features/report_tab/widgets/trend_line.dart';

// ── 헬퍼 ─────────────────────────────────────────────────

Widget _buildWidget({TrendData? data}) {
  return ProviderScope(
    overrides: [
      trendProvider.overrideWith((_) async => data),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: TrendLine(),
      ),
    ),
  );
}

// ── 테스트 ────────────────────────────────────────────────

void main() {
  // ── A: TrendData null → SizedBox.shrink ─────────────

  group('A: TrendData null — 슬롯 미렌더링', () {
    testWidgets('null이면 텍스트 없음', (tester) async {
      await tester.pumpWidget(_buildWidget(data: null));
      await tester.pump();

      // 추세 카피가 없어야 함
      expect(find.textContaining('지난주'), findsNothing);
    });

    testWidgets('null이면 Padding(추세 줄) 렌더링 안 됨', (tester) async {
      await tester.pumpWidget(_buildWidget(data: null));
      await tester.pump();

      // 이모지 텍스트 없음
      expect(find.textContaining('🌿'), findsNothing);
      expect(find.textContaining('🌱'), findsNothing);
      expect(find.textContaining('➡️'), findsNothing);
      expect(find.textContaining('⚠️'), findsNothing);
      expect(find.textContaining('🌫️'), findsNothing);
    });
  });

  // ── B: TrendCategory별 이모지·카피 5케이스 ───────────

  group('B: TrendCategory 이모지·카피 매트릭스', () {
    testWidgets('muchBetter → 🌿 + "지난주보다 많이 깨끗했어요"', (tester) async {
      const data = TrendData(category: TrendCategory.muchBetter, delta: -0.4);
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.textContaining('🌿'), findsOneWidget);
      expect(find.textContaining('지난주보다 많이 깨끗했어요'), findsOneWidget);
    });

    testWidgets('slightlyBetter → 🌱 + "지난주보다 조금 깨끗했어요"', (tester) async {
      const data = TrendData(category: TrendCategory.slightlyBetter, delta: -0.2);
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.textContaining('🌱'), findsOneWidget);
      expect(find.textContaining('지난주보다 조금 깨끗했어요'), findsOneWidget);
    });

    testWidgets('similar → ➡️ + "지난주와 비슷한 한 주였어요"', (tester) async {
      const data = TrendData(category: TrendCategory.similar, delta: 0.05);
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.textContaining('➡️'), findsOneWidget);
      expect(find.textContaining('지난주와 비슷한 한 주였어요'), findsOneWidget);
    });

    testWidgets('slightlyWorse → ⚠️ + "지난주보다 조금 안 좋았어요"', (tester) async {
      const data = TrendData(category: TrendCategory.slightlyWorse, delta: 0.2);
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.textContaining('⚠️'), findsOneWidget);
      expect(find.textContaining('지난주보다 조금 안 좋았어요'), findsOneWidget);
    });

    testWidgets('muchWorse → 🌫️ + "지난주보다 많이 안 좋았어요"', (tester) async {
      const data = TrendData(category: TrendCategory.muchWorse, delta: 0.4);
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.textContaining('🌫️'), findsOneWidget);
      expect(find.textContaining('지난주보다 많이 안 좋았어요'), findsOneWidget);
    });
  });

  // ── C: Loading / Error 상태 ──────────────────────────

  group('C: Loading / Error 상태', () {
    testWidgets('Loading 중 → 텍스트 미표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trendProvider.overrideWith(
                (_) => Future.delayed(
                  const Duration(hours: 1),
                  () => null,
                ),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: TrendLine()),
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('지난주'), findsNothing);
      });
    });

    testWidgets('Error → 텍스트 미표시', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trendProvider.overrideWith(
              (_) => Future<TrendData?>.error('error'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: TrendLine()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('지난주'), findsNothing);
    });
  });
}
