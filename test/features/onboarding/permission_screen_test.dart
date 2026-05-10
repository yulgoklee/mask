import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/permission_screen.dart';
import 'package:mask_alert/features/onboarding/widgets/onboarding_hero.dart';
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

const _profile = UserProfile(
  nickname: '지수',
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

// ── 헬퍼 ──────────────────────────────────────────────────────

late SharedPreferences _prefs;

Widget _buildApp() {
  final repo = _FakeProfileRepo(_profile);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: const MaterialApp(
      home: PermissionScreen(),
    ),
  );
}

// flutter_animate 타이머(300~350ms) 완전 소진 헬퍼
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

// ── 테스트 ────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('PermissionScreen smoke', () {
    testWidgets('a: PopScope canPop=false', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    // 케이스 A: initState 직후 _notifGranted == null → 로딩 상태
    // permission_handler가 테스트 환경에서 완료되지 않으므로
    // pump() 1회 후의 초기 로딩 상태를 검증
    testWidgets('b: 초기 로딩 상태 — CircularProgressIndicator 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(); // 첫 frame — _notifGranted still null
      // _notifGranted == null (케이스 A) → isLoading=true → CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 남은 animate 타이머 소진
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('c: 초기 로딩 상태 — PopScope 존재', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);
      expect(find.byType(PopScope), findsOneWidget);
    });

    testWidgets('d: 초기 로딩 상태 — Scaffold 존재', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('e: OnboardingHero 위젯 사용', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);
      expect(find.byType(OnboardingHero), findsWidgets);
    });
  });
}
