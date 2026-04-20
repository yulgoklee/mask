import 'package:flutter/material.dart';
import '../core/constants/app_tokens.dart';

/// 화면 내 섹션 제목 컴포넌트
///
/// 사용법:
///   SectionHeader('시간별 현황')
///   SectionHeader('오늘의 상태', trailing: TextButton(...))
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Text(title, style: AppTokens.titleSm),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
