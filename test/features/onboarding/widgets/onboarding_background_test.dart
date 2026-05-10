import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/features/onboarding/widgets/onboarding_background.dart';
import 'package:mask_alert/widgets/gradient_background.dart';

void main() {
  group('OnboardingBackground', () {
    testWidgets('a: GradientBackground(animated:false) 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingBackground(
            child: SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(OnboardingBackground), findsOneWidget);
      // animated:false → DecoratedBox 경로
      expect(find.byType(GradientBackground), findsOneWidget);
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

      // GradientBackground(animated:false) → DecoratedBox 경로
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final gradient = (decoratedBox.decoration as BoxDecoration).gradient
          as LinearGradient;

      expect(gradient.colors.length, 3);
      expect(gradient.stops, const [0.0, 0.3, 1.0]);
      // brand 파랑 톱 색상
      expect(gradient.colors[0], const Color(0xFFE8F0FE));
      // 바텀 색상
      expect(gradient.colors[2], const Color(0xFFF9FAFB));
    });
  });
}
