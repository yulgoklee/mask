import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mask_alert/core/constants/design_tokens.dart';
import 'package:mask_alert/core/utils/persona_generator.dart';
import 'package:mask_alert/data/models/notification_setting.dart';
import 'package:mask_alert/data/models/temporary_state.dart';
import 'package:mask_alert/data/models/today_situation.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/data/repositories/profile_repository.dart';
import 'package:mask_alert/features/profile_tab/widgets/persona_card.dart';
import 'package:mask_alert/providers/profile_providers.dart';

// ── Fake repo ─────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  UserProfile _profile;
  _FakeProfileRepo(this._profile);

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
  Future<List<TemporaryState>> loadTemporaryStates() async => [];

  @override
  Future<void> saveTemporaryStates(List<TemporaryState> s) async {}

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

// ── 프로필 생성 헬퍼 ──────────────────────────────────────

UserProfile _p({
  int respiratory = 0,
  int outdoor = 0,
  int sensitivity = 0,
  bool pregnant = false,
  bool skinTreatment = false,
  String nickname = '지수',
}) =>
    UserProfile(
      nickname: nickname,
      birthYear: 1990,
      gender: 'male',
      respiratoryStatus: respiratory,
      sensitivityLevel: sensitivity,
      isPregnant: pregnant,
      recentSkinTreatment: skinTreatment,
      outdoorMinutes: outdoor,
      activityTags: const [],
      discomfortLevel: 0,
    );

// ── 위젯 빌더 헬퍼 ────────────────────────────────────────

(ProviderContainer, Widget) _build(UserProfile profile) {
  final repo = _FakeProfileRepo(profile);
  final container = ProviderContainer(
    overrides: [profileRepositoryProvider.overrideWith((_) => repo)],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: PersonaCard())),
  );
  return (container, widget);
}

void main() {
// ── a. 기본 렌더링 ────────────────────────────────────────

group('a: 기본 렌더링', () {
  testWidgets('이모지 표시', (tester) async {
    final (container, widget) = _build(_p(respiratory: 2));
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    final persona = PersonaGenerator.generate(_p(respiratory: 2));
    expect(find.text(persona.emoji), findsOneWidget);
  });

  testWidgets('페르소나 이름 표시', (tester) async {
    final (container, widget) = _build(_p());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(find.text('균형 유지형'), findsOneWidget);
  });

  testWidgets('닉네임 표시', (tester) async {
    final (container, widget) = _build(_p(nickname: '지수'));
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(find.text('지수님'), findsOneWidget);
  });

  testWidgets('내 기준치 레이블 표시', (tester) async {
    final (container, widget) = _build(_p());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(find.text('내 기준치'), findsOneWidget);
  });

  testWidgets('일반인 기준 레이블 표시', (tester) async {
    // outdoor=2 → tFinal < 35 이므로 "35 µg/m³" 는 일반인 기준에만 표시됨
    final (container, widget) = _build(_p(outdoor: 2));
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(find.text('일반인 기준'), findsOneWidget);
    expect(find.text('35 µg/m³'), findsOneWidget);
  });

  testWidgets('"자세히 보기" 버튼 표시', (tester) async {
    final (container, widget) = _build(_p());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(find.text('자세히 보기'), findsOneWidget);
  });
});

// ── b. 6개 페르소나 배경색 매핑 ──────────────────────────

group('b: 페르소나별 배경색 매핑', () {
  Color _cardBgColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(PersonaCard),
        matching: find.byType(Container),
      ).first,
    );
    return (container.decoration as BoxDecoration).color!;
  }

  testWidgets('compound → primaryLt', (tester) async {
    // respiratory=2, outdoor=2 → compound
    final (c, w) = _build(_p(respiratory: 2, outdoor: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();
    expect(_cardBgColor(tester), DT.primaryLt);
  });

  testWidgets('medicalCare → purpleLt', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();
    expect(_cardBgColor(tester), DT.purpleLt);
  });

  testWidgets('activeAndSensitive → tealLt', (tester) async {
    final (c, w) = _build(_p(outdoor: 2, sensitivity: 1));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();
    expect(_cardBgColor(tester), DT.tealLt);
  });

  testWidgets('activeOutdoor → safeLt', (tester) async {
    final (c, w) = _build(_p(outdoor: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();
    expect(_cardBgColor(tester), DT.safeLt);
  });

  testWidgets('sensitiveFeel → pinkLt', (tester) async {
    final (c, w) = _build(_p(sensitivity: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();
    expect(_cardBgColor(tester), DT.pinkLt);
  });

  testWidgets('general → grayLt', (tester) async {
    final (c, w) = _build(_p());
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();
    expect(_cardBgColor(tester), DT.grayLt);
  });
});

// ── c. '자세히 보기' 탭 → 확장 상태 전환 ─────────────────

group('c: 확장 동작', () {
  testWidgets('"자세히 보기" 탭 시 "접기" 버튼으로 변경', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.text('접기'), findsOneWidget);
    expect(find.text('자세히 보기'), findsNothing);
  });

  testWidgets('카드 전체 탭으로도 확장됨', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.byType(PersonaCard));
    await tester.pumpAndSettle();

    expect(find.text('접기'), findsOneWidget);
  });
});

