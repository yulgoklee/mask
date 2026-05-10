import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 설정 외부 링크 아이콘 trailing
class SExtIcon extends StatelessWidget {
  const SExtIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.open_in_new, size: 16, color: DT.gray2);
  }
}
