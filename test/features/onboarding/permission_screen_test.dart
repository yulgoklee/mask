import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/permission_screen.dart';
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

// ── 테스트 ────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('PermissionScreen smoke', () {
    testWidgets('a: PopScope canPop=false', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    testWidgets('b: notifGranted=false → "알림 받기" 버튼 표시', (tester) async {
      // 테스트 환경에서 permission_handler는 denied를 반환 → notifGranted=false
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      // FutureBuilder snapshot.data ?? false → 알림 받기
      expect(find.text('알림 받기'), findsOneWidget);
    });

    testWidgets('c: _ExampleRow 아이콘 3개 렌더 (외출 전·급등·내일 예보)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('외출 30분 전'), findsOneWidget);
      expect(find.textContaining('미세먼지가 급등하면'), findsOneWidget);
      expect(find.textContaining('내일 예보'), findsOneWidget);
    });

    testWidgets('d: "나중에 할게요" 건너뛰기 버튼 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('나중에 할게요'), findsOneWidget);
    });
  });
}
