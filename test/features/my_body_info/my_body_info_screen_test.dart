import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/temporary_state.dart';
import 'package:mask_alert/data/models/today_situation.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/my_body_info/my_body_info_screen.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile;
  _FakeProfileRepo([UserProfile? initial])
      : _profile = initial ?? _base;

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<void> saveProfile(UserProfile profile) async => _profile = profile;

  @override
  Future<NotificationSetting> loadNotificationSetting() async =>
      const NotificationSetting();

  @override
  Future<void> saveNotificationSetting(NotificationSetting s) async {}

  @override
  Future<List<TemporaryState>> loadTemporaryStates() async => [];

  @override
  Future<void> saveTemporaryStates(List<TemporaryState> states) async {}

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
  nickname: '율곡',
  birthYear: 1990,
  gender: 'male',
  respiratoryStatus: 0,
  sensitivityLevel: 1,
  isPregnant: false,
  recentSkinTreatment: false,
  outdoorMinutes: 1,
  activityTags: [],
  discomfortLevel: 2, // 보존 확인용 (f 시나리오)
);

// ── 테스트 헬퍼 ───────────────────────────────────────────

Widget _buildApp({UserProfile? initial}) {
  final repo = _FakeProfileRepo(initial ?? _base);
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) => repo),
    ],
    child: const MaterialApp(home: MyBodyInfoScreen()),
  );
}

// ProviderContainer 기반 헬퍼 (저장 결과 직접 검증용)
(ProviderContainer, Widget) _buildWithContainer({UserProfile? initial}) {
  final repo = _FakeProfileRepo(initial ?? _base);
  final container = ProviderContainer(
    overrides: [profileRepositoryProvider.overrideWith((_) => repo)],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: MyBodyInfoScreen()),
  );
  return (container, widget);
}

