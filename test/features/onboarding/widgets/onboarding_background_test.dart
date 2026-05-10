import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/features/onboarding/widgets/onboarding_background.dart';

void main() {
  group('OnboardingBackground', () {
    testWidgets('a: DecoratedBox(gradient) 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingBackground(
            child: SizedBox.expand(),
          ),
        ),
      );

      // DecoratedBox가 렌더링되는지 확인
      expect(find.byType(OnboardingBackground), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('b: child 위젯을 그대로 전달', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingBackground(
            child: Text('test-child'),
          ),
        ),
      );

      expect(find.text('test-child'), findsOneWidget);
    });

    testWidgets('c: safe 3-stop 그라디언트 색상 검증', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingBackground(
            child: SizedBox.expand(),
          ),
        ),
      );

      // 위젯 트리 내 DecoratedBox 찾기
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final gradient = (decoratedBox.decoration as BoxDecoration).gradient
          as LinearGradient;

      expect(gradient.colors.length, 3);
      expect(gradient.stops, const [0.0, 0.3, 1.0]);
      // safe 톱 색상
      expect(gradient.colors[0], const Color(0xFFE0F0E8));
      // safe 바텀 색상
      expect(gradient.colors[2], const Color(0xFFF9FAFB));
    });
  });
}
