import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/features/settings/widgets/s_switch.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a: value=true → Switch.value=true', (tester) async {
    await tester.pumpWidget(_wrap(
      SSwitch(value: true, onChange: (_) {}),
    ));
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isTrue);
  });

  testWidgets('b: value=false → Switch.value=false', (tester) async {
    await tester.pumpWidget(_wrap(
      SSwitch(value: false, onChange: (_) {}),
    ));
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);
  });

  testWidgets('c: onChange 콜백 호출됨', (tester) async {
    bool? changed;
    await tester.pumpWidget(_wrap(
      SSwitch(value: false, onChange: (v) => changed = v),
    ));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(changed, isNotNull);
  });

  testWidgets('d: materialTapTargetSize = shrinkWrap', (tester) async {
    await tester.pumpWidget(_wrap(
      SSwitch(value: true, onChange: (_) {}),
    ));
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
  });
}
