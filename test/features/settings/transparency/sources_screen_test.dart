import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/settings/transparency/sources_screen.dart';

Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/settings/transparency/sources',
    routes: [
      GoRoute(
        path: '/settings/transparency/sources',
        builder: (_, __) => const SourcesScreen(),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  testWidgets('a: SourcesScreen 렌더링', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.byType(SourcesScreen), findsOneWidget);
  });

  testWidgets('b: 헤더 타이틀 "참고 자료" 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('참고 자료'), findsOneWidget);
  });

  testWidgets('c: WHO 자료 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('WHO — 대기오염 가이드라인 2021'), findsOneWidget);
  });

  testWidgets('c: 에어코리아 자료 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.text('에어코리아 (한국환경공단)'), findsOneWidget);
  });

  testWidgets('d: 그룹 라벨 3개 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    expect(find.text('1차 자료'), findsOneWidget);
    expect(find.text('임상 가이드라인'), findsOneWidget);
    expect(find.text('데이터 출처'), findsOneWidget);
  });

  testWidgets('e: open_in_new 아이콘이 하나 이상 표시됨', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.open_in_new), findsWidgets);
  });

  testWidgets('f: footer "외부 사이트로 이동해요" 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('외부 사이트로 이동해요. 영어 자료 포함.'),
      200,
    );
    expect(find.text('외부 사이트로 이동해요. 영어 자료 포함.'), findsOneWidget);
  });
}
