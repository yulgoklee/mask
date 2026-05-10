import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q3 — 성별
// ══════════════════════════════════════════════════════════════

class DiagQ3Gender extends StatelessWidget {
  final String? value; // 'male'|'female'|null
  final ValueChanged<String?> onChanged;
  final int questionNumber;

  const DiagQ3Gender({super.key, this.value, required this.onChanged, this.questionNumber = 3});

  static const _options = <(String, String)>[
    ('male',   '남성'),
    ('female', '여성'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q$questionNumber · 성별'),
          const SizedBox(height: 14),
          qTitle(context, '성별을 알려주세요'),
          const SizedBox(height: 40),
          Row(
            children: List.generate(_options.length, (i) {
              final (val, label) = _options[i];
              final selected = value == val;
              // 카드 사이 간격만 오른쪽 패딩 — 마지막 카드는 패딩 없음
              final isLast = i == _options.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 12),
                  child: GestureDetector(
                    // 이미 선택된 항목 재탭 시 null 토글 방지 — 항상 해당 값 설정
                    onTap: () => onChanged(val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: selected
                            ? DT.primary.withValues(alpha: 0.08)
                            : DT.grayLt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? DT.primary : DT.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            val == 'male' ? Icons.male : Icons.female,
                            size: 40,
                            color: selected ? DT.primary : DT.gray2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: selected ? DT.primary : DT.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
