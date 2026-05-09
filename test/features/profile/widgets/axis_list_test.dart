import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/constants/design_tokens.dart';
import 'package:mask_alert/features/profile/widgets/axis_list.dart';

// ── 픽스처 ────────────────────────────────────────────────────

const _axes5 = [
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
    weight: 0,
    delta: 0,
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

const _allNeutral = [
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
    weight: 0,
    delta: 0,
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

Widget buildList(List<AxisItem> axes) {
  return MaterialApp(
    home: Scaffold(
      body: AxisList(axes: axes, accentColor: DT.safe),
    ),
  );
}

void main() {
  group('AxisList — active 항목', () {
    testWidgets('active 항목 라벨 표시', (tester) async {
      await tester.pumpWidget(buildList(_axes5));
      expect(find.text('호흡기 민감'), findsOneWidget);
      expect(find.text('연령'), findsOneWidget);
    });

    testWidgets('active 항목 sub 표시', (tester) async {
      await tester.pumpWidget(buildList(_axes5));
      expect(find.text('천식'), findsOneWidget);
      expect(find.text('36세'), findsOneWidget);
    });

    testWidgets('active 항목 delta 표시 (-7.0 → "-7.0")', (tester) async {
      await tester.pumpWidget(buildList(_axes5));
      expect(find.text('-7.0'), findsOneWidget);
    });
  });

  group('AxisList — neutral 항목 압축', () {
    testWidgets('비활성 항목들은 한 줄 "해당 없음" 압축', (tester) async {
      await tester.pumpWidget(buildList(_axes5));
      // 심혈관, 흡연, 임신·특별은 비활성 → 한 줄 압축
      expect(find.textContaining('해당 없음'), findsOneWidget);
      expect(find.textContaining('심혈관'), findsOneWidget);
    });

    testWidgets('모두 비활성이면 전체 압축 한 줄', (tester) async {
      await tester.pumpWidget(buildList(_allNeutral));
      expect(find.textContaining('해당 없음'), findsOneWidget);
      // 활성 행 없음
      expect(find.text('-7.0'), findsNothing);
    });

    testWidgets('비활성 항목들은 개별 행으로 표시되지 않음', (tester) async {
      await tester.pumpWidget(buildList(_axes5));
      // 심혈관은 개별 라벨로 단독 렌더 없어야 함
      // (압축 줄에 포함돼 있음)
      // 단독 Text('심혈관')이 없는 대신 textContaining으로 압축 줄에서 찾음
      final independentLabel = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data == '심혈관' &&
            w.style?.fontWeight == FontWeight.w700,
      );
      expect(independentLabel, findsNothing);
    });
  });

  group('AxisList — 단위 표시', () {
    testWidgets('"㎍/㎥" 단위 active 항목마다 표시', (tester) async {
      await tester.pumpWidget(buildList(_axes5));
      // active 2개 → ㎍/㎥ 2개
      expect(find.text('㎍/㎥'), findsNWidgets(2));
    });
  });
}
