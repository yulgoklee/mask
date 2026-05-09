import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/profile/widgets/profile_hero.dart';

/// KoreanHeroText가 단어 경계에서 \n을 삽입하므로
/// 줄바꿈 정규화해서 매칭한다 (report_hero_test 패턴 재사용).
Finder findHeroText(String pattern) => find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data?.replaceAll('\n', ' ').contains(pattern) ?? false),
    );

Widget buildHero({
  double tFinal = 21.0,
  String sub = '호흡기 민감 그룹이에요',
  String? greeting,
  String? cap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ProfileHero(
        tFinal: tFinal,
        sub: sub,
        greeting: greeting,
        cap: cap,
      ),
    ),
  );
}

void main() {
  group('ProfileHero — greeting', () {
    testWidgets('greeting 있으면 "지수님," 표시', (tester) async {
      await tester.pumpWidget(buildHero(greeting: '지수'));
      expect(find.text('지수,'), findsOneWidget);
    });

    testWidgets('greeting null이면 인사 없음', (tester) async {
      await tester.pumpWidget(buildHero(greeting: null));
      expect(find.textContaining('님'), findsNothing);
    });

    testWidgets('greeting 빈 문자열이면 인사 없음', (tester) async {
      await tester.pumpWidget(buildHero(greeting: ''));
      expect(find.textContaining('님'), findsNothing);
    });
  });

  group('ProfileHero — cap', () {
    testWidgets('cap 있으면 "내 기준은" 표시', (tester) async {
      await tester.pumpWidget(buildHero(cap: '내 기준은'));
      expect(find.text('내 기준은'), findsOneWidget);
    });

    testWidgets('cap null이면 cap 없음', (tester) async {
      await tester.pumpWidget(buildHero(cap: null));
      expect(find.text('내 기준은'), findsNothing);
    });
  });

  group('ProfileHero — 숫자·단위·sub', () {
    testWidgets('tFinal=21 → "21" 텍스트 표시', (tester) async {
      await tester.pumpWidget(buildHero(tFinal: 21.0));
      expect(find.text('21'), findsOneWidget);
    });

    testWidgets('단위 "㎍/㎥" 표시', (tester) async {
      await tester.pumpWidget(buildHero(tFinal: 21.0));
      expect(find.text('㎍/㎥'), findsOneWidget);
    });

    testWidgets('sub KoreanHeroText 로 렌더 — 페르소나 라벨 포함', (tester) async {
      await tester.pumpWidget(buildHero(sub: '호흡기 민감 그룹이에요'));
      expect(findHeroText('호흡기 민감 그룹이에요'), findsOneWidget);
    });

    testWidgets('tFinal=35 → "35" 표시 (일반 기준)', (tester) async {
      await tester.pumpWidget(buildHero(tFinal: 35.0, sub: '일반 그룹이에요'));
      expect(find.text('35'), findsOneWidget);
    });
  });
}
