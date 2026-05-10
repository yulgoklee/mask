import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/welcome_screen.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  bool _tutorialCompleted = false;

  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
        nickname: '테스트',
        birthYear: 1990,
        gender: 'female',
        asthma: false,
        rhinitis: false,
        copd: false,
        allergy: false,
        hypertension: false,
        heartDisease: false,
        stroke: false,
        smokingStatus: SmokingStatus.never,
      );

  @override
  Future<void> saveProfile(UserProfile p) async {}

  @override
  Future<NotificationSetting> loadNotificationSetting() async =>
      const NotificationSetting();

  @override
  Future<void> saveNotificationSetting(NotificationSetting s) async {}

  @override
  Future<bool> isOnboardingCompleted() async => false;

  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<void> resetOnboarding() async {}

  @override
  Future<bool> isTutorialSeen() async => _tutorialCompleted;

  @override
  Future<void> completeTutorial() async {
    _tutorialCompleted = true;
  }
}

// ── 라우터 + 헬퍼 ───────────────────────────────────────────────

late SharedPreferences _prefs;
final _fakeRepo = _FakeProfileRepo();

Widget _buildApp() {
  final router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const Scaffold(body: Text('onboarding')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => _fakeRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('a: WelcomeScreen 초기 렌더링 — 페이지 1 표시', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    // 사이클 #15: P1 "사람마다 호흡이 달라요"
    expect(find.textContaining('사람마다'), findsWidgets);
    expect(find.textContaining('호흡이 달라요'), findsWidgets);
  });

  testWidgets('b: 페이지 1에서 "다음 →" 버튼 표시, "시작할게요" 없음', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('다음 →'), findsOneWidget);
    expect(find.text('시작할게요'), findsNothing);
  });

  testWidgets('c: "다음 →" 탭 → 페이지 2 표시 (흐름 설명)', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('다음 →'));
    await tester.pumpAndSettle();

    // 사이클 #15: P2 "이렇게 진행돼요"
    expect(find.text('이렇게 진행돼요'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
  });

  testWidgets('d: 페이지 2에서 "시작할게요" 버튼 표시', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    // 페이지 1 → 2
    await tester.tap(find.text('다음 →'));
    await tester.pumpAndSettle();

    expect(find.text('시작할게요'), findsOneWidget);
    expect(find.text('다음 →'), findsNothing);
  });

  testWidgets('e: "시작할게요" 탭 → /onboarding 이동', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    // 페이지 1 → 2
    await tester.tap(find.text('다음 →'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작할게요'));
    await tester.pumpAndSettle();

    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('f: 도트 인디케이터 2개 표시', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 200));

    // _DotIndicator는 List.generate(2, ...) → AnimatedContainer 2개로 렌더링
    final dotFinder = find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          w.duration == const Duration(milliseconds: 200) &&
          (w.constraints?.maxWidth == 6.0 || w.constraints?.maxWidth == 20.0),
    );
    expect(dotFinder, findsNWidgets(2));
  });
}
