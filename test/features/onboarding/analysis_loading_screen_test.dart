import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/analysis_loading_screen.dart';
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

// ── 픽스처 ────────────────────────────────────────────────────

const _profileWithName = UserProfile(
  nickname: '지수',
  birthYear: 1995,
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

const _profileNoName = UserProfile(
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

Widget _buildApp(UserProfile profile) {
  final repo = _FakeProfileRepo(profile);
  final router = GoRouter(
    initialLocation: '/loading',
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const AnalysisLoadingScreen(),
      ),
      GoRoute(
        path: '/diagnosis_result',
        builder: (_, __) => const Scaffold(body: Text('result')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── 테스트 ────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('AnalysisLoadingScreen smoke', () {
    testWidgets('a: SpinKitThreeBounce 렌더링', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp(_profileWithName));
        await tester.pump(const Duration(milliseconds: 50));
      });
      expect(find.byType(SpinKitThreeBounce), findsOneWidget);
    });

    testWidgets('b: nickname 있을 때 cap 인사 표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp(_profileWithName));
        await tester.pump(const Duration(milliseconds: 50));
      });
      // displayName = '지수님' → cap: "지수님만을 위한"
      expect(find.textContaining('만을 위한'), findsOneWidget);
      expect(find.textContaining('만들어지고 있어요'), findsWidgets);
    });

    testWidgets('c: nickname 없을 때 Hero main만 표시 (cap 없음)', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp(_profileNoName));
        await tester.pump(const Duration(milliseconds: 50));
      });
      expect(find.textContaining('만들어지고 있어요'), findsWidgets);
    });

    testWidgets('d: 초기 메시지 "건강 정보를 읽고 있어요" 표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp(_profileWithName));
        await tester.pump(const Duration(milliseconds: 50));
      });
      expect(find.text('건강 정보를 읽고 있어요'), findsOneWidget);
    });
  });
}
