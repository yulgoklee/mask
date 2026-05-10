import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/settings/transparency/disclaimer_screen.dart';

Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/settings/transparency/disclaimer',
    routes: [
      GoRoute(
        path: '/settings/transparency/disclaimer',
        builder: (_, __) => const TransparencyDisclaimerScreen(),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  testWidgets('a: TransparencyDisclaimerScreen 렌더링', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.byType(TransparencyDisclaimerScreen), findsOneWidget);
  });

  testWidgets('b: 헤더 타이틀 "의료도구 면책" 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('의료도구 면책'), findsOneWidget);
  });

  testWidgets('c: "이 앱은 의료기기가 아니에요." 타이틀 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.textContaining('의료기기가 아니에요'), findsOneWidget);
  });

  testWidgets('d: "이 앱이 하는 것" / "이 앱이 하지 않는 것" 라벨 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('이 앱이 하는 것'), findsOneWidget);
    expect(find.text('이 앱이 하지 않는 것'), findsOneWidget);
  });

  testWidgets('e: "이 앱이 하지 않는 것" bullet 3개 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('질환을 진단하거나 치료를 권고하지 않아요.'), findsOneWidget);
    expect(find.text('의료 전문가의 판단을 대체하지 않아요.'), findsOneWidget);
    expect(find.text('응급 상황에 대응하는 기능이 없어요.'), findsOneWidget);
  });

  testWidgets('f: 강조 박스 (호흡 곤란) 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.textContaining('호흡 곤란'), findsOneWidget);
  });
}
