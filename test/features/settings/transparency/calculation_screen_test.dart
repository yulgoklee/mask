import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/settings/transparency/calculation_screen.dart';
import 'package:mask_alert/features/profile_tab/widgets/waterfall.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/settings/transparency/calculation',
    routes: [
      GoRoute(
        path: '/settings/transparency/calculation',
        builder: (_, __) => const CalculationScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('a: CalculationScreen 렌더링', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.byType(CalculationScreen), findsOneWidget);
  });

  testWidgets('b: 헤더 타이틀 "계산 방식" 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('계산 방식'), findsOneWidget);
  });

  testWidgets('c: "T_final이란?" 타이틀 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('T_final이란?'), findsOneWidget);
  });

  testWidgets('d: Waterfall 위젯 존재', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.byType(Waterfall), findsOneWidget);
  });

  testWidgets('e: "임계치 산정 흐름" 섹션 라벨 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('임계치 산정 흐름'), findsOneWidget);
  });

  testWidgets('f: "PM10 환산" 섹션 라벨 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('PM10 환산'), findsOneWidget);
  });

  testWidgets('g: "최저 기준" 섹션 라벨 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('최저 기준'), findsOneWidget);
  });
}
