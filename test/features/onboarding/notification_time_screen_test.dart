import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/onboarding/notification_time_screen.dart';
import 'package:mask_alert/features/settings/widgets/settings_drill_header.dart';
import 'package:mask_alert/features/settings/widgets/s_item.dart';
import 'package:mask_alert/features/settings/widgets/s_label.dart';
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a: 헤더 ───────────────────────────────────────────────

  group('a: SettingsDrillHeader 표시', () {
    testWidgets('헤더 타이틀 "알림 시간" 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(SettingsDrillHeader), findsOneWidget);
      expect(find.text('알림 시간'), findsOneWidget);
    });
  });

  // ── b: 섹션 라벨 ──────────────────────────────────────────

  group('b: SLabel 섹션 라벨 표시', () {
    testWidgets('스케줄 알림·실시간·방해 금지·알림 미리보기 섹션 라벨 표시',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final sLabels = tester.widgetList<SLabel>(find.byType(SLabel));
      final texts = sLabels.map((w) => w.text).toSet();

      expect(texts, contains('스케줄 알림'));
      expect(texts, contains('실시간'));
      expect(texts, contains('방해 금지'));
      expect(texts, contains('알림 미리보기'));
    });
  });

  // ── c: SItem 항목 ─────────────────────────────────────────

  group('c: SItem 항목 표시', () {
    testWidgets('외출 전·전날 예보·귀가 후 SItem 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final items = tester.widgetList<SItem>(find.byType(SItem));
      final labels = items.map((w) => w.label).toSet();

      expect(labels, contains('외출 전'));
      expect(labels, contains('전날 예보'));
      expect(labels, contains('귀가 후'));
      expect(labels, contains('실시간 경보'));
      expect(labels, contains('방해 금지 시간'));
    });
  });

  // ── d: isOnboarding 파라미터 ──────────────────────────────

  group('d: isOnboarding 파라미터', () {
    testWidgets('isOnboarding=false → "설정 완료" 버튼 없음', (tester) async {
      await tester.pumpWidget(_buildApp(isOnboarding: false));
      await tester.pump();

      expect(find.text('설정 완료  →'), findsNothing);
    });

    testWidgets('isOnboarding=true → "설정 완료→" AppButton 표시', (tester) async {
      await tester.pumpWidget(_buildApp(isOnboarding: true));
      await tester.pump();

      expect(find.byType(AppButton), findsWidgets);
      expect(find.text('설정 완료  →'), findsOneWidget);
    });

    testWidgets('isOnboarding 기본값 false — 하위 호환', (tester) async {
      // 기본 생성자: isOnboarding 파라미터 없이 사용
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
      await tester.pump();

      // 하단 완료 버튼 없음 (기본값 false)
      expect(find.text('설정 완료  →'), findsNothing);
    });
  });
}
