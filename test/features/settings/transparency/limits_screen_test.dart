import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/settings/transparency/limits_screen.dart';

Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/settings/transparency/limits',
    routes: [
      GoRoute(
        path: '/settings/transparency/limits',
        builder: (_, __) => const LimitsScreen(),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  testWidgets('a: LimitsScreen 렌더링', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.byType(LimitsScreen), findsOneWidget);
  });

  testWidgets('b: 헤더 타이틀 "한계와 책임" 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('한계와 책임'), findsOneWidget);
  });

  testWidgets('c: LimitItem 4개 제목 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    expect(find.text('측정소 위치의 한계'), findsOneWidget);
    expect(find.text('기상 조건의 변동성'), findsOneWidget);
    expect(find.text('개인 민감도의 다양성'), findsOneWidget);
    expect(find.text('의료 판단의 근거가 아님'), findsOneWidget);
  });

  testWidgets('d: 리드 텍스트 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(
      find.textContaining('에어코리아 공개 데이터'),
      findsOneWidget,
    );
  });
}
