import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/onboarding/diagnosis_cards.dart';

// ── 헬퍼 ──────────────────────────────────────────────────────

/// 다음 버튼 활성화 조건 (onboarding_screen.dart 의 onTap 조건과 동일)
bool _isQ4Disabled({
  required bool rhinitis,
  required bool asthma,
  required bool copd,
  required bool allergy,
  required bool noneRespiratory,
}) =>
    !rhinitis && !asthma && !copd && !allergy && !noneRespiratory;

bool _isQ5Disabled({
  required bool hypertension,
  required bool heartDisease,
  required bool stroke,
  required bool noneCardiovascular,
}) =>
    !hypertension && !heartDisease && !stroke && !noneCardiovascular;

// ── DiagQ4Respiratory 래퍼 ────────────────────────────────────

class _Q4Wrapper extends StatefulWidget {
  const _Q4Wrapper();
  @override
  State<_Q4Wrapper> createState() => _Q4WrapperState();
}

class _Q4WrapperState extends State<_Q4Wrapper> {
  bool rhinitis = false;
  bool asthma = false;
  bool copd = false;
  bool allergy = false;
  bool noneRespiratory = true;

  @override
  Widget build(BuildContext context) {
    final disabled = _isQ4Disabled(
      rhinitis: rhinitis,
      asthma: asthma,
      copd: copd,
      allergy: allergy,
      noneRespiratory: noneRespiratory,
    );
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            DiagQ4Respiratory(
              rhinitis: rhinitis,
              asthma: asthma,
              copd: copd,
              allergy: allergy,
              noneSelected: noneRespiratory,
              onChanged: (r, a, c, al, none) => setState(() {
                rhinitis = r;
                asthma = a;
                copd = c;
                allergy = al;
                noneRespiratory = none;
              }),
            ),
            ElevatedButton(
              onPressed: disabled ? null : () {},
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DiagQ5Cardiovascular 래퍼 ─────────────────────────────────

class _Q5Wrapper extends StatefulWidget {
  const _Q5Wrapper();
  @override
  State<_Q5Wrapper> createState() => _Q5WrapperState();
}

class _Q5WrapperState extends State<_Q5Wrapper> {
  bool hypertension = false;
  bool heartDisease = false;
  bool stroke = false;
  bool noneCardiovascular = true;

  @override
  Widget build(BuildContext context) {
    final disabled = _isQ5Disabled(
      hypertension: hypertension,
      heartDisease: heartDisease,
      stroke: stroke,
      noneCardiovascular: noneCardiovascular,
    );
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            DiagQ5Cardiovascular(
              hypertension: hypertension,
              heartDisease: heartDisease,
              stroke: stroke,
              noneSelected: noneCardiovascular,
              onChanged: (h, hd, s, none) => setState(() {
                hypertension = h;
                heartDisease = hd;
                stroke = s;
                noneCardiovascular = none;
              }),
            ),
            ElevatedButton(
              onPressed: disabled ? null : () {},
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 단위 테스트: 비활성화 조건 ────────────────────────────────

void main() {
  // ── a: Q4 활성화 조건 단위 검증 ──────────────────────────

  group('a: Q4 호흡기 다음 버튼 활성화 조건', () {
    test('초기 상태 (noneRespiratory=true): 버튼 활성화', () {
      expect(
        _isQ4Disabled(
          rhinitis: false,
          asthma: false,
          copd: false,
          allergy: false,
          noneRespiratory: true,
        ),
        isFalse,
      );
    });

    test('질환 1개 이상 선택 시 버튼 활성화', () {
      expect(
        _isQ4Disabled(
          rhinitis: true,
          asthma: false,
          copd: false,
          allergy: false,
          noneRespiratory: false,
        ),
        isFalse,
      );
    });

    test('모두 false (체크 후 해제): 버튼 비활성화', () {
      // 버그 시나리오: 비염 ON → OFF 후 noneRespiratory=false 상태
      expect(
        _isQ4Disabled(
          rhinitis: false,
          asthma: false,
          copd: false,
          allergy: false,
          noneRespiratory: false,
        ),
        isTrue,
      );
    });

    test('"없어요" 선택 시 버튼 활성화', () {
      expect(
        _isQ4Disabled(
          rhinitis: false,
          asthma: false,
          copd: false,
          allergy: false,
          noneRespiratory: true,
        ),
        isFalse,
      );
    });
  });

  // ── b: Q5 활성화 조건 단위 검증 ──────────────────────────

  group('b: Q5 심혈관 다음 버튼 활성화 조건', () {
    test('초기 상태 (noneCardiovascular=true): 버튼 활성화', () {
      expect(
        _isQ5Disabled(
          hypertension: false,
          heartDisease: false,
          stroke: false,
          noneCardiovascular: true,
        ),
        isFalse,
      );
    });

    test('질환 1개 이상 선택 시 버튼 활성화', () {
      expect(
        _isQ5Disabled(
          hypertension: true,
          heartDisease: false,
          stroke: false,
          noneCardiovascular: false,
        ),
        isFalse,
      );
    });

    test('모두 false (체크 후 해제): 버튼 비활성화', () {
      expect(
        _isQ5Disabled(
          hypertension: false,
          heartDisease: false,
          stroke: false,
          noneCardiovascular: false,
        ),
        isTrue,
      );
    });

    test('"없어요" 선택 시 버튼 활성화', () {
      expect(
        _isQ5Disabled(
          hypertension: false,
          heartDisease: false,
          stroke: false,
          noneCardiovascular: true,
        ),
        isFalse,
      );
    });
  });

  // ── c: DiagQ4Respiratory 위젯 — 콜백 검증 ────────────────

  group('c: DiagQ4Respiratory 위젯 콜백', () {
    void setTallView(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('초기 상태: 다음 버튼 활성화 (없어요 기본 선택)', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q4Wrapper()));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('비염 탭 → 다음 버튼 활성화 (질환 선택됨)', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q4Wrapper()));
      await tester.pump();

      await tester.tap(find.text('비염 (알레르기성·비알레르기성)'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('비염 ON → OFF: 다음 버튼 비활성화 (빈 상태)', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q4Wrapper()));
      await tester.pump();

      await tester.tap(find.text('비염 (알레르기성·비알레르기성)'));
      await tester.pump();
      await tester.tap(find.text('비염 (알레르기성·비알레르기성)'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull,
          reason: '비염 ON→OFF 후 모든 선택 해제: 다음 버튼 비활성화 필요');
    });

    testWidgets('빈 상태에서 "없어요" 탭 → 다음 버튼 활성화', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q4Wrapper()));
      await tester.pump();

      // 비염 ON → OFF → 빈 상태
      await tester.tap(find.text('비염 (알레르기성·비알레르기성)'));
      await tester.pump();
      await tester.tap(find.text('비염 (알레르기성·비알레르기성)'));
      await tester.pump();

      // 없어요 선택
      await tester.tap(find.text('진단 받은 게 없어요'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });
  });

  // ── d: DiagQ5Cardiovascular 위젯 — 콜백 검증 ─────────────

  group('d: DiagQ5Cardiovascular 위젯 콜백', () {
    void setTallView(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('초기 상태: 다음 버튼 활성화 (없어요 기본 선택)', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q5Wrapper()));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('고혈압 ON → OFF: 다음 버튼 비활성화 (빈 상태)', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q5Wrapper()));
      await tester.pump();

      await tester.tap(find.text('고혈압'));
      await tester.pump();
      await tester.tap(find.text('고혈압'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull,
          reason: '고혈압 ON→OFF 후 모든 선택 해제: 다음 버튼 비활성화 필요');
    });

    testWidgets('빈 상태에서 "없어요" 탭 → 다음 버튼 활성화', (tester) async {
      setTallView(tester);
      await tester.pumpWidget(const MaterialApp(home: _Q5Wrapper()));
      await tester.pump();

      await tester.tap(find.text('고혈압'));
      await tester.pump();
      await tester.tap(find.text('고혈압'));
      await tester.pump();

      await tester.tap(find.text('진단 받은 게 없어요'));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });
  });
}
