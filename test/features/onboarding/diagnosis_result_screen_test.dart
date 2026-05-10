import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/diagnosis_result_screen.dart';
import 'package:mask_alert/features/onboarding/widgets/onboarding_background.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  final UserProfile _profile;
  _FakeProfileRepo(this._profile);

  @override
  Future<UserProfile> loadProfile() async => _profile;
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

// ── 프로필 픽스처 ──────────────────────────────────────────────

/// 호흡기 민감 그룹 (천식, 비염 → wRespiratory > 0)
const _respiratory = UserProfile(
  nickname: '지수',
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

/// 일반 그룹 (모두 0)
const _general = UserProfile(
  nickname: '',
  birthYear: 1990,
  gender: '',
  asthma: false,
  rhinitis: false,
  copd: false,
  allergy: false,
  hypertension: false,
  heartDisease: false,
  stroke: false,
  smokingStatus: SmokingStatus.never,
);

// ── 헬퍼 ──────────────────────────────────────────────────────

late SharedPreferences _prefs;

GoRouter _makeRouter({bool isRediag = false}) {
  return GoRouter(
    initialLocation: '/result',
    routes: [
      GoRoute(
        path: '/result',
        builder: (_, __) =>
            DiagnosisResultScreen(isRediag: isRediag),
      ),
      GoRoute(
        path: '/location_setup',
        builder: (_, __) => const Scaffold(body: Text('location')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('profile')),
      ),
    ],
  );
}

Widget _buildApp(UserProfile profile, {bool isRediag = false}) {
  final repo = _FakeProfileRepo(profile);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter(isRediag: isRediag)),
  );
}

void _setTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ── KoreanHeroText 정규화 매칭 ──────────────────────────────────

Finder findHeroText(String pattern) => find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data?.replaceAll('\n', ' ').contains(pattern) ?? false),
    );

// ── 테스트 ────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('OnboardingBackground 존재', () {
    testWidgets('OnboardingBackground 위젯 렌더링 확인', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_respiratory));
      await tester.pump();
      expect(find.byType(OnboardingBackground), findsOneWidget);
    });
  });

  group('닉네임 분기', () {
    testWidgets('nickname 있으면 인사 표시 "지수님,"', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_respiratory));
      await tester.pump();
      // displayName = "지수님", ProfileHero에서 "지수님," 렌더
      expect(find.text('지수님,'), findsOneWidget);
    });

    testWidgets('nickname 없으면 인사 없음', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general));
      await tester.pump();
      expect(find.textContaining('님,'), findsNothing);
    });
  });

  group('페르소나 라벨', () {
    testWidgets('호흡기 민감 그룹 — labelDiscovery 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_respiratory));
      await tester.pump();
      expect(findHeroText('호흡기 민감 그룹이에요'), findsOneWidget);
    });

    testWidgets('일반 그룹 — "일반 그룹이에요" 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general));
      await tester.pump();
      expect(findHeroText('일반 그룹이에요'), findsOneWidget);
    });
  });

  group('CTA 라우팅', () {
    testWidgets('isRediag=false → CTA 버튼 "내 동네 공기 보러 가기" 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general, isRediag: false));
      await tester.pump();
      expect(find.text('내 동네 공기 보러 가기'), findsOneWidget);
    });

    testWidgets('isRediag=true → CTA 버튼 "확인" 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general, isRediag: true));
      await tester.pump();
      expect(find.text('확인'), findsOneWidget);
    });
  });

  group('isRediag PopScope', () {
    testWidgets('isRediag=false → PopScope canPop=false', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general, isRediag: false));
      await tester.pump();
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    testWidgets('isRediag=true → PopScope canPop=true', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general, isRediag: true));
      await tester.pump();
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isTrue);
    });
  });

  group('자료원 푸터', () {
    testWidgets('"WHO Air Quality Guidelines 2021" 푸터 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(_general));
      await tester.pump();
      expect(find.textContaining('WHO Air Quality Guidelines 2021'), findsOneWidget);
    });
  });
}
