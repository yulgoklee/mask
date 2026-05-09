import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/design_tokens.dart';
import 'package:mask_alert/features/profile/widgets/axis_list.dart';
import 'package:mask_alert/features/profile_tab/widgets/waterfall.dart';

// ── 픽스처 ─────────────────────────────────────────────────────────

const _axesWithActive = [
  AxisItem(
    key: 'respiratory',
    label: '호흡기 민감',
    sub: '천식',
    weight: 0.20,
    delta: -7.0,
    isActive: true,
  ),
  AxisItem(
    key: 'cardiovascular',
    label: '심혈관',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'smoking',
    label: '흡연',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'special',
    label: '임신·특별',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'age',
    label: '연령',
    sub: '36세',
    weight: 0.06,
    delta: -2.1,
    isActive: true,
  ),
];

const _axesAllNeutral = [
  AxisItem(
    key: 'respiratory',
    label: '호흡기 민감',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'cardiovascular',
    label: '심혈관',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'smoking',
    label: '흡연',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'special',
    label: '임신·특별',
    sub: null,
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
  AxisItem(
    key: 'age',
    label: '연령',
    sub: '36세',
    weight: 0.0,
    delta: 0.0,
    isActive: false,
  ),
];

Widget _buildWaterfall({
  double general = 35.0,
  double tFinal = 26.0,
  List<AxisItem> axes = _axesWithActive,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Waterfall(
          general: general,
          tFinal: tFinal,
          axes: axes,
          accent: DT.caution,
        ),
      ),
    ),
  );
}

void main() {
  // ── a. 노드 렌더링 ───────────────────────────────────────────────

  group('a: 시작/끝 노드', () {
    testWidgets('"일반 기준" 노드 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('일반 기준'), findsOneWidget);
    });

    testWidgets('"내 기준" 노드 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('내 기준'), findsOneWidget);
    });

    testWidgets('"환경공단" 서브라벨 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('환경공단'), findsOneWidget);
    });

    testWidgets('일반 기준 값(35) 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall(general: 35.0));
      expect(find.text('35'), findsWidgets); // ㎍/㎥ 포함 여러 개
    });

    testWidgets('내 기준 값(26) 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall(tFinal: 26.0));
      expect(find.text('26'), findsOneWidget);
    });
  });

  // ── b. DeltaRow (active 축) ──────────────────────────────────────

  group('b: DeltaRow — active 축 표시', () {
    testWidgets('active 호흡기 민감 DeltaRow: "− 호흡기 민감" 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('− 호흡기 민감'), findsOneWidget);
    });

    testWidgets('active 연령 DeltaRow: "− 연령" 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('− 연령'), findsOneWidget);
    });

    testWidgets('delta 값 표시 (호흡기: -7.0 → "-7.0")', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('-7.0'), findsOneWidget);
    });

    testWidgets('note(sub) + 가중치 표시', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      // "천식 · 가중치 0.20" 형태
      expect(find.textContaining('천식'), findsOneWidget);
      expect(find.textContaining('가중치'), findsWidgets);
    });
  });

  // ── c. inactive 축은 DeltaRow 미표시 ───────────────────────────

  group('c: inactive 축 미표시', () {
    testWidgets('inactive 심혈관은 DeltaRow 없음', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('− 심혈관'), findsNothing);
    });

    testWidgets('inactive 흡연은 DeltaRow 없음', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      expect(find.text('− 흡연'), findsNothing);
    });
  });

  // ── d. 전부 inactive (일반 그룹) ────────────────────────────────

  group('d: 전부 inactive — DeltaRow 없이 시작/끝 노드만', () {
    testWidgets('일반 기준, 내 기준만 표시 (DeltaRow 0개)', (tester) async {
      await tester.pumpWidget(
        _buildWaterfall(tFinal: 35.0, axes: _axesAllNeutral),
      );
      expect(find.text('일반 기준'), findsOneWidget);
      expect(find.text('내 기준'), findsOneWidget);
      expect(find.textContaining('− '), findsNothing);
    });
  });

  // ── e. CustomPainter _ConnArrow ─────────────────────────────────

  group('e: ConnArrow CustomPainter', () {
    testWidgets('active 축 있으면 ConnArrow CustomPaint 렌더링', (tester) async {
      await tester.pumpWidget(_buildWaterfall());
      // active 2개 → ConnArrow 3개 (각 노드 사이 + 마지막 내 기준 앞)
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
