import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── /profile/edit → /my-body-info 리다이렉트 테스트 ──────

Widget _buildRouter() {
  final router = GoRouter(
    initialLocation: '/profile/edit',
    routes: [
      GoRoute(
        path: '/profile/edit',
        redirect: (_, __) => '/my-body-info',
      ),
      GoRoute(
        path: '/my-body-info',
        builder: (_, __) => const Scaffold(body: Text('내 몸 정보 화면')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('/profile/edit 리다이렉트', () {
    testWidgets('/profile/edit 접근 시 /my-body-info 로 리다이렉트', (tester) async {
      await tester.pumpWidget(_buildRouter());
      await tester.pumpAndSettle();

      expect(find.text('내 몸 정보 화면'), findsOneWidget);
    });
  });

  // ── /profile/edit 잔존 참조 회귀 방지 ──────────────────
  // app_router.dart 의 redirect 정의 외에 /profile/edit 를
  // 직접 사용하는 코드가 추가되면 CI에서 즉시 감지.

  group('/profile/edit 잔존 참조 방지', () {
    test('app_router.dart 외 lib/ 에 /profile/edit 참조 없음', () async {
      final result = await Process.run(
        'grep',
        ['-r', '-l', '/profile/edit', 'lib/'],
      );
      final files = (result.stdout as String)
          .trim()
          .split('\n')
          .where((f) => f.isNotEmpty)
          .toList()
        ..sort();

      expect(
        files,
        equals(['lib/core/router/app_router.dart']),
        reason: 'app_router.dart 의 redirect 정의 외에 /profile/edit 참조가 발견됨: $files',
      );
    });
  });
}
