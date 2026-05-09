import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/design_tokens.dart';
import 'package:mask_alert/features/profile/widgets/profile_background.dart';

void main() {
  group('ProfileBackground.levelFromSum', () {
    test('sum < 0.20 → safe', () {
      expect(
        ProfileBackground.levelFromSum(0.0),
        ProfileSensitivityLevel.safe,
      );
      expect(
        ProfileBackground.levelFromSum(0.19),
        ProfileSensitivityLevel.safe,
      );
    });

    test('sum == 0.20 → caution', () {
      expect(
        ProfileBackground.levelFromSum(0.20),
        ProfileSensitivityLevel.caution,
      );
    });

    test('sum > 0.20 → caution', () {
      expect(
        ProfileBackground.levelFromSum(0.30),
        ProfileSensitivityLevel.caution,
      );
      expect(
        ProfileBackground.levelFromSum(0.55),
        ProfileSensitivityLevel.caution,
      );
    });
  });

  group('ProfileBackground.accentColor', () {
    test('safe → DT.safe', () {
      expect(
        ProfileBackground.accentColor(ProfileSensitivityLevel.safe),
        DT.safe,
      );
    });

    test('caution → DT.caution', () {
      expect(
        ProfileBackground.accentColor(ProfileSensitivityLevel.caution),
        DT.caution,
      );
    });
  });

  group('ProfileBackground 위젯', () {
    testWidgets('AnimatedContainer 포함 — child 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileBackground(
            level: ProfileSensitivityLevel.safe,
            child: Text('hello'),
          ),
        ),
      );
      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('safe 레벨 — 그라디언트 색 E0F0E8 포함', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileBackground(
            level: ProfileSensitivityLevel.safe,
            child: SizedBox(),
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, const Color(0xFFE0F0E8));
    });

    testWidgets('caution 레벨 — 그라디언트 색 FDEDC4 포함', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileBackground(
            level: ProfileSensitivityLevel.caution,
            child: SizedBox(),
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, const Color(0xFFFDEDC4));
    });
  });
}
