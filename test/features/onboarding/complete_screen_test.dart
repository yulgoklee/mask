import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/complete_screen.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/dust_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  final UserProfile _profile;
  final NotificationSetting _setting;

  _FakeProfileRepo({
    required UserProfile profile,
    required NotificationSetting setting,
  })  : _profile = profile,
        _setting = setting;

  @override
  Future<UserProfile> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(UserProfile p) async {}
  @override
  Future<NotificationSetting> loadNotificationSetting() async => _setting;
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

// morningAlert 켜짐: 08:00
const _settingWithMorning = NotificationSetting(
  morningAlertEnabled: true,
  morningAlertHour: 8,
  morningAlertMinute: 0,
);

// 모든 알림 꺼짐
const _settingAllOff = NotificationSetting(
  morningAlertEnabled: false,
  eveningForecastEnabled: false,
  eveningReturnEnabled: false,
);

// ── 헬퍼 ──────────────────────────────────────────────────────

late SharedPreferences _prefs;

Widget _buildApp({
  UserProfile profile = _profile,
  NotificationSetting setting = _settingWithMorning,
}) {
  final repo = _FakeProfileRepo(profile: profile, setting: setting);
  final router = GoRouter(
    initialLocation: '/complete',
    routes: [
      GoRoute(
        path: '/complete',
        builder: (_, __) => const OnboardingCompleteScreen(),
      ),
      GoRoute(
        path: '/care',
        builder: (_, __) => const Scaffold(body: Text('care')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
      // dustDataProvider는 null 반환으로 stub (네트워크 호출 방지)
      dustDataProvider.overrideWith((ref) async => null),
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

  group('OnboardingCompleteScreen smoke', () {
    testWidgets('a: "준비됐어요" 텍스트 표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp());
        await tester.pump(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('준비됐어요'), findsWidgets);
    });

    testWidgets('b: firstAlertTime — 오전 8:00 형식 표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp(setting: _settingWithMorning));
        await tester.pump(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      // _formatTime(8, 0) = '오전 8:00'
      expect(find.textContaining('오전 8:00'), findsOneWidget);
    });

    testWidgets('c: "시작할게요" CTA 버튼 표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp());
        await tester.pump(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('시작할게요'), findsOneWidget);
    });

    testWidgets('d: 모든 알림 꺼진 경우 다른 문구 표시', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildApp(setting: _settingAllOff));
        await tester.pump(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('알림을 모두 끄셨어요'), findsOneWidget);
    });
  });
}