// ── d. 확장 시 reasons 렌더링 ──────────────────────────────

group('d: reasons 렌더링', () {
  testWidgets('천식만 → reasons 1개 (번호 1 + 천식 title 표시)', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.text('왜 더 엄격한가요'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('천식'), findsOneWidget);
  });

  testWidgets('천식+야외+매우예민 → reasons 3개 (번호 1~3)', (tester) async {
    final (c, w) = _build(_p(respiratory: 2, outdoor: 2, sensitivity: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('reasons description 표시', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(
      find.text('적은 농도에도 기관지가 반응해요. 그래서 기준을 낮췄어요.'),
      findsOneWidget,
    );
  });
});

// ── e. 균형 유지형 안내 문구 ──────────────────────────────

group('e: 균형 유지형 처리', () {
  testWidgets('확장 시 안내 문구 표시, reasons 블록 없음', (tester) async {
    final (c, w) = _build(_p()); // general
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('공식 기준(35µg/m³)'),
      findsOneWidget,
    );
    expect(find.text('왜 더 엄격한가요'), findsNothing);
  });

  testWidgets('sensitivityLevel=1 단독 (general) → 안내 문구', (tester) async {
    final (c, w) = _build(_p(sensitivity: 1));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('공식 기준(35µg/m³)'), findsOneWidget);
  });
});

// ── f. '접기' 탭 → 원래 상태 복귀 ───────────────────────

group('f: 접기 동작', () {
  testWidgets('"접기" 탭 시 "자세히 보기"로 복귀', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('접기'));
    await tester.pumpAndSettle();

    expect(find.text('자세히 보기'), findsOneWidget);
    expect(find.text('접기'), findsNothing);
  });

  testWidgets('접은 후 reasons 텍스트 사라짐', (tester) async {
    final (c, w) = _build(_p(respiratory: 2));
    addTearDown(c.dispose);
    await tester.pumpWidget(w);
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.text('천식'), findsOneWidget);

    await tester.tap(find.text('접기'));
    await tester.pumpAndSettle();

    expect(find.text('왜 더 엄격한가요'), findsNothing);
  });
});

// ── g. 프로필 변경 시 카드 자동 갱신 ─────────────────────

group('g: 프로필 변경 시 카드 갱신', () {
  testWidgets('general → medicalCare로 변경 시 페르소나 이름 갱신', (tester) async {
    final (container, widget) = _build(_p());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(find.text('균형 유지형'), findsOneWidget);

    // 프로필 업데이트
    await container.read(profileProvider.notifier).saveProfile(
          _p(respiratory: 2),
        );
    await tester.pump();

    expect(find.text('섬세한 체질형'), findsOneWidget);
    expect(find.text('균형 유지형'), findsNothing);
  });

  testWidgets('프로필 변경 후 확장 시 새 reasons 표시', (tester) async {
    final (container, widget) = _build(_p());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pump();

    // general → medicalCare
    await container.read(profileProvider.notifier).saveProfile(_p(respiratory: 2));
    await tester.pump();

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.text('천식'), findsOneWidget);
  });
});
} // end main
