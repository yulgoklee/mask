// Q4·Q5·Q6 _insightBox 강화 카피 확인 테스트 (사이클 #11 [B])
//
// 계획서 §3 카피 기준:
//   Q4: "호흡기 질환이 있으면 같은 농도에서 더 일찍 반응해요."
//       "기준치를 최대 30%까지 낮춰 더 일찍 알려드려요."
//   Q5: "혈관 질환이 있으면 미세먼지가 혈관 벽에 더 큰 자극을 줘요."
//       "기준치를 최대 25%까지 낮춰 더 일찍 알려드려요."
//   Q6: "현재 흡연 중이면 기준치를 20% 더 낮춰요."
//       "금연 후에도 폐 민감도가 수년간 높게 유지돼요."

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/data/models/user_profile.dart';
import 'package:mask_alert/features/onboarding/diagnosis_cards.dart';

// ── 헬퍼: 위젯을 MaterialApp으로 감싸서 mount ──────────────────

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ── Q4 하네스 ──────────────────────────────────────────────────

class _Q4Harness extends StatefulWidget {
  const _Q4Harness();
  @override
  State<_Q4Harness> createState() => _Q4HarnessState();
}

class _Q4HarnessState extends State<_Q4Harness> {
  bool rhinitis = false;
  bool asthma = false;
  bool copd = false;
  bool allergy = false;
  bool noneSelected = true;

  @override
  Widget build(BuildContext context) {
    return DiagQ4Respiratory(
      rhinitis: rhinitis,
      asthma: asthma,
      copd: copd,
      allergy: allergy,
      noneSelected: noneSelected,
      onChanged: (r, a, c, al, none) => setState(() {
        rhinitis = r;
        asthma = a;
        copd = c;
        allergy = al;
        noneSelected = none;
      }),
    );
  }
}

// ── Q5 하네스 ──────────────────────────────────────────────────

class _Q5Harness extends StatefulWidget {
  const _Q5Harness();
  @override
  State<_Q5Harness> createState() => _Q5HarnessState();
}

class _Q5HarnessState extends State<_Q5Harness> {
  bool hypertension = false;
  bool heartDisease = false;
  bool stroke = false;
  bool noneSelected = true;

  @override
  Widget build(BuildContext context) {
    return DiagQ5Cardiovascular(
      hypertension: hypertension,
      heartDisease: heartDisease,
      stroke: stroke,
      noneSelected: noneSelected,
      onChanged: (h, hd, s, none) => setState(() {
        hypertension = h;
        heartDisease = hd;
        stroke = s;
        noneSelected = none;
      }),
    );
  }
}

// ── Q6 하네스 ──────────────────────────────────────────────────

class _Q6Harness extends StatefulWidget {
  const _Q6Harness();
  @override
  State<_Q6Harness> createState() => _Q6HarnessState();
}

class _Q6HarnessState extends State<_Q6Harness> {
  SmokingStatus? value;

  @override
  Widget build(BuildContext context) {
    return DiagQ6Smoking(
      value: value,
      onChanged: (v) => setState(() => value = v),
    );
  }
}

// ── Q6-1 하네스 ────────────────────────────────────────────────

class _Q61Harness extends StatefulWidget {
  const _Q61Harness();
  @override
  State<_Q61Harness> createState() => _Q61HarnessState();
}

class _Q61HarnessState extends State<_Q61Harness> {
  bool cigarette = false;
  bool heated = false;
  bool vaping = false;

  @override
  Widget build(BuildContext context) {
    return DiagQ6_1SmokingType(
      cigarette: cigarette,
      heated: heated,
      vaping: vaping,
      onChanged: (c, h, v) => setState(() {
        cigarette = c;
        heated = h;
        vaping = v;
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  테스트
// ══════════════════════════════════════════════════════════════

void main() {
  group('Q4 호흡기 _insightBox 강화 카피', () {
    testWidgets('첫 번째 줄 카피 확인', (tester) async {
      await tester.pumpWidget(_wrap(const _Q4Harness()));
      expect(
        find.textContaining('호흡기 질환이 있으면 같은 농도에서 더 일찍 반응해요'),
        findsOneWidget,
      );
    });

    testWidgets('두 번째 줄 카피 확인 (30% 수치)', (tester) async {
      await tester.pumpWidget(_wrap(const _Q4Harness()));
      expect(
        find.textContaining('기준치를 최대 30%까지 낮춰 더 일찍 알려드려요'),
        findsOneWidget,
      );
    });
  });

  group('Q5 심혈관 _insightBox 강화 카피', () {
    testWidgets('첫 번째 줄 카피 확인', (tester) async {
      await tester.pumpWidget(_wrap(const _Q5Harness()));
      expect(
        find.textContaining('혈관 질환이 있으면 미세먼지가 혈관 벽에 더 큰 자극을 줘요'),
        findsOneWidget,
      );
    });

    testWidgets('두 번째 줄 카피 확인 (25% 수치)', (tester) async {
      await tester.pumpWidget(_wrap(const _Q5Harness()));
      expect(
        find.textContaining('기준치를 최대 25%까지 낮춰 더 일찍 알려드려요'),
        findsOneWidget,
      );
    });
  });

  group('Q6-1 흡연 종류 _insightBox 카피 (D-3 현재 카피 유지)', () {
    testWidgets('담배 종류에 따라 폐에 미치는 영향 카피 확인', (tester) async {
      await tester.pumpWidget(_wrap(const _Q61Harness()));
      expect(
        find.textContaining('담배 종류에 따라 폐에 미치는 영향이 달라요'),
        findsOneWidget,
      );
    });
  });

  group('Q6 흡연 _insightBox 강화 카피', () {
    testWidgets('첫 번째 줄 카피 확인 (20% 수치)', (tester) async {
      await tester.pumpWidget(_wrap(const _Q6Harness()));
      expect(
        find.textContaining('현재 흡연 중이면 기준치를 20% 더 낮춰요'),
        findsOneWidget,
      );
    });

    testWidgets('두 번째 줄 카피 확인 (금연 후 민감도)', (tester) async {
      await tester.pumpWidget(_wrap(const _Q6Harness()));
      expect(
        find.textContaining('금연 후에도 폐 민감도가 수년간 높게 유지돼요'),
        findsOneWidget,
      );
    });
  });
}
