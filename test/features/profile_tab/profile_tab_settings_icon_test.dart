import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/temporary_state.dart';
import 'package:mask_alert/data/models/today_situation.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile_tab/profile_tab.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile = UserProfile(
    nickname: '테스트',
    birthYear: 1990,
    gender: 'male',
    respiratoryStatus: 0,
    sensitivityLevel: 0,
    isPregnant: false,
    recentSkinTreatment: false,
    outdoorMinutes: 0,
    activityTags: const [],
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
  Future<List<TemporaryState>> loadTemporaryStates() async => [];
  @override
  Future<void> saveTemporaryStates(List<TemporaryState> s) async {}
  @override
  Future<List<TodaySituation>> loadTodaySituations() async => [];
  @override
  Future<void> saveTodaySituations(List<TodaySituation> s) async {}
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
        path: '/my-body-info',
        builder: (_, __) => const Scaffold(body: Text('내 몸 정보 화면')),
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

    testWidgets('프로필 타이틀과 같은 Row에 위치', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      final iconFinder = find.byIcon(Icons.settings);
      expect(iconFinder, findsOneWidget);

      final row = find.ancestor(
        of: iconFinder,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: row.first, matching: find.text('프로필')),
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

  // ── c-1. 제거된 항목 확인 ────────────────────────────────

  group('c-1: 제거된 항목', () {
    testWidgets('프로필 탭에 "알림 설정" 버튼 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('알림 설정'), findsNothing);
    });

    testWidgets('프로필 탭에 버전 정보 텍스트 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.textContaining('v1.0'), findsNothing);
    });

    testWidgets('퀵 토글 "감기 중" 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('감기 중'), findsNothing);
    });

    testWidgets('퀵 토글 "피부 시술" 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('피부 시술'), findsNothing);
    });

    testWidgets('퀵 토글 "야외 활동" 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('야외 활동'), findsNothing);
    });
  });

  // ── c. 내 몸 정보 진입점 ────────────────────────────────

  group('c: 내 몸 정보 진입점', () {
    testWidgets('"내 몸 정보" 레이블 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('내 몸 정보'), findsOneWidget);
    });

    testWidgets('"건강 프로필 수정" 레이블 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('건강 프로필 수정'), findsNothing);
    });

    testWidgets('내 몸 정보 탭 → /my-body-info 화면으로 이동', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('내 몸 정보'));
      await tester.pumpAndSettle();

      expect(find.text('내 몸 정보 화면'), findsOneWidget);
      expect(find.byType(ProfileTab), findsNothing);
    });
  });
}
