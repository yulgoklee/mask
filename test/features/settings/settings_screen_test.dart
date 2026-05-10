import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/features/settings/settings_screen.dart';
import 'package:mask_alert/features/settings/widgets/s_cap.dart';
import 'package:mask_alert/features/settings/widgets/s_item.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

Widget _wrapWithRouter() {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notification_time',
        builder: (_, __) => const Scaffold(body: Text('알림 시간 화면')),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const Scaffold(body: Text('온보딩 화면')),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const Scaffold(body: Text('건강 정보 수정')),
      ),
      GoRoute(
        path: '/settings/transparency/sources',
        builder: (_, __) => const Scaffold(body: Text('참고 자료')),
      ),
      GoRoute(
        path: '/settings/transparency/calculation',
        builder: (_, __) => const Scaffold(body: Text('계산 방식')),
      ),
      GoRoute(
        path: '/settings/transparency/limits',
        builder: (_, __) => const Scaffold(body: Text('한계와 책임')),
      ),
      GoRoute(
        path: '/settings/transparency/disclaimer',
        builder: (_, __) => const Scaffold(body: Text('의료도구 면책')),
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

Widget _wrapSimple() {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'mask_alert',
      packageName: 'com.example.mask_alert',
      version: '1.3.0',
      buildNumber: '12',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a. SCap 24pt 헤더 ────────────────────────────────────

  testWidgets('a: SCap "환경 설정" 24pt 헤더 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.byType(SCap), findsOneWidget);
    expect(find.text('환경 설정'), findsOneWidget);

    final text = tester.widget<Text>(
      find.descendant(of: find.byType(SCap), matching: find.byType(Text)),
    );
    expect(text.style?.fontSize, 24);
    expect(text.style?.fontWeight, FontWeight.w700);
  });

  // ── b. 6개 카테고리 라벨 표시 ────────────────────────────

  testWidgets('b: 6개 SLabel 카테고리 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('진단'), findsOneWidget);
    expect(find.text('위치'), findsOneWidget);
    expect(find.text('데이터'), findsOneWidget);
    expect(find.text('투명성'), findsOneWidget);
    expect(find.text('앱 정보'), findsOneWidget);
  });

  // ── c. 핵심 항목 표시 ────────────────────────────────────

  testWidgets('c: 알림 카테고리 항목 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.text('외출 전 알림 시간'), findsOneWidget);
    expect(find.text('전날 예보 알림 시간'), findsOneWidget);
    expect(find.text('귀가 후 알림 시간'), findsOneWidget);
    expect(find.text('실시간 경보'), findsOneWidget);
    expect(find.text('방해 금지 시간'), findsOneWidget);
    expect(find.text('알림 미리 받아보기'), findsOneWidget);
  });

  testWidgets('c: 진단 카테고리 항목 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.text('건강 정보 수정'), findsOneWidget);
    expect(find.text('재진단 받기'), findsOneWidget);
    expect(find.text('결과지 다시 보기'), findsOneWidget);
  });

  testWidgets('c: 투명성 카테고리 항목 4개 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.text('참고 자료·가이드라인'), findsOneWidget);
    expect(find.text('데이터 처리 방식 (T_final)'), findsOneWidget);
    expect(find.text('한계와 책임'), findsOneWidget);
    expect(find.text('의료도구 면책'), findsOneWidget);
  });

  testWidgets('c: 앱 정보 카테고리 항목 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();
    await tester.pump(); // PackageInfo future

    expect(find.text('버전 정보'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('오픈소스 라이선스'), findsOneWidget);
    expect(find.text('도움말'), findsOneWidget);
    expect(find.text('문의'), findsOneWidget);
  });

  testWidgets('c: 버전 표시 "1.3.0 (12)"', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();
    await tester.pump();

    expect(find.text('1.3.0 (12)'), findsOneWidget);
  });

  // ── d. 데이터 내보내기 없음 (yulgok 수정 2) ──────────────

  testWidgets('d: 데이터 내보내기 항목 없음', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.text('데이터 내보내기'), findsNothing);
  });

  testWidgets('d: 알림 기록 보기 항목 없음 (P3 제외)', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.text('알림 기록 보기'), findsNothing);
  });

  // ── e. SItem 개수 확인 ───────────────────────────────────

  testWidgets('e: SItem 위젯이 하나 이상 표시됨', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.byType(SItem), findsWidgets);
  });

  // ── f. 라우터 통합 — /settings 진입 ─────────────────────

  testWidgets('f: /settings 라우트 → SettingsScreen 표시', (tester) async {
    await tester.pumpWidget(_wrapWithRouter());
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('환경 설정'), findsOneWidget);
  });

  // ── g. 카드(BoxDecoration+boxShadow) 없음 ───────────────

  testWidgets('g: Card 위젯 없음', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    expect(find.byType(Card), findsNothing);
  });

  // ── h. Footer 텍스트 표시 ────────────────────────────────

  testWidgets('h: footer "내 몸에 맞는 미세먼지 알림" 표시', (tester) async {
    await tester.pumpWidget(_wrapSimple());
    await tester.pump();

    // SingleChildScrollView 안에 있으므로 스크롤 필요
    await tester.scrollUntilVisible(
      find.text('내 몸에 맞는 미세먼지 알림'),
      200,
    );
    expect(find.text('내 몸에 맞는 미세먼지 알림'), findsOneWidget);
  });
}
