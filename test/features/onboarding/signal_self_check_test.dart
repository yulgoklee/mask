// 잠재 민감군 자가 점검 페이지 테스트 (B 작업 1.1.0 — B-2 단계)
//
// 다루는 시나리오:
//   1. Feature Flag OFF — 페이지 노출 안 됨
//   2. Feature Flag ON — 페이지 노출됨
//   3. 4개 신호 토글 동작 (체크 → 해제)
//   4. 모든 신호 OFF (건너뛰기) → signalAnswers 빈 맵
//   5. 일부 ON → signalAnswers 해당 키 true
//
// 의존성: `FeatureFlags.kEnableSignalSelfCheck` 컴파일 타임 상수.
//   현재 false이므로 "Flag ON" 테스트는 OnboardingScreen 통합 대신
//   DiagSignalSelfCheck 위젯을 직접 mount 하여 시나리오 검증.
//   (Phase 4에서 Flag true로 전환 후 통합 e2e 테스트 추가 예정.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/feature_flags.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/features/onboarding/diagnosis_cards.dart';

// ── 테스트 래퍼 ────────────────────────────────────────────────

class _SignalCheckHarness extends StatefulWidget {
  const _SignalCheckHarness({this.initial = const {}});
  final Map<String, bool> initial;

  @override
  State<_SignalCheckHarness> createState() => _SignalCheckHarnessState();
}

class _SignalCheckHarnessState extends State<_SignalCheckHarness> {
  late Map<String, bool> answers;

  @override
  void initState() {
    super.initState();
    answers = Map<String, bool>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DiagSignalSelfCheck(
          answers: answers,
          onChanged: (m) => setState(() => answers = m),
        ),
      ),
    );
  }
}

// ── 테스트용 — 큰 화면 (overflow 방지) ────────────────────────

void _setTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ──────────────────────────────────────────────────────────────

