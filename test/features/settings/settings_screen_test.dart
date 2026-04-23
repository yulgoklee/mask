import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/settings/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 단순 래핑 (GoRouter 없음 — 렌더링 전용)
Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

// GoRouter 래핑 — 네비게이션 테스트용
Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const Scaffold(body: Text('알림 설정 화면')),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'mask_alert',
      packageName: 'com.example.mask_alert',
      version: '1.0.5',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  // ── a. AppBar 타이틀 ──────────────────────────────────────

  testWidgets('a: AppBar 타이틀 "설정" 표시', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('설정'), findsOneWidget);
  });

  // ── b. 섹션 헤더 ─────────────────────────────────────────

  testWidgets('b: 3개 섹션 헤더 표시 (알림, 진단, 앱 정보)', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('진단'), findsOneWidget);
    expect(find.text('앱 정보'), findsOneWidget);
  });

  // ── c. 항목 표시 ─────────────────────────────────────────

  testWidgets('c: 5개 항목 모두 표시', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump(); // initState 동기 부분
    await tester.pump(); // PackageInfo future 완료

    expect(find.text('알림 설정'), findsOneWidget);
    expect(find.text('재진단 받기'), findsOneWidget);
    expect(find.text('버전 정보'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('오픈소스 라이선스'), findsOneWidget);
  });

  testWidgets('c: 버전 정보 값 "1.0.5 (7)" 표시', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();
    await tester.pump();

    expect(find.text('1.0.5 (7)'), findsOneWidget);
  });

  // ── d. onTap 연결 확인 (chevron 존재 = onTap non-null) ──

  testWidgets('d: 재진단 받기 chevron 표시 → onTap 연결됨', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    // 재진단 행의 chevron 확인 — onTap이 연결되어야 chevron이 표시됨
    final diagnosisRow = find.ancestor(
      of: find.text('재진단 받기'),
      matching: find.byType(InkWell),
    );
    expect(diagnosisRow, findsOneWidget);
    final inkWell = tester.widget<InkWell>(diagnosisRow);
    expect(inkWell.onTap, isNotNull);
  });

  testWidgets('d: 개인정보처리방침 탭해도 에러 발생 안 함', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    await tester.tap(find.text('개인정보처리방침'));
    await tester.pump();
  });

  testWidgets('d: 오픈소스 라이선스 탭해도 에러 발생 안 함', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pump();
  });

  // ── e. 라우트 '/settings' 직접 접근 ─────────────────────

  testWidgets('e: 라우트 /settings 직접 접근 시 SettingsScreen 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });

  // ── f. 네비게이션 검증 ───────────────────────────────────

  testWidgets('f: 알림 설정 탭 → /notifications 화면으로 이동', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.text('알림 설정'));
    await tester.pumpAndSettle();

    expect(find.text('알림 설정 화면'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

}
