import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 방해 금지 시간 펼침 자식 — 시안 DndChild 정합
/// borderLeft 2px + paddingLeft 16 + marginLeft 2
class SDndChild extends StatelessWidget {
  final Widget child;

  const SDndChild({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 2,
            color: DT.text.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: child,
    );
  }
}
