import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 설정 메인 최상단 헤더 "환경 설정" — 24pt (yulgok 수정 1)
class SCap extends StatelessWidget {
  final String text;

  const SCap({super.key, this.text = '환경 설정'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: DT.text,
          letterSpacing: -0.6,
          height: 1.2,
        ),
      ),
    );
  }
}
