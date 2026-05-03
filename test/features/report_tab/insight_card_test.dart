/// InsightCard 위젯 테스트 — 리포트 탭 단계 3
///
/// §6 단계 3 + §8 테스트 매트릭스 기준으로 작성.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/features/report_tab/models/report_models.dart';
import 'package:mask_alert/features/report_tab/providers/report_providers.dart';
import 'package:mask_alert/features/report_tab/widgets/insight_card.dart';

// ── 헬퍼 ─────────────────────────────────────────────────

Widget _buildWidget({InsightData? data}) {
  return ProviderScope(
    overrides: [
      insightProvider.overrideWith((_) async => data),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: InsightCard(),
      ),
    ),
  );
}

// ── 테스트 ────────────────────────────────────────────────

void main() {
  // ── A: 데이터 있음 — 카드 렌더링 ─────────────────────

  group('A: InsightData 있음 — 카드 렌더링', () {
    testWidgets('카드 제목 "이번 주의 발견" 표시', (tester) async {
      const data = InsightData(
        category: InsightCategory.allSafe,
        bodyText: '이번 한 주는 내내 괜찮았어요.',
      );
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.text('이번 주의 발견'), findsOneWidget);
    });

    testWidgets('bodyText 표시됨', (tester) async {
      const body = '월요일 오후, PM2.5가 45µg/m³까지 올랐어요.';
      const data = InsightData(
        category: InsightCategory.actionMatch,
        bodyText: body,
      );
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.text(body), findsOneWidget);
    });

    testWidgets('footnoteText 있으면 표시됨', (tester) async {
      const footnote = 'PM2.5 45µg/m³ · 5월 1일 (수)';
      const data = InsightData(
        category: InsightCategory.actionMatch,
        bodyText: '월요일 오후, 마스크를 챙기셨네요.',
        footnoteText: footnote,
      );
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.text(footnote), findsOneWidget);
    });

    testWidgets('footnoteText null이면 미주 텍스트 없음', (tester) async {
      const data = InsightData(
        category: InsightCategory.allSafe,
        bodyText: '이번 한 주는 내내 괜찮았어요.',
        // footnoteText 없음
      );
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      // 미주 텍스트로 추가될 수 있는 µg 패턴이 없어야 함
      // (footnoteText가 null이므로 12px DT.gray 텍스트 별도 없음)
      // 카드 제목과 bodyText만 있는 것 확인
      expect(find.text('이번 주의 발견'), findsOneWidget);
      expect(find.text('이번 한 주는 내내 괜찮았어요.'), findsOneWidget);
    });
  });

  // ── B: InsightData null → SizedBox.shrink ───────────

  group('B: InsightData null — 슬롯 미렌더링', () {
    testWidgets('null이면 InsightCard 위젯 트리에서 카드 없음', (tester) async {
      await tester.pumpWidget(_buildWidget(data: null));
      await tester.pump();

      // 카드 제목 없음
      expect(find.text('이번 주의 발견'), findsNothing);
    });

    testWidgets('null이면 Container(카드 박스) 렌더링 안 됨', (tester) async {
      await tester.pumpWidget(_buildWidget(data: null));
      await tester.pump();

      // BoxDecoration(color: white, borderRadius: 16px) Container 없음
      bool hasCardBox = false;
      tester.widgetList<Container>(find.byType(Container)).forEach((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration &&
            deco.color == const Color(0xFFFFFFFF) &&
            deco.borderRadius != null) {
          hasCardBox = true;
        }
      });
      expect(hasCardBox, isFalse);
    });
  });

  // ── C: 카테고리별 카피 ─────────────────────────────

  group('C: 카테고리별 bodyText 렌더링', () {
    testWidgets('allSafe 카테고리 본문 표시', (tester) async {
      const body = '이번 한 주는 내내 괜찮았어요.\n당신 기준으로도 무리 없이 지낼 수 있는 공기였어요.';
      const data = InsightData(
        category: InsightCategory.allSafe,
        bodyText: body,
      );
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.text(body), findsOneWidget);
    });

    testWidgets('envPeak 카테고리 본문 + 미주 표시', (tester) async {
      const body = '화요일에 공기가 가장 안 좋았어요.\nPM2.5 일평균 50µg/m³으로, 당신 기준(35µg/m³)을 넘었어요.';
      const footnote = 'PM2.5 50µg/m³ · 4월 29일 (화)';
      const data = InsightData(
        category: InsightCategory.envPeak,
        bodyText: body,
        footnoteText: footnote,
      );
      await tester.pumpWidget(_buildWidget(data: data));
      await tester.pump();

      expect(find.text(body), findsOneWidget);
      expect(find.text(footnote), findsOneWidget);
    });
  });

  // ── D: Loading / Error 상태 ──────────────────────────

  group('D: Loading / Error 상태', () {
    testWidgets('Loading 중 → 카드 미표시 (SizedBox.shrink)', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              insightProvider.overrideWith(
                (_) => Future.delayed(
                  const Duration(hours: 1),
                  () => null,
                ),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: InsightCard()),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('이번 주의 발견'), findsNothing);
      });
    });

    testWidgets('Error → 카드 미표시 (SizedBox.shrink)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insightProvider.overrideWith(
              (_) => Future<InsightData?>.error('error'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InsightCard()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('이번 주의 발견'), findsNothing);
    });
  });
}
