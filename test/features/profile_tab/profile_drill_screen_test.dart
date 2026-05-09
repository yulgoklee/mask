import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile/widgets/axis_list.dart';
import 'package:mask_alert/features/profile_tab/profile_drill_screen.dart';
import 'package:mask_alert/features/profile_tab/widgets/waterfall.dart';
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

Widget _buildDrillScreen({UserProfile? profile}) {
  final repo = _FakeProfileRepo(profile: profile);

  final router = GoRouter(
    initialLocation: '/profile/details',
    routes: [
      GoRoute(
        path: '/profile/details',
        builder: (_, __) => const ProfileDrillScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('프로필 화면')),
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

/// 뒤로가기 테스트 전용 헬퍼:
/// /profile(스택 바닥) → /profile/details(push) 구조로 시작해 pop()이 동작하도록 한다.
/// GoRouter 인스턴스를 반환해 push를 직접 호출할 수 있게 한다.
(Widget, GoRouter) _buildDrillFromProfile({UserProfile? profile}) {
  final repo = _FakeProfileRepo(profile: profile);

  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('프로필 화면')),
        routes: [
          GoRoute(
            path: 'details',
            builder: (_, __) => const ProfileDrillScreen(),
          ),
        ],
      ),
    ],
  );

  final widget = ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );

  return (widget, router);
}

void main() {
  // ── a. 헤더 ─────────────────────────────────────────────────────

  group('a: Sticky 헤더', () {
    testWidgets('"내 기준 자세히" 타이틀 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('내 기준 자세히'), findsOneWidget);
    });

    testWidgets('뒤로가기 아이콘 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('뒤로가기 탭 → 이전 화면으로 전환', (tester) async {
      // /profile 바닥 → /profile/details push 구조로 pop()이 동작
      final (widget, router) = _buildDrillFromProfile();
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // /profile/details로 push (스택에 /profile이 남아 pop 가능)
      router.push('/profile/details');
      await tester.pumpAndSettle();

      expect(find.byType(ProfileDrillScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('프로필 화면'), findsOneWidget);
    });
  });

  // ── b. 섹션 라벨 ─────────────────────────────────────────────────

  group('b: 섹션 헤더', () {
    testWidgets('"임계치 산정 흐름" 섹션 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('임계치 산정 흐름'), findsOneWidget);
    });

    testWidgets('"5축 가중치" 섹션 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('5축 가중치'), findsOneWidget);
    });

    testWidgets('"자료원" 섹션 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('자료원'), findsOneWidget);
    });

    testWidgets('섹션 3 동적 타이틀 — 일반 그룹 프로필', (tester) async {
      // 기본 픽스처: 건강 조건 없음 → label = "일반 그룹"
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('"일반 그룹"이란'), findsOneWidget);
    });

    testWidgets('섹션 3 동적 타이틀 — 호흡기 민감 그룹 프로필', (tester) async {
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

      await tester.pumpWidget(_buildDrillScreen(profile: sensitiveProfile));
      await tester.pumpAndSettle();

      expect(find.text('"호흡기 민감 그룹"이란'), findsOneWidget);
    });
  });

  // ── c. Waterfall 위젯 ────────────────────────────────────────────

  group('c: Waterfall 컴포넌트', () {
    testWidgets('Waterfall 위젯 렌더링', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Waterfall), findsOneWidget);
    });

    testWidgets('"일반 기준" 노드 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('일반 기준'), findsOneWidget);
    });

    testWidgets('"내 기준" 노드 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('내 기준'), findsOneWidget);
    });

    testWidgets('"환경공단" 서브라벨 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('환경공단'), findsOneWidget);
    });
  });

  // ── d. AxisList variant F ────────────────────────────────────────

  group('d: AxisList variant F (5축 가중치 섹션)', () {
    testWidgets('AxisList variant F 렌더링', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      // variant F로 렌더된 AxisList 존재 확인
      // (ProfileTab variant D + DrillScreen variant F = 총 2개 아닐 수 있으므로 1개 이상 확인)
      expect(find.byType(AxisList), findsWidgets);
    });

    testWidgets('호흡기 민감 행 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('호흡기 민감'), findsOneWidget);
    });

    testWidgets('"해당 없음" 텍스트 표시 (비활성 축)', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      // 일반 프로필(no conditions)에서는 여러 축이 해당 없음
      expect(find.text('해당 없음'), findsWidgets);
    });
  });

  // ── e. 자료원 ────────────────────────────────────────────────────

  group('e: 자료원 섹션', () {
    testWidgets('"WHO Air Quality Guidelines 2021" 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('WHO Air Quality Guidelines 2021'), findsOneWidget);
    });

    testWidgets('"환경부 미세먼지 기준" 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.text('환경부 미세먼지 기준'), findsOneWidget);
    });

    testWidgets('면책 주석 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('의료적 진단'), findsOneWidget);
    });
  });

  // ── f. 호흡기 민감 프로필 ───────────────────────────────────────

  group('f: 호흡기 민감 프로필 Waterfall', () {
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

    testWidgets('호흡기 민감 가중치 DeltaRow 표시', (tester) async {
      await tester.pumpWidget(_buildDrillScreen(profile: sensitiveProfile));
      await tester.pumpAndSettle();

      // active axis가 있으면 "− 호흡기 민감" 형태로 표시
      expect(find.textContaining('− 호흡기 민감'), findsOneWidget);
    });

    testWidgets('페르소나 설명문에 "호흡기 민감" 언급', (tester) async {
      await tester.pumpWidget(_buildDrillScreen(profile: sensitiveProfile));
      await tester.pumpAndSettle();

      expect(find.textContaining('호흡기 민감'), findsWidgets);
    });
  });
}
