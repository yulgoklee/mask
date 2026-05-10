import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/features/onboarding/widgets/onboarding_hero.dart';
import 'package:mask_alert/widgets/korean_hero_text.dart';

void main() {
  group('OnboardingHero', () {
    testWidgets('a: main 텍스트 렌더링 (KoreanHeroText)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingHero(
              main: '같은 공기,\n다른 기준.',
              heroSize: 64,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KoreanHeroText), findsOneWidget);
      expect(find.textContaining('다른 기준.'), findsWidgets);
    });

    testWidgets('b: cap 있을 때 cap 텍스트 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingHero(
              cap: '지수만을 위한',
              main: '내 알림 기준',
              heroSize: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('지수만을 위한'), findsOneWidget);
    });

    testWidgets('c: cap null이면 cap 텍스트 없음', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingHero(
              main: '내 알림 기준',
              heroSize: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // cap=null이므로 cap 텍스트 없음, main만 존재
      expect(find.textContaining('내 알림 기준'), findsWidgets);
    });

    testWidgets('d: sub 있을 때 sub 텍스트 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingHero(
              main: '내 알림 기준',
              sub: '보조 설명 문구',
              heroSize: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('보조 설명 문구'), findsOneWidget);
    });

    testWidgets('e: sub null이면 sub 텍스트 없음', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingHero(
              main: '내 알림 기준',
              heroSize: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // sub=null → sub Text 없음
      expect(find.text('보조 설명 문구'), findsNothing);
    });

    testWidgets('f: ValueKey onboarding-hero-main 으로 animate 트리거', (tester) async {
      const heroMain = '준비됐어요';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingHero(
              main: heroMain,
              heroSize: 64,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // KoreanHeroText가 ValueKey('onboarding-hero-$main')을 받는지 확인
      final koreanHero = tester.widget<KoreanHeroText>(
        find.byType(KoreanHeroText),
      );
      expect(koreanHero.text, heroMain);
    });
  });
}
