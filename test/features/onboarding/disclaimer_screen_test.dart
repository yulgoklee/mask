import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/core/constants/app_constants.dart';
import 'package:mask_alert/features/onboarding/disclaimer_screen.dart';
import 'package:mask_alert/providers/core_providers.dart';

// ── 헬퍼 ──────────────────────────────────────────────────────

late SharedPreferences _prefs;

Widget _buildApp() {
  final router = GoRouter(
    initialLocation: '/disclaimer',
    routes: [
      GoRoute(
        path: '/disclaimer',
        builder: (_, __) => const DisclaimerScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const Scaffold(body: Text('welcome')),
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

  testWidgets('a: DisclaimerScreen 렌더링 — 3개 항목 표시', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    // 헤드라인 (OnboardingHero, \n 포함 → textContaining)
    expect(find.textContaining('읽어주세요'), findsWidgets);
    // 각 항목 라벨
    expect(find.text('참고 정보'), findsOneWidget);
    expect(find.text('의료진 우선'), findsOneWidget);
    // 사이클 #15: "측정 한계" → "수치가 달라요"
    expect(find.text('수치가 달라요'), findsOneWidget);
    // 각 항목 본문 (일부)
    expect(
      find.textContaining('참고용이에요'),
      findsOneWidget,
    );
    expect(
      find.textContaining('의료진의 안내를 우선'),
      findsOneWidget,
    );
    expect(
      find.textContaining('체감과 다를 수 있어요'),
      findsOneWidget,
    );
    // CTA 버튼
    expect(find.text('확인했습니다'), findsOneWidget);
  });

  testWidgets('b: CTA 탭 → prefDisclaimerAgreedAt 저장 후 /welcome 이동',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    // 동의 전에는 prefs에 없음
    expect(
      _prefs.getString(AppConstants.prefDisclaimerAgreedAt),
      isNull,
    );

    await tester.ensureVisible(find.text('확인했습니다'));
    await tester.tap(find.text('확인했습니다'));
    await tester.pumpAndSettle();

    // prefs 저장 확인
    final savedAt = _prefs.getString(AppConstants.prefDisclaimerAgreedAt);
    expect(savedAt, isNotNull);
    expect(DateTime.tryParse(savedAt!), isNotNull);

    // /welcome 이동 확인
    expect(find.text('welcome'), findsOneWidget);
  });
}