void main() {
  // ── a. 렌더링 확인 ────────────────────────────────────────

  group('a: 화면 렌더링', () {
    testWidgets('AppBar 타이틀 "내 몸 정보" 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('내 몸 정보'), findsOneWidget);
    });

    testWidgets('3개 섹션 헤더 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('기본 정보'), findsOneWidget);
      expect(find.text('건강 상태'), findsOneWidget);
      expect(find.text('현재 상황'), findsOneWidget);
    });

    testWidgets('9개 항목 타이틀 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      for (final title in [
        '닉네임', '출생 연도', '성별',
        '호흡기', '민감도', '야외 활동', '활동 유형',
        '임신', '피부 시술',
      ]) {
        expect(find.text(title), findsOneWidget, reason: '$title not found');
      }
    });
  });

  // ── b. 현재 프로필 값 표시 ────────────────────────────────

  group('b: 현재 프로필 값 표시', () {
    testWidgets('닉네임 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('율곡'), findsOneWidget);
    });

    testWidgets('닉네임 미입력 시 "미입력" 표시', (tester) async {
      await tester.pumpWidget(_buildApp(initial: _base.copyWith(nickname: '')));
      await tester.pump();
      expect(find.text('미입력'), findsOneWidget);
    });

    testWidgets('출생연도 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('1990년'), findsOneWidget);
    });

    testWidgets('성별 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('남성'), findsOneWidget);
    });

    testWidgets('호흡기 표시 — 건강함', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('건강함'), findsOneWidget);
    });

    testWidgets('민감도 표시 — 조금 예민', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('조금 예민'), findsOneWidget);
    });

    testWidgets('야외 활동 표시 — 30분~3시간', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('30분~3시간'), findsOneWidget);
    });

    testWidgets('활동 유형 없음 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('없음'), findsOneWidget);
    });

    testWidgets('임신 아니오 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('아니오'), findsOneWidget);
    });

    testWidgets('피부 시술 해당 없음 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('해당 없음'), findsOneWidget);
    });
  });

  // ── c. 바텀시트 열림/닫힘 ─────────────────────────────────

  group('c: 바텀시트 열림/닫힘', () {
    testWidgets('닉네임 항목 탭 → 바텀시트 열림', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('닉네임'));
      await tester.pumpAndSettle();

      // TextField가 바텀시트에 표시됨
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('취소 버튼 → 바텀시트 닫힘', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('닉네임'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('성별 항목 탭 → 칩 그룹 바텀시트 열림', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('성별'));
      await tester.pumpAndSettle();

      expect(find.text('남성'), findsWidgets);
      expect(find.text('여성'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
    });

    testWidgets('호흡기 항목 탭 → 바텀시트 열림', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('호흡기'));
      await tester.pumpAndSettle();

      expect(find.text('건강함'), findsWidgets);
      expect(find.text('비염'), findsOneWidget);
      expect(find.text('천식'), findsOneWidget);
    });

    testWidgets('활동 유형 항목 탭 → 체크박스 목록 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('활동 유형'));
      await tester.pumpAndSettle();

      expect(find.text('출퇴근'), findsOneWidget);
      expect(find.text('산책'), findsOneWidget);
      expect(find.text('운동'), findsOneWidget);
    });

    testWidgets('임신 항목 탭 → 스위치 바텀시트 열림', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('임신'));
      await tester.pumpAndSettle();

      expect(find.text('임신 중이에요'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('피부 시술 항목 탭 → 스위치 바텀시트 열림', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.scrollUntilVisible(find.text('피부 시술'), 100);
      await tester.pump();
      await tester.tap(find.text('피부 시술'));
      await tester.pumpAndSettle();

      expect(find.text('최근 피부 시술했어요'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  // ── d. 값 수정 → 저장 → 프로필 반영 ──────────────────────

  group('d: 저장 후 프로필 반영', () {
    testWidgets('d-닉네임: 새 닉네임 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('닉네임'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '새이름');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).nickname, '새이름');
    });

    testWidgets('d-성별: 여성으로 변경 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('성별'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('여성'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).gender, 'female');
    });

    testWidgets('d-호흡기: 비염으로 변경 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('호흡기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('비염'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).respiratoryStatus, 1);
    });

    testWidgets('d-민감도: 매우 예민으로 변경 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('민감도'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('매우 예민'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).sensitivityLevel, 2);
    });

    testWidgets('d-야외활동: 3시간 이상으로 변경 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('야외 활동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3시간 이상'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).outdoorMinutes, 2);
    });

    testWidgets('d-활동유형: 출퇴근 선택 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('활동 유형'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('출퇴근'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).activityTags,
          contains(ActivityTag.commute));
    });

    testWidgets('d-임신: ON으로 변경 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('임신'));
      await tester.pumpAndSettle();

      // 스위치 탭으로 ON
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).isPregnant, isTrue);
    });

    testWidgets('d-피부시술: ON으로 변경 저장 반영', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.scrollUntilVisible(find.text('피부 시술'), 100);
      await tester.pump();
      await tester.tap(find.text('피부 시술'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).recentSkinTreatment, isTrue);
    });
  });

  // ── e. 취소 시 변경 없음 ──────────────────────────────────

  group('e: 취소 시 변경 없음', () {
    testWidgets('성별 바텀시트에서 변경 후 취소 → 원래값 유지', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('성별'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('여성'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).gender, 'male');
    });

    testWidgets('호흡기 바텀시트에서 변경 후 취소 → 원래값 유지', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('호흡기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('비염'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).respiratoryStatus, 0);
    });
  });

  // ── f. discomfortLevel 보존 ───────────────────────────────

  group('f: discomfortLevel 수정 후에도 보존', () {
    testWidgets('민감도 변경 저장 후 discomfortLevel=2 유지', (tester) async {
      // _base에 discomfortLevel: 2 설정돼 있음
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('민감도'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('매우 예민'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = container.read(profileProvider);
      expect(saved.sensitivityLevel, 2);
      expect(saved.discomfortLevel, 2); // 원래값 보존
    });

    testWidgets('호흡기 변경 저장 후 discomfortLevel=2 유지', (tester) async {
      final (container, widget) = _buildWithContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pump();

      await tester.tap(find.text('호흡기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('천식'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = container.read(profileProvider);
      expect(saved.respiratoryStatus, 2);
      expect(saved.discomfortLevel, 2);
    });
  });
}