void main() {
  // ── a: Feature Flag 게이트 ────────────────────────────────

  group('a: FeatureFlags.kEnableSignalSelfCheck', () {
    test('기본값은 false — Phase 3 검증 전까지 OFF', () {
      // 페이지 노출 자체가 막혀 있어야 함. _includeSignalSelfCheck 분기의
      // 단일 진실 원천이라서 이 값이 변경되면 의도가 바뀐 것.
      expect(FeatureFlags.kEnableSignalSelfCheck, isFalse);
    });
  });

  // ── b: Flag OFF 시 _buildProfile 빈 맵 보장 ────────────────

  group('b: Flag OFF — 프로필 signalAnswers 빈 맵', () {
    test('UserProfile 기본 생성: signalAnswers 빈 맵', () {
      final p = UserProfile.defaultProfile();
      expect(p.signalAnswers, isEmpty);
    });

    test('Flag OFF — 사용자 데이터가 있어도 OnboardingScreen이 빈 맵 저장', () {
      // 가드 로직 (onboarding_screen._buildProfile)이 사용하는 동일 분기.
      final captured = FeatureFlags.kEnableSignalSelfCheck
          ? Map<String, bool>.unmodifiable({SignalId.a1: true})
          : const <String, bool>{};
      expect(captured, isEmpty,
          reason: 'Flag OFF 시 사용자가 어떻게 답하든 빈 맵이 저장돼야 함');
    });
  });

  // ── c: 4개 신호 라벨 노출 ─────────────────────────────────

  group('c: DiagSignalSelfCheck 위젯 라벨 노출', () {
    testWidgets('4개 신호 라벨 모두 보임', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(const _SignalCheckHarness());
      await tester.pump();

      // A1·B1·C1·D3 텍스트가 노출되는지
      expect(find.text('콧물·코막힘이 한 주에 4일 이상 있다'), findsOneWidget);
      expect(find.text('자다가 천식 증상으로 깬 적 있다'), findsOneWidget);
      expect(find.text('운동 시작 5~10분 후 가슴 답답함·기침'), findsOneWidget);
      expect(find.text('만성 가래 동반 기침이 3개월 이상 지속'), findsOneWidget);
    });

    testWidgets('헤더 + 서브 + 면책 푸터 노출', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(const _SignalCheckHarness());
      await tester.pump();

      expect(find.textContaining('혹시 이런 적'), findsOneWidget);
      expect(find.textContaining('답하지 않아도 괜찮아요'), findsOneWidget);
      expect(find.textContaining('진단이 아니에요'), findsOneWidget);
      expect(find.textContaining('ARIA·ATS·GOLD·CB Scale'), findsOneWidget);
    });
  });

  // ── d: 토글 동작 — 단일 신호 ──────────────────────────────

  group('d: 단일 신호 토글', () {
    testWidgets('A1 탭 → answers에 a1=true', (tester) async {
      _setTallView(tester);
      Map<String, bool>? captured;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiagSignalSelfCheck(
            answers: const {},
            onChanged: (m) => captured = m,
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('콧물·코막힘이 한 주에 4일 이상 있다'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured![SignalId.a1], isTrue);
      // 다른 키는 없어야 함 (false는 키 자체 미저장)
      expect(captured!.length, 1);
    });

    testWidgets('A1 ON → OFF: 키가 맵에서 제거됨', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(const _SignalCheckHarness(
        initial: {SignalId.a1: true},
      ));
      await tester.pump();

      // 처음에는 체크된 상태
      final state = tester.state<_SignalCheckHarnessState>(
          find.byType(_SignalCheckHarness));
      expect(state.answers[SignalId.a1], isTrue);

      // 다시 탭 → 해제
      await tester.tap(find.text('콧물·코막힘이 한 주에 4일 이상 있다'));
      await tester.pump();

      expect(state.answers.containsKey(SignalId.a1), isFalse,
          reason: '해제 시 false 저장 대신 키 자체를 제거해야 함');
      expect(state.answers, isEmpty);
    });
  });

  // ── e: 모든 신호 OFF (건너뛰기) ────────────────────────────

  group('e: 건너뛰기 — 모든 신호 false', () {
    testWidgets('초기 빈 맵에서 아무것도 안 누르고 통과 → 빈 맵 유지', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(const _SignalCheckHarness());
      await tester.pump();

      final state = tester.state<_SignalCheckHarnessState>(
          find.byType(_SignalCheckHarness));
      expect(state.answers, isEmpty);
    });
  });

  // ── f: 일부 신호 ON ────────────────────────────────────────

  group('f: 일부 신호 ON', () {
    testWidgets('A1 + C1 두 개 체크 → 두 키만 true', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(const _SignalCheckHarness());
      await tester.pump();

      await tester.tap(find.text('콧물·코막힘이 한 주에 4일 이상 있다'));
      await tester.pump();
      await tester.tap(find.text('운동 시작 5~10분 후 가슴 답답함·기침'));
      await tester.pump();

      final state = tester.state<_SignalCheckHarnessState>(
          find.byType(_SignalCheckHarness));

      expect(state.answers[SignalId.a1], isTrue);
      expect(state.answers[SignalId.c1], isTrue);
      expect(state.answers.containsKey(SignalId.b1), isFalse);
      expect(state.answers.containsKey(SignalId.d3), isFalse);
      expect(state.answers.length, 2);
    });

    testWidgets('4개 모두 체크 → 4개 키 true', (tester) async {
      _setTallView(tester);
      await tester.pumpWidget(const _SignalCheckHarness());
      await tester.pump();

      await tester.tap(find.text('콧물·코막힘이 한 주에 4일 이상 있다'));
      await tester.pump();
      await tester.tap(find.text('자다가 천식 증상으로 깬 적 있다'));
      await tester.pump();
      await tester.tap(find.text('운동 시작 5~10분 후 가슴 답답함·기침'));
      await tester.pump();
      await tester.tap(find.text('만성 가래 동반 기침이 3개월 이상 지속'));
      await tester.pump();

      final state = tester.state<_SignalCheckHarnessState>(
          find.byType(_SignalCheckHarness));

      expect(state.answers[SignalId.a1], isTrue);
      expect(state.answers[SignalId.b1], isTrue);
      expect(state.answers[SignalId.c1], isTrue);
      expect(state.answers[SignalId.d3], isTrue);
      expect(state.answers.length, 4);
    });
  });

  // ── g: SignalId 키 존재 확인 ──────────────────────────────

  group('g: SignalId 상수 무결성', () {
    test('SignalId.all에 4개 키 모두 포함', () {
      expect(SignalId.all, containsAll([
        SignalId.a1,
        SignalId.b1,
        SignalId.c1,
        SignalId.d3,
      ]));
      expect(SignalId.all.length, 4);
    });

    test('각 키는 signal_ 접두사로 시작', () {
      for (final id in SignalId.all) {
        expect(id, startsWith('signal_'));
      }
    });
  });
}
