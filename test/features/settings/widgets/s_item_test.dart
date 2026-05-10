import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/settings/widgets/s_item.dart';
import 'package:mask_alert/features/settings/widgets/s_switch.dart';
import 'package:mask_alert/features/settings/widgets/s_ext_icon.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // ── a. chevron 종류 ────────────────────────────────────────
  testWidgets('a: onClick 있고 trailing 없으면 chevron_right 아이콘 자동 추가', (tester) async {
    await tester.pumpWidget(_wrap(
      SItem(label: '건강 정보 수정', onClick: () {}),
    ));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  // ── b. 토글 종류 ───────────────────────────────────────────
  testWidgets('b: trailing = SSwitch이면 토글 표시', (tester) async {
    await tester.pumpWidget(_wrap(
      SItem(
        label: '실시간 경보',
        trailing: SSwitch(value: true, onChange: (_) {}),
      ),
    ));
    expect(find.byType(SSwitch), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    // chevron 없음
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  // ── c. 정보 표시 종류 ─────────────────────────────────────
  testWidgets('c: onClick null, trailing null → chevron 없고 값만 표시', (tester) async {
    await tester.pumpWidget(_wrap(
      const SItem(label: '버전 정보', value: '1.3.0 (12)'),
    ));
    expect(find.text('버전 정보'), findsOneWidget);
    expect(find.text('1.3.0 (12)'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  // ── d. 외부 링크 종류 ─────────────────────────────────────
  testWidgets('d: trailing = SExtIcon이면 open_in_new 아이콘 표시', (tester) async {
    await tester.pumpWidget(_wrap(
      SItem(
        label: '개인정보처리방침',
        trailing: const SExtIcon(),
        onClick: () {},
      ),
    ));
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  // ── e. last=true → hairline 없음 ─────────────────────────
  testWidgets('e: last=true이면 하단 Divider 없음', (tester) async {
    await tester.pumpWidget(_wrap(
      SItem(label: '문의', onClick: () {}, last: true),
    ));
    // Divider가 없어야 함
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('e: last=false이면 하단 Divider 있음', (tester) async {
    await tester.pumpWidget(_wrap(
      SItem(label: '개인정보처리방침', onClick: () {}),
    ));
    expect(find.byType(Divider), findsOneWidget);
  });

  // ── f. onClick InkWell ────────────────────────────────────
  testWidgets('f: onClick 있으면 InkWell로 감싸짐', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      SItem(label: '재진단 받기', onClick: () => tapped = true),
    ));
    await tester.tap(find.text('재진단 받기'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  // ── g. indent ─────────────────────────────────────────────
  testWidgets('g: indent 있으면 Padding에 left 반영됨', (tester) async {
    await tester.pumpWidget(_wrap(
      SItem(label: '시작 시간', onClick: () {}, indent: 20),
    ));
    expect(find.text('시작 시간'), findsOneWidget);
  });
}
