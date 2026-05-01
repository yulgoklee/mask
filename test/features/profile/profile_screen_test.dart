import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/temporary_state.dart';
import 'package:mask_alert/data/models/today_situation.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile/profile_screen.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile;
  List<TemporaryState> _states;

  _FakeProfileRepo({UserProfile? initial, List<TemporaryState>? states})
      : _profile = initial ?? _base,
        _states = states ?? [];

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
  Future<List<TemporaryState>> loadTemporaryStates() async =>
      List.of(_states);
  @override
  Future<void> saveTemporaryStates(List<TemporaryState> s) async =>
      _states = s;
  @override
  Future<List<TodaySituation>> loadTodaySituations() async => [];
  @override
  Future<void> saveTodaySituations(List<TodaySituation> s) async {}
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
  gender: 'female', // female → 임신 섹션 표시
  asthma: false,
  rhinitis: false,
  copd: false,
  allergy: false,
  hypertension: false,
  heartDisease: false,
  stroke: false,
  isPregnant: false,
  smokingStatus: SmokingStatus.never,
  activityTags: [],
  discomfortLevel: 1,
);

// ── 테스트 헬퍼 ───────────────────────────────────────────

late SharedPreferences _prefs;

(ProviderContainer, Widget) _buildWithContainer({
  UserProfile? initial,
  List<TemporaryState>? states,
}) {
  final repo =
      _FakeProfileRepo(initial: initial ?? _base, states: states ?? []);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(_prefs),
    profileRepositoryProvider.overrideWith((_) => repo),
  ]);
  addTearDown(container.dispose);
  return (
    container,
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
}

