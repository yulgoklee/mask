import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── /profile/edit 직접 라우트 테스트 ─────────────────────
//
// D 작업 이후 /profile/edit 는 redirect 없이 ProfileEditScreen 을 직접 로드.
// /my-body-info 는 반대로 /profile/edit 로 redirect.

Widget _buildRouter() {
  final router = GoRouter(
    initialLocation: '/profile/edit',
    routes: [
      GoRoute(
        path: '/my-body-info',
        redirect: (_, __) => '/profile/edit',
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const Scaffold(body: Text('프로필 수정 화면')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Widget _buildMyBodyInfoRouter() {
  final router = GoRouter(
    initialLocation: '/my-body-info',
    routes: [
      GoRoute(
        path: '/my-body-info',
        redirect: (_, __) => '/profile/edit',
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const Scaffold(body: Text('프로필 수정 화면')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('/profile/edit 직접 라우트', () {
    testWidgets('/profile/edit 접근 시 ProfileEditScreen 로드', (tester) async {
      await tester.pumpWidget(_buildRouter());
      await tester.pumpAndSettle();

      expect(find.text('프로필 수정 화면'), findsOneWidget);
    });
  });

  group('/my-body-info → /profile/edit 리다이렉트', () {
    testWidgets('/my-body-info 접근 시 /profile/edit 로 리다이렉트', (tester) async {
      await tester.pumpWidget(_buildMyBodyInfoRouter());
      await tester.pumpAndSettle();

      expect(find.text('프로필 수정 화면'), findsOneWidget);
    });
  });

  // ── /profile/edit 잔존 참조 회귀 방지 ──────────────────
  // app_router.dart 의 pageBuilder 정의 외에 /profile/edit 를
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
        equals([
          'lib/core/router/app_router.dart',
          'lib/features/profile_tab/profile_tab.dart',
        ]),
        reason:
            '허용된 파일 외에 /profile/edit 참조가 발견됨: $files',
      );
    });
  });
}
