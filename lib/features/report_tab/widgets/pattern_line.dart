import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/report_models.dart';

/// 패턴 발견 한 줄 + 데이터 캡션
///
/// pattern이 null이면 SizedBox.shrink() 반환.
class PatternLine extends StatelessWidget {
  final PatternData? pattern;

  const PatternLine({super.key, this.pattern});

  @override
  Widget build(BuildContext context) {
    if (pattern == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pattern!.discoveryText,
          style: const TextStyle(
            fontSize:      16,
            fontWeight:    FontWeight.w600,
            color:         DT.text,
            letterSpacing: -0.24,  // -0.015 * 16
            height:        1.45,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pattern!.noteText,
          style: const TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w500,
            color:      DT.gray2,
          ),
        ),
      ],
    );
  }
}