Widget _buildApp({UserProfile? initial, List<TemporaryState>? states}) {
  final repo =
      _FakeProfileRepo(initial: initial ?? _base, states: states ?? []);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

// ListView 전체 렌더링을 위해 뷰 높이를 크게 설정
void _setTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// 특정 타이틀의 ListTile에서 Switch를 찾아 탭
Future<void> _tapSwitch(WidgetTester tester, String title) async {
  final tile = find.ancestor(
    of: find.text(title),
    matching: find.byType(ListTile),
  );
  final sw = find.descendant(of: tile, matching: find.byType(Switch));
  await tester.tap(sw);
  await tester.pumpAndSettle();
}

// ── 테스트 ────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── C-1 a: 새 섹션 렌더링 ────────────────────────────────

  group('a: 새 섹션 렌더링', () {
    testWidgets('호흡기 섹션 헤더 표시', (tester) async {
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

    testWidgets('심혈관 섹션 헤더 표시', (tester) async {
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

    testWidgets('흡연 ChipGroup 3개 옵션 표시', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('현재 흡연 중'), findsOneWidget);
      expect(find.text('끊었어요'), findsOneWidget);
      expect(find.text('안 피워요'), findsOneWidget);
    });

    testWidgets('never 초기 상태: 흡연 종류 Switch 숨김', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('연초'), findsNothing);
      expect(find.text('가열식'), findsNothing);
      expect(find.text('전자담배'), findsNothing);
    });
  });

  // ── C-1 a-2: 초기 상태 프로필 반영 ─────────────────────

  group('a-2: 초기 상태 프로필 반영', () {
    testWidgets('rhinitis=true → 비염 Switch ON', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(
          _buildApp(initial: _base.copyWith(rhinitis: true)));
      await tester.pump();

      final tile = find.ancestor(
        of: find.text('비염'),
        matching: find.byType(ListTile),
      );
      final sw = tester.widget<Switch>(
        find.descendant(of: tile, matching: find.byType(Switch)),
      );
      expect(sw.value, isTrue);
    });

    testWidgets('hypertension=true → 고혈압 Switch ON', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(
          _buildApp(initial: _base.copyWith(hypertension: true)));
      await tester.pump();

      final tile = find.ancestor(
        of: find.text('고혈압'),
        matching: find.byType(ListTile),
      );
      final sw = tester.widget<Switch>(
        find.descendant(of: tile, matching: find.byType(Switch)),
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

  // ── C-1 b: Switch 토글 저장 ──────────────────────────────

  group('b: Switch 토글 저장', () {
    testWidgets('비염 Switch 탭 → rhinitis=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '비염');
      expect(container.read(profileProvider).rhinitis, isTrue);
    });

    testWidgets('천식 Switch 탭 → asthma=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '천식');
      expect(container.read(profileProvider).asthma, isTrue);
    });

    testWidgets('COPD Switch 탭 → copd=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, 'COPD (만성 폐쇄성 폐질환)');
      expect(container.read(profileProvider).copd, isTrue);
    });

    testWidgets('알레르기 Switch 탭 → allergy=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '알레르기 (꽃가루 등)');
      expect(container.read(profileProvider).allergy, isTrue);
    });

    testWidgets('고혈압 Switch 탭 → hypertension=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '고혈압');
      expect(container.read(profileProvider).hypertension, isTrue);
    });

    testWidgets('심장 질환 Switch 탭 → heartDisease=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '심장 질환');
      expect(container.read(profileProvider).heartDisease, isTrue);
    });

    testWidgets('뇌졸중 Switch 탭 → stroke=true 저장', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '뇌졸중 (중풍 경험)');
      expect(container.read(profileProvider).stroke, isTrue);
    });

    testWidgets('Switch 탭 후 SnackBar 표시', (tester) async {
      _setTallView(tester);
      final (_, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();
      await _tapSwitch(tester, '비염');
      expect(find.text('저장됐어요'), findsOneWidget);
    });
  });

  // ── C-2 c: 흡연 섹션 조건부 노출 + 초기화 ───────────────

  group('c: 흡연 섹션 조건부 노출 + 초기화', () {
    testWidgets('현재 흡연 중 선택 → 종류 Switch 3개 노출 + smokingStatus 저장',
        (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer();
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('현재 흡연 중'));
      await tester.pumpAndSettle();

      expect(find.text('연초'), findsOneWidget);
      expect(find.text('가열식'), findsOneWidget);
      expect(find.text('전자담배'), findsOneWidget);
      expect(
          container.read(profileProvider).smokingStatus, SmokingStatus.current);
    });

    testWidgets('끊었어요 선택 → 종류 숨김', (tester) async {
      _setTallView(tester);
      final (_, widget) = _buildWithContainer(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('끊었어요'));
      await tester.pumpAndSettle();

      expect(find.text('연초'), findsNothing);
    });

    testWidgets('안 피워요 선택 → 종류 숨김', (tester) async {
      _setTallView(tester);
      final (_, widget) = _buildWithContainer(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('안 피워요'));
      await tester.pumpAndSettle();

      expect(find.text('연초'), findsNothing);
    });

    testWidgets('비흡연 변경 시 종류 자동 초기화', (tester) async {
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

      await tester.tap(find.text('끊었어요'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).smokesCigarette, isFalse);
      expect(container.read(profileProvider).smokesHeated, isFalse);
      expect(container.read(profileProvider).smokesVaping, isFalse);
    });

    testWidgets('현재 흡연 후 연초 Switch 탭 → smokesCigarette=true', (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer(
        initial: _base.copyWith(smokingStatus: SmokingStatus.current),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      await _tapSwitch(tester, '연초');
      expect(container.read(profileProvider).smokesCigarette, isTrue);
    });
  });

  // ── C-3 d: 임신 동기화 (B-4) ─────────────────────────────

  group('d: 임신 동기화 (B-4)', () {
    testWidgets('임신 TemporaryState 추가 → isPregnant=true 동기화',
        (tester) async {
      _setTallView(tester);
      final (container, widget) = _buildWithContainer(
        initial: _base.copyWith(gender: 'female', isPregnant: false),
        states: [],
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      // female → pregnancy가 orderedInactive 첫 번째 → 첫 번째 '추가' 버튼
      await tester.tap(find.text('추가').first);
      await tester.pumpAndSettle();

      expect(find.text('적용하기'), findsOneWidget);
      await tester.tap(find.text('적용하기'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).isPregnant, isTrue);
      expect(
        container
            .read(temporaryStatesProvider)
            .any((s) => s.type == TemporaryStateType.pregnancy),
        isTrue,
      );
    });

    testWidgets('임신 TemporaryState 제거 → isPregnant=false 동기화',
        (tester) async {
      _setTallView(tester);
      final pregnancyState = TemporaryState(
        type: TemporaryStateType.pregnancy,
        startDate: DateTime.now(),
        expiryDate: null,
      );
      final (container, widget) = _buildWithContainer(
        initial: _base.copyWith(gender: 'female', isPregnant: true),
        states: [pregnancyState],
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      // 활성 타일 닫기 아이콘 탭
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 '해제' 탭
      expect(find.text('해제'), findsOneWidget);
      await tester.tap(find.text('해제'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).isPregnant, isFalse);
      expect(
        container
            .read(temporaryStatesProvider)
            .where((s) => s.type == TemporaryStateType.pregnancy)
            .isEmpty,
        isTrue,
      );
    });
  });
}
