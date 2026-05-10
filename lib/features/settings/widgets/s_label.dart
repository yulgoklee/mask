import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 설정 카테고리 라벨 (11pt w600 회색 캡션)
///
/// top 20 / bottom 2 패딩 포함.
/// 카테고리 사이 구분선은 SCap이 아닌 SettingsScreen의 Divider로 처리.
class SLabel extends StatelessWidget {
  final String text;

  const SLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DT.gray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
