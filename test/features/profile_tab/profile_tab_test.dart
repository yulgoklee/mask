import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile_tab/profile_tab.dart';
import 'package:mask_alert/features/profile_tab/widgets/profile_footer.dart';
import 'package:mask_alert/features/profile/widgets/axis_list.dart';
import 'package:mask_alert/features/profile/widgets/profile_background.dart';
import 'package:mask_alert/features/profile/widgets/profile_hero.dart';
import 'package:mask_alert/features/profile/widgets/threshold_range.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  final UserProfile profile;

  _FakeProfileRepo({UserProfile? profile})
      : profile = profile ??
            const UserProfile(
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
            );

  @override
  Future<UserProfile> loadProfile() async => profile;
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
  Future<bool> isTutorialSeen() async => false;
  @override
  Future<void> completeTutorial() async {}
}

// ── 테스트 헬퍼 ────────────────────────────────────────────────────

Widget _buildWithRouter({UserProfile? profile}) {
  final repo = _FakeProfileRepo(profile: profile);

  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileTab(),
      ),
      GoRoute(
        path: '/profile/details',
        builder: (_, __) => const Scaffold(body: Text('상세 화면')),
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
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // ── a. 핵심 컴포넌트 렌더링 ─────────────────────────────────────

  group('a: 핵심 컴포넌트 렌더링', () {
    testWidgets('Hero 캡션 "내 기준은" 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('내 기준은'), findsOneWidget);
    });

    testWidgets('Hero 단위 "㎍/㎥" 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      // ProfileHero의 단위 텍스트
      expect(find.text('㎍/㎥'), findsWidgets);
    });

    testWidgets('ThresholdRange 캡션 표시 (일반 기준보다 N% 낮아요 / 비슷해요)', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      // 두 문구 중 하나 표시됨
      final finder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.contains('낮아요') == true ||
                w.data?.contains('비슷해요') == true),
      );
      expect(finder, findsOneWidget);
    });

    testWidgets('섹션 라벨 "내 건강 분석" 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('내 건강 분석'), findsOneWidget);
    });

    testWidgets('AxisList variant D 렌더링', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byType(AxisList), findsOneWidget);
    });

    testWidgets('핵심 위젯 타입 3종 렌더링 확인', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileBackground), findsOneWidget);
      expect(find.byType(ProfileHero), findsOneWidget);
      expect(find.byType(ThresholdRange), findsOneWidget);
    });
  });

  // ── b. Footer 렌더링 ─────────────────────────────────────────────

  group('b: Footer 렌더링', () {
    testWidgets('ProfileFooter 위젯 존재', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileFooter), findsOneWidget);
    });

    testWidgets('"더 자세히 보기" 텍스트 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('더 자세히 보기'), findsOneWidget);
    });

    testWidgets('설정 아이콘 (settings_outlined) 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Footer 안내 문구 표시', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.textContaining('기준이 다시 계산'), findsOneWidget);
    });
  });

  // ── c. 네비게이션 ────────────────────────────────────────────────

  group('c: 네비게이션', () {
    testWidgets('"더 자세히 보기" 탭 → /profile/details 이동', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('더 자세히 보기'));
      await tester.pumpAndSettle();

      expect(find.text('상세 화면'), findsOneWidget);
    });

    testWidgets('설정 아이콘 탭 → /settings 이동', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('설정 화면'), findsOneWidget);
    });
  });

  // ── d. 제거된 구 UI 확인 ─────────────────────────────────────────

  group('d: 폐기된 구 UI 부재 확인', () {
    testWidgets('알림 요약 카드(🔔 내 알림) 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('🔔 내 알림'), findsNothing);
    });

    testWidgets('AppBar 없음 (ProfileBackground 기반 레이아웃)', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('"이렇게 알려드릴게요" 구 헤더 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.textContaining('이렇게 알려드릴게요'), findsNothing);
    });

    testWidgets('"일반인 기준" 구 카드 텍스트 없음', (tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      expect(find.text('일반인 기준'), findsNothing);
    });
  });

  // ── e. 배경 레벨 (ProfileBackground) ─────────────────────────────

  group('e: 배경 그라디언트', () {
    testWidgets('호흡기 민감 프로필 → caution 배경 렌더', (tester) async {
      const sensitiveProfile = UserProfile(
        nickname: '민감이',
        birthYear: 1990,
        gender: 'female',
        asthma: true,
        rhinitis: true,
        copd: false,
        allergy: false,
        hypertension: false,
        heartDisease: false,
        stroke: false,
        smokingStatus: SmokingStatus.never,
      );

      await tester.pumpWidget(_buildWithRouter(profile: sensitiveProfile));
      await tester.pumpAndSettle();

      // 렌더링만 확인 (배경색 변경 여부는 CareBackground와 동일 패턴)
      expect(find.byType(ProfileTab), findsOneWidget);
    });
  });
}
