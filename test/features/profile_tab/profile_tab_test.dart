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
  final NotificationSetting notifSetting;

  _FakeProfileRepo({this.notifSetting = const NotificationSetting()});

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
  Future<NotificationSetting> loadNotificationSetting() async => notifSetting;
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

Widget _buildWithRouter({NotificationSetting? notifSetting}) {
  final repo = _FakeProfileRepo(
    notifSetting: notifSetting ?? const NotificationSetting(),
  );

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
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const Scaffold(body: Text('알림 설정 화면')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) => repo),
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

  // ── c. 카드 1: 페르소나 위젯 렌더링 ───────────────────────

  group('c: 페르소나 카드 렌더링', () {
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

  // ── d. 카드 2: 내 알림 요약 카드 렌더링 ──────────────────

  group('d: 내 알림 요약 카드 렌더링', () {
    testWidgets('"🔔 내 알림" 카드 제목 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('🔔 내 알림'), findsOneWidget);
    });

    testWidgets('"변경 →" 텍스트 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('변경 →'), findsOneWidget);
    });

    testWidgets('알림 카드 탭 → /notifications 화면으로 이동', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      // "🔔 내 알림" 텍스트를 탭
      await tester.tap(find.text('🔔 내 알림'));
      await tester.pumpAndSettle();

      expect(find.text('알림 설정 화면'), findsOneWidget);
    });

    testWidgets('"변경 →" 탭 → /notifications 화면으로 이동', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('변경 →'));
      await tester.pumpAndSettle();

      expect(find.text('알림 설정 화면'), findsOneWidget);
    });
  });

  // ── e. 한 줄 링크: 내 몸 정보 수정 ─────────────────────

  group('e: 내 몸 정보 수정 링크', () {
    testWidgets('"내 몸 정보 수정" 텍스트 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('내 몸 정보 수정'), findsOneWidget);
    });

    testWidgets('chevron_right 아이콘 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('내 몸 정보 수정 탭 → /profile/edit 화면으로 이동', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('내 몸 정보 수정'));
      await tester.pumpAndSettle();

      expect(find.text('프로필 수정 화면'), findsOneWidget);
      expect(find.byType(ProfileTab), findsNothing);
    });
  });

  // ── f. 제거된 항목 확인 ──────────────────────────────────

  group('f: 제거된 항목', () {
    testWidgets('"방해 금지" 섹션 없음 (이동됨)', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      // 방해금지는 알림 설정 화면으로 이동됨
      expect(find.text('방해 금지'), findsNothing);
    });

    testWidgets('"프로필 수정하기" 구 버튼 없음 (→ "내 몸 정보 수정"으로 교체)', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('프로필 수정하기'), findsNothing);
    });
  });
}
