import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile/profile_edit_screen.dart';
import 'package:mask_alert/features/settings/widgets/s_item.dart';
import 'package:mask_alert/features/settings/widgets/settings_drill_header.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';
import 'package:mask_alert/widgets/app_button.dart';

// ── Fake repo ─────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile;

  _FakeProfileRepo({UserProfile? initial})
      : _profile = initial ?? _base;

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

const _base = UserProfile(
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

Widget _buildApp({UserProfile? initial}) {
  final repo = _FakeProfileRepo(initial: initial ?? _base);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: const MaterialApp(home: ProfileEditScreen()),
  );
}

void _setTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a: SettingsDrillHeader ────────────────────────────────

  group('a: SettingsDrillHeader 헤더', () {
    testWidgets('"건강 정보" 타이틀 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(SettingsDrillHeader), findsOneWidget);
      expect(find.text('건강 정보'), findsOneWidget);
    });

    testWidgets('AppBar 없음 (기존 AppBar 폐기 확인)', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(AppBar), findsNothing);
    });
  });

  // ── b: SItem 항목 구조 ────────────────────────────────────

  group('b: SItem 설정 항목 구조', () {
    testWidgets('성별·출생연도 SItem 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final items = tester.widgetList<SItem>(find.byType(SItem));
      final labels = items.map((w) => w.label).toSet();

      expect(labels, contains('성별'));
      expect(labels, contains('출생연도'));
    });

    testWidgets('호흡기 4개 SItem 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final items = tester.widgetList<SItem>(find.byType(SItem));
      final labels = items.map((w) => w.label).toSet();

      expect(labels, contains('비염'));
      expect(labels, contains('천식'));
      expect(labels, contains('COPD (만성 폐쇄성 폐질환)'));
      expect(labels, contains('알레르기 (꽃가루 등)'));
    });

    testWidgets('심혈관 3개 SItem 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final items = tester.widgetList<SItem>(find.byType(SItem));
      final labels = items.map((w) => w.label).toSet();

      expect(labels, contains('고혈압'));
      expect(labels, contains('심장 질환'));
      expect(labels, contains('뇌졸중 (중풍 경험)'));
    });
  });

  // ── c: D-3 subtitle 제거 ─────────────────────────────────

  group('c: D-3 질환 subtitle 제거 확인', () {
    testWidgets('알레르기성 또는 비알레르기성 비염 등 설명 텍스트 없음', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('알레르기성 또는 비알레르기성 비염'), findsNothing);
      expect(find.text('기관지 천식 진단 또는 증상'), findsNothing);
      expect(find.text('만성기관지염, 폐기종 포함'), findsNothing);
      expect(find.text('고혈압 진단 또는 약 복용 중'), findsNothing);
      expect(find.text('협심증, 심근경색, 부정맥 등'), findsNothing);
    });
  });

  // ── d: D-2 하단 고정 저장 버튼 ───────────────────────────

  group('d: D-2 하단 고정 AppButton.primary 저장 버튼', () {
    testWidgets('"저장" AppButton 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('저장'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });
  });

  // ── e: 흡연 상태별 SItem 분기 ────────────────────────────

  group('e: 흡연 종류 SItem — current 시만 표시', () {
    testWidgets('흡연 never → 연초·가열식·전자담배 미표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(initial: _base));
      await tester.pump();

      final items = tester.widgetList<SItem>(find.byType(SItem));
      final labels = items.map((w) => w.label).toSet();

      expect(labels, isNot(contains('연초')));
      expect(labels, isNot(contains('가열식')));
      expect(labels, isNot(contains('전자담배')));
    });

    testWidgets('흡연 current → 연초·가열식·전자담배 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      ));
      await tester.pump();

      final items = tester.widgetList<SItem>(find.byType(SItem));
      final labels = items.map((w) => w.label).toSet();

      expect(labels, contains('연초'));
      expect(labels, contains('가열식'));
      expect(labels, contains('전자담배'));
    });
  });
}
