import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import 'care_background.dart';

/// 미세먼지 수치 행 (시안 v3 정확)
///
/// 카드 박스 X. 라벨 (13px) + 큰 숫자 (30px) + 단위 + hint.
/// hint = "내 기준의 절반 아래" / "내 기준에 가까움" / "내 기준 N% 초과"
class PollutantRow extends StatelessWidget {
  final double pm25;
  final double? pm10;
  final double threshold; // 개인 임계치
  final CareRiskLevel level;

  const PollutantRow({
    super.key,
    required this.pm25,
    required this.pm10,
    required this.threshold,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final base = CareBackground.baseColor(level);
    final ratio = threshold > 0 ? pm25 / threshold : 0.0;

    String hint;
    Color hintColor;
    if (ratio < 0.7) {
      hint = '내 기준의 절반 아래';
      hintColor = DT.gray;
    } else if (ratio < 1.0) {
      hint = '내 기준(${threshold.round()})에 가까움';
      hintColor = base;
    } else {
      final over = ((ratio - 1) * 100).round();
      hint = '내 기준 $over% 초과';
      hintColor = base;
    }

    return Row(
      children: [
        Expanded(
          child: _Cell(
            label: '초미세먼지 PM2.5',
            value: pm25.round(),
            unit:  '㎍/㎥',
            hint:  hint,
            hintColor: hintColor,
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: _Cell(
            label: '미세먼지 PM10',
            value: pm10?.round(),
            unit:  '㎍/㎥',
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String  label;
  final int?    value;
  final String  unit;
  final String? hint;
  final Color?  hintColor;

  const _Cell({
    required this.label,
    required this.value,
    required this.unit,
    this.hint,
    this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: const TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      DT.gray,
          ),
        ),
        const SizedBox(height: 6),

        // 큰 숫자 + 단위
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value?.toString() ?? '—',
              style: const TextStyle(
                fontSize:      30,
                fontWeight:    FontWeight.w700,
                color:         DT.text,
                letterSpacing: -0.9,
                fontFamily:    'monospace',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      DT.gray,
              ),
            ),
          ],
        ),

        // hint
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: TextStyle(
              fontSize:      12,
              fontWeight:    FontWeight.w500,
              color:         hintColor ?? DT.gray,
              letterSpacing: -0.06,
            ),
          ),
        ],
      ],
    );
  }
}
