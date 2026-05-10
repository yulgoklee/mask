import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile/profile_edit_screen.dart';
import 'package:mask_alert/features/settings/widgets/s_item.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

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

// ── 기본 테스트 프로필 ─────────────────────────────────────

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

// ── 테스트 헬퍼 ───────────────────────────────────────────

late SharedPreferences _prefs;

(ProviderContainer, Widget) _buildWithContainer({
  UserProfile? initial,
}) {
  final repo = _FakeProfileRepo(initial: initial ?? _base);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(_prefs),
    profileRepositoryProvider.overrideWith((_) => repo),
  ]);
  addTearDown(container.dispose);
  return (
    container,
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileEditScreen()),
    ),
  );
}

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

/// SItem label을 기준으로 인접 Switch를 찾아 탭 후 저장
Future<void> _tapSwitchAndSave(WidgetTester tester, String label) async {
  // SItem 위젯 내 label 텍스트의 형제 Switch를 찾음
  final sItem = find.ancestor(
    of: find.text(label),
    matching: find.byType(SItem),
  );
  final sw = find.descendant(of: sItem, matching: find.byType(Switch));
  await tester.tap(sw);
  await tester.pumpAndSettle();
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
}

// ── 테스트 ────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a: 섹션 렌더링 ────────────────────────────────────

  group('a: 섹션 렌더링', () {
    testWidgets('호흡기 질환 섹션 헤더 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('호흡기 질환'), findsOneWidget);
    });

    testWidgets('호흡기 4개 항목 타이틀 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('비염'), findsOneWidget);
      expect(find.text('천식'), findsOneWidget);
      expect(find.text('COPD (만성 폐쇄성 폐질환)'), findsOneWidget);
      expect(find.text('알레르기 (꽃가루 등)'), findsOneWidget);
    });

    testWidgets('심혈관 질환 섹션 헤더 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('심혈관 질환'), findsOneWidget);
    });

    testWidgets('심혈관 3개 항목 타이틀 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('고혈압'), findsOneWidget);
      expect(find.text('심장 질환'), findsOneWidget);
      expect(find.text('뇌졸중 (중풍 경험)'), findsOneWidget);
    });

    testWidgets('흡연 여부 SItem 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('흡연 여부'), findsOneWidget);
    });

    testWidgets('never 초기 상태: 흡연 종류 Switch 숨김', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('연초'), findsNothing);
      expect(find.text('가열식'), findsNothing);
      expect(find.text('전자담배'), findsNothing);
    });

    testWidgets('저장 버튼 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('저장'), findsOneWidget);
    });
  });

  // ── a-2: 초기 상태 프로필 반영 ────────────────────────

  group('a-2: 초기 상태 프로필 반영', () {
    testWidgets('rhinitis=true → 비염 Switch ON', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(
          _buildApp(initial: _base.copyWith(rhinitis: true)));
      await tester.pump();

      final sItem = find.ancestor(
        of: find.text('비염'),
        matching: find.byType(SItem),
      );
      final sw = tester.widget<Switch>(
        find.descendant(of: sItem, matching: find.byType(Switch)),
      );
      expect(sw.value, isTrue);
    });

    testWidgets('hypertension=true → 고혈압 Switch ON', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(
          _buildApp(initial: _base.copyWith(hypertension: true)));
      await tester.pump();

      final sItem = find.ancestor(
        of: find.text('고혈압'),
        matching: find.byType(SItem),
      );
      final sw = tester.widget<Switch>(
        find.descendant(of: sItem, matching: find.byType(Switch)),
      );
      expect(sw.value, isTrue);
    });

    testWidgets('smokingStatus=current → 종류 Switch 노출', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(
        _buildApp(
            initial: _base.copyWith(smokingStatus: SmokingStatus.current)),
      );
      await tester.pump();
      expect(find.text('연초'), findsOneWidget);
    });
  });

  // ── b: Switch 토글 후 저장 ───────────────────────────

  group('b: Switch 토글 후 저장', () {
    testWidgets('비염 Switch 탭 + 저장 → rhinitis=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, '비염');
      expect(container.read(profileProvider).rhinitis, isTrue);
    });

    testWidgets('천식 Switch 탭 + 저장 → asthma=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, '천식');
      expect(container.read(profileProvider).asthma, isTrue);
    });

    testWidgets('COPD Switch 탭 + 저장 → copd=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, 'COPD (만성 폐쇄성 폐질환)');
      expect(container.read(profileProvider).copd, isTrue);
    });

    testWidgets('알레르기 Switch 탭 + 저장 → allergy=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, '알레르기 (꽃가루 등)');
      expect(container.read(profileProvider).allergy, isTrue);
    });

    testWidgets('고혈압 Switch 탭 + 저장 → hypertension=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, '고혈압');
      expect(container.read(profileProvider).hypertension, isTrue);
    });

    testWidgets('심장 질환 Switch 탭 + 저장 → heartDisease=true 저장',
        (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, '심장 질환');
      expect(container.read(profileProvider).heartDisease, isTrue);
    });

    testWidgets('뇌졸중 Switch 탭 + 저장 → stroke=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitchAndSave(tester, '뇌졸중 (중풍 경험)');
      expect(container.read(profileProvider).stroke, isTrue);
    });
  });

  // ── c: 흡연 섹션 조건부 노출 + 초기화 ──────────────────

  group('c: 흡연 섹션 조건부 노출 + 초기화', () {
    testWidgets('smokingStatus=current → 종류 Switch 3개 노출', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      ));
      await tester.pump();
      expect(find.text('연초'), findsOneWidget);
      expect(find.text('가열식'), findsOneWidget);
      expect(find.text('전자담배'), findsOneWidget);
    });

    testWidgets('smokingStatus=current → 흡연 여부 SItem 값 "현재 흡연 중"',
        (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      ));
      await tester.pump();
      expect(find.text('현재 흡연 중'), findsOneWidget);
    });

    testWidgets('smokingStatus=never → 흡연 종류 미표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('연초'), findsNothing);
    });

    testWidgets('비흡연 변경 시 종류 자동 초기화 + 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer(
        initial: _base.copyWith(
          smokingStatus: SmokingStatus.current,
          smokesCigarette: true,
          smokesHeated: true,
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      // 흡연 여부 SItem 탭 → BottomSheet 오픈
      await tester.tap(find.text('현재 흡연 중'));
      await tester.pumpAndSettle();

      // BottomSheet에서 "끊었어요" 선택
      await tester.tap(find.text('끊었어요'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).smokesCigarette, isFalse);
      expect(container.read(profileProvider).smokesHeated, isFalse);
      expect(container.read(profileProvider).smokesVaping, isFalse);
    });

    testWidgets('현재 흡연 후 연초 Switch 탭 + 저장 → smokesCigarette=true',
        (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      await _tapSwitchAndSave(tester, '연초');
      expect(container.read(profileProvider).smokesCigarette, isTrue);
    });
  });
}
