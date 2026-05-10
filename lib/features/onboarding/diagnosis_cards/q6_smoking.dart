import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../data/models/user_profile.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q6 — 흡연 이력
// ══════════════════════════════════════════════════════════════

class DiagQ6Smoking extends StatelessWidget {
  final SmokingStatus? value; // null = 아직 미선택
  final ValueChanged<SmokingStatus> onChanged;
  final int questionNumber;

  const DiagQ6Smoking({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 6,
  });

  static const _options = <(SmokingStatus, IconData, String, String)>[
    (SmokingStatus.current, Icons.smoking_rooms,       '현재 흡연 중',  '지금도 담배를 피워요'),
    (SmokingStatus.former,  Icons.eco,                 '끊었어요',      '과거에 피웠지만 지금은 아니에요'),
    (SmokingStatus.never,   Icons.check_circle_outline, '안 피워요',    '흡연 이력이 없어요'),
  ];

  /// SmokingStatus별 강조 색 분기
  Color _q6Accent(SmokingStatus s) {
    switch (s) {
      case SmokingStatus.never:   return DT.safe;
      case SmokingStatus.former:  return DT.primary;
      case SmokingStatus.current: return DT.caution;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q$questionNumber · 흡연'),
          const SizedBox(height: 14),
          qTitle(context, '흡연 이력을 알려주세요'),
          const SizedBox(height: 8),
          qSubtitle(context, '흡연은 폐 민감도에 직접적인 영향을 줘요'),
          const SizedBox(height: 28),

          ..._options.map((opt) {
            final (status, iconData, label, hint) = opt;
            final sel = value == status;
            final accent = _q6Accent(status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onChanged(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? accent.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? accent : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? accent : DT.gray2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: sel ? accent : DT.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DT.gray),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: sel ? accent : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          insightBox(
            '현재 흡연 중이면 기준치를 20% 더 낮춰요.\n'
            '금연 후에도 폐 민감도가 수년간 높게 유지돼요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
