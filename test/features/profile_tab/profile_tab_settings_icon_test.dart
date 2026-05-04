import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile_tab/profile_tab.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    nickname: '테스트',
    birthYear: 1990,
    gender: 'male',
    asthma: false,
    rhinitis: false,
    copd: false,
    allergy: false,
    hypertension: false,
    heartDisease: false,
    stroke: false,
    smokingStatus: SmokingStatus.never,
    activityTags: [],
    discomfortLevel: 0,
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(UserProfile p) async => _profile = p;
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
  Future<bool> isTutorialSeen() async => false;
  @override
  Future<void> completeTutorial() async {}
}

// ── 테스트 헬퍼 ───────────────────────────────────────────

void _setTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildWithRouter() {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileTab(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const Scaffold(body: Text('설정 화면')),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const Scaffold(body: Text('프로필 수정 화면')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) => _FakeProfileRepo()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // ── a. 설정 아이콘 렌더링 ──────────────────────────────

  group('a: 설정 아이콘 렌더링', () {
    testWidgets('⚙️ 아이콘 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('프로필 타이틀과 같은 AppBar에 위치', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      final iconFinder = find.byIcon(Icons.settings);
      expect(iconFinder, findsOneWidget);

      final appBar = find.byType(AppBar);
      expect(
        find.descendant(of: appBar, matching: find.text('프로필')),
        findsOneWidget,
      );
    });
  });

  // ── b. /settings 네비게이션 ────────────────────────────

  group('b: /settings 네비게이션', () {
    testWidgets('설정 아이콘 탭 → /settings 화면으로 이동', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('설정 화면'), findsOneWidget);
      expect(find.byType(ProfileTab), findsNothing);
    });
  });

  // ── c. 보기 영역 렌더링 ────────────────────────────────

  group('c: 보기 영역 렌더링', () {
    testWidgets('ThresholdCompareCard 존재 — "일반인 기준" 텍스트', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('일반인 기준'), findsOneWidget);
    });

    testWidgets('SensitivityBreakdown 존재 — "상태 분석" 텍스트', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('상태 분석'), findsOneWidget);
    });

    testWidgets('"이렇게 알려드릴게요." 헤더 텍스트 존재', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.textContaining('이렇게 알려드릴게요'), findsOneWidget);
    });
  });

  // ── d. 프로필 수정 진입점 ────────────────────────────────

  group('d: 프로필 수정 진입점', () {
    testWidgets('"프로필 수정하기" 레이블 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('프로필 수정하기'), findsOneWidget);
    });

    testWidgets('프로필 수정하기 탭 → /profile/edit 화면으로 이동', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('프로필 수정하기'));
      await tester.pumpAndSettle();

      expect(find.text('프로필 수정 화면'), findsOneWidget);
      expect(find.byType(ProfileTab), findsNothing);
    });
  });

  // ── e. 제거된 항목 확인 ────────────────────────────────

  group('e: 제거된 항목', () {
    testWidgets('"알림 설정" 버튼 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('알림 설정'), findsNothing);
    });

    testWidgets('버전 정보 텍스트 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.textContaining('v1.0'), findsNothing);
    });
  });

  // ── f. 현재 상태 섹션 없음 (제거됨) ──────────────────────

  group('f: 현재 상태 섹션 제거 확인', () {
    testWidgets('"현재 상태" 섹션 헤더 없음', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('현재 상태'), findsNothing);
    });

    testWidgets('"방해 금지" 섹션 헤더 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('방해 금지'), findsOneWidget);
    });
  });
}
