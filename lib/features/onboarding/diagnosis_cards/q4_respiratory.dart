import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q4 — 호흡기 상태
// ══════════════════════════════════════════════════════════════

class DiagQ4Respiratory extends StatelessWidget {
  final bool rhinitis;
  final bool asthma;
  final bool copd;
  final bool allergy;
  final bool noneSelected;
  final void Function(bool rhinitis, bool asthma, bool copd, bool allergy, bool noneSelected) onChanged;
  final int questionNumber;

  const DiagQ4Respiratory({
    super.key,
    required this.rhinitis,
    required this.asthma,
    required this.copd,
    required this.allergy,
    required this.noneSelected,
    required this.onChanged,
    this.questionNumber = 4,
  });

  static const _conditions = <(String, IconData, String, String)>[
    ('rhinitis', Icons.water_drop_outlined,   '비염 (알레르기성·비알레르기성)',  '콧물·코막힘·재채기·코 가려움'),
    ('asthma',   Icons.air,                   '천식 (운동 유발 포함)',         '쌕쌕거림·가슴 답답함·만성 기침'),
    ('copd',     Icons.waves_outlined,        'COPD / 만성 기관지염',         '만성 기침·가래·계단 시 숨 참'),
    ('allergy',  Icons.local_florist_outlined, '흡입성 알레르기',              '꽃가루·먼지·동물 털 등에 반응'),
  ];

  bool _valueOf(String key) {
    switch (key) {
      case 'rhinitis': return rhinitis;
      case 'asthma':   return asthma;
      case 'copd':     return copd;
      case 'allergy':  return allergy;
      default:         return false;
    }
  }

  void _toggle(String key) {
    final newRhinitis = key == 'rhinitis' ? !rhinitis : rhinitis;
    final newAsthma   = key == 'asthma'   ? !asthma   : asthma;
    final newCopd     = key == 'copd'     ? !copd     : copd;
    final newAllergy  = key == 'allergy'  ? !allergy  : allergy;
    onChanged(newRhinitis, newAsthma, newCopd, newAllergy, false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q$questionNumber · 호흡기'),
          const SizedBox(height: 14),
          qTitle(context, '호흡기 상태를 알려주세요'),
          const SizedBox(height: 6),
          qSubtitle(context, '호흡기 상태는 마스크 판단에 가장 중요해요'),
          const SizedBox(height: 4),
          qSubtitle(context, '진단 받은 게 있다면 모두 선택해주세요'),
          const SizedBox(height: 28),

          // ── 체크박스 항목 (4개) ──────────────────────────────
          ..._conditions.map((opt) {
            final (key, iconData, label, hint) = opt;
            final sel = _valueOf(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggle(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? DT.caution.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? DT.caution : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? DT.caution : DT.gray2),
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
                                color: sel ? DT.caution : DT.text,
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
                        sel ? Icons.check_box : Icons.check_box_outline_blank,
                        color: sel ? DT.caution : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── 구분선 ────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: DT.border),
          ),

          // ── "진단 받은 게 없어요" 라디오 ─────────────────────
          GestureDetector(
            onTap: () => onChanged(false, false, false, false, true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: noneSelected
                    ? DT.safe.withValues(alpha: 0.07)
                    : DT.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: noneSelected ? DT.safe : DT.border,
                  width: noneSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 26, color: noneSelected ? DT.safe : DT.gray2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '진단 받은 게 없어요',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: noneSelected
                            ? DT.safe
                            : DT.text,
                      ),
                    ),
                  ),
                  Icon(
                    noneSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: noneSelected ? DT.safe : DT.gray2,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          insightBox(
            '호흡기 질환이 있으면 같은 농도에서 더 일찍 반응해요.\n'
            '기준치를 최대 30%까지 낮춰 더 일찍 알려드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
