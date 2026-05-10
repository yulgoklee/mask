import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 설정 인라인 토글 위젯
class SSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChange;

  const SSwitch({
    super.key,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChange,
      activeThumbColor: DT.text,
      activeTrackColor: DT.border,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
