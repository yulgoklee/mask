import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/notification_time_screen.dart';
import 'package:mask_alert/features/settings/widgets/settings_drill_header.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';
import 'package:mask_alert/widgets/app_button.dart';

// ── Fake repo ─────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile;
  NotificationSetting _setting;

  _FakeProfileRepo({
    UserProfile? profile,
    NotificationSetting? setting,
  })  : _profile = profile ?? _baseProfile,
        _setting = setting ?? const NotificationSetting();

  @override
  Future<UserProfile> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(UserProfile p) async => _profile = p;
  @override
  Future<NotificationSetting> loadNotificationSetting() async => _setting;
  @override
  Future<void> saveNotificationSetting(NotificationSetting s) async =>
      _setting = s;
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

const _baseProfile = UserProfile(
  nickname: '테스트',
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

late SharedPreferences _prefs;

Widget _buildApp({bool isOnboarding = false}) {
  final repo = _FakeProfileRepo();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: MaterialApp(
      home: NotificationTimeScreen(isOnboarding: isOnboarding),
    ),
  );
}

// flutter_animate 타이머(300~350ms) 완전 소진 헬퍼
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a: 헤더 분기 ──────────────────────────────────────────

  group('a: 헤더 분기', () {
    testWidgets('isOnboarding=false → SettingsDrillHeader "알림 시간" 표시',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      expect(find.byType(SettingsDrillHeader), findsOneWidget);
      expect(find.text('알림 시간'), findsOneWidget);
    });

    testWidgets(
        'isOnboarding=true → "거의 다 왔어요" 표시, SettingsDrillHeader 없음',
        (tester) async {
      await tester.pumpWidget(_buildApp(isOnboarding: true));
      await _settle(tester);

      expect(find.text('거의 다 왔어요'), findsOneWidget);
      expect(find.byType(SettingsDrillHeader), findsNothing);
    });
  });

  // ── b: Hero 영역 ──────────────────────────────────────────

  group('b: Hero 영역', () {
    testWidgets('알림 관련 Hero 텍스트 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      expect(find.textContaining('알림'), findsWidgets);
    });
  });

  // ── c: 스케줄 알림 항목 ────────────────────────────────────

  group('c: _TimeRow 스케줄 알림 항목', () {
    testWidgets('외출 전·전날 예보·귀가 후 라벨 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      expect(find.text('외출 전'), findsOneWidget);
      expect(find.text('전날 예보'), findsOneWidget);
      expect(find.text('귀가 후'), findsOneWidget);
    });

    testWidgets('실시간 경보 항목 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      expect(find.text('실시간 경보'), findsOneWidget);
    });

    testWidgets('방해 금지 시간 항목 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      expect(find.text('방해 금지 시간'), findsOneWidget);
    });
  });

  // ── d: 미리 보기 버튼 ─────────────────────────────────────

  group('d: 알림 미리 보기 버튼', () {
    testWidgets('"미리 보기" 버튼 텍스트 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      expect(find.text('미리 보기'), findsOneWidget);
    });
  });

  // ── e: isOnboarding 파라미터 ──────────────────────────────

  group('e: isOnboarding 파라미터', () {
    testWidgets('isOnboarding=false → "설정 완료" 버튼 없음', (tester) async {
      await tester.pumpWidget(_buildApp(isOnboarding: false));
      await _settle(tester);

      expect(find.text('설정 완료'), findsNothing);
    });

    testWidgets('isOnboarding=true → "설정 완료" AppButton 표시', (tester) async {
      await tester.pumpWidget(_buildApp(isOnboarding: true));
      await _settle(tester);

      expect(find.byType(AppButton), findsWidgets);
      expect(find.text('설정 완료'), findsOneWidget);
    });

    testWidgets('isOnboarding 기본값 false — 하위 호환', (tester) async {
      final widget = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(_prefs),
          profileRepositoryProvider.overrideWith((_) => _FakeProfileRepo()),
        ],
        child: const MaterialApp(
          home: NotificationTimeScreen(),
        ),
      );
      await tester.pumpWidget(widget);
      await _settle(tester);

      expect(find.text('설정 완료'), findsNothing);
    });
  });
}
