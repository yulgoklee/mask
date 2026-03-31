import 'package:flutter/material.dart';
import '../core/constants/dust_standards.dart';

/// 등급 이모지 + 라벨을 표시하는 공용 위젯
/// [grade]가 null이면 '-' 텍스트만 표시
class GradeBadge extends StatelessWidget {
  final DustGrade? grade;
  final double emojiSize;
  final double labelSize;
  final String? valueLabel; // "32μg" 같은 수치 텍스트 (선택)

  const GradeBadge({
    super.key,
    required this.grade,
    this.emojiSize = 18,
    this.labelSize = 11,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (grade == null) {
      return Text('-',
          style: TextStyle(fontSize: labelSize, color: Colors.grey),
          textAlign: TextAlign.center);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(grade!.emoji, style: TextStyle(fontSize: emojiSize)),
        if (valueLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            valueLabel!,
            style: TextStyle(
                fontSize: labelSize,
                color: grade!.color,
                fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          grade!.label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: labelSize,
              color: grade!.color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
