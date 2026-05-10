import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 설정 항목 행 (4종)
///
/// 종류:
///   - chevron: onClick 있음, trailing null → 자동 `>` 추가
///   - toggle: onClick null, trailing = SSwitch
///   - info: onClick null, trailing null (값 표시)
///   - external link: onClick 있음, trailing = SExtIcon
///
/// [last] = true이면 하단 hairline 없음.
class SItem extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onClick;
  final bool last;
  final double? indent;

  const SItem({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onClick,
    this.last = false,
    this.indent,
  });

  @override
  Widget build(BuildContext context) {
    final isClickable = onClick != null;
    final showChevron = isClickable && trailing == null;

    Widget content = Padding(
      padding: EdgeInsets.only(
        left: indent ?? 0,
        top: 14,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: DT.text,
                letterSpacing: -0.34,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DT.gray,
              ),
            ),
          if (value != null && (showChevron || trailing != null))
            const SizedBox(width: 4),
          if (trailing != null) trailing!,
          if (showChevron)
            const Icon(Icons.chevron_right, size: 20, color: DT.gray2),
        ],
      ),
    );

    return Column(
      children: [
        isClickable
            ? InkWell(
                onTap: onClick,
                child: content,
              )
            : content,
        if (!last)
          Divider(
            height: 1,
            thickness: 0.5,
            color: DT.text.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
