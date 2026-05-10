import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q5 — 심혈관
// ══════════════════════════════════════════════════════════════

class DiagQ5Cardiovascular extends StatelessWidget {
  final bool hypertension;
  final bool heartDisease;
  final bool stroke;
  final bool noneSelected;
  final void Function(bool hypertension, bool heartDisease, bool stroke, bool noneSelected) onChanged;
  final int questionNumber;

  const DiagQ5Cardiovascular({
    super.key,
    required this.hypertension,
    required this.heartDisease,
    required this.stroke,
    required this.noneSelected,
    required this.onChanged,
    this.questionNumber = 5,
  });

  static const _conditions = <(String, IconData, String, String)>[
    ('hypertension', Icons.monitor_heart_outlined, '고혈압',           '혈압이 높아 심혈관 부담이 있어요'),
    ('heartDisease', Icons.favorite_outline,       '심장 질환',         '심장 관련 질환을 진단받았어요'),
    ('stroke',       Icons.electric_bolt_outlined, '뇌졸중 (중풍) 경험', '뇌혈관 질환을 경험한 적 있어요'),
  ];

  bool _valueOf(String key) {
    switch (key) {
      case 'hypertension': return hypertension;
      case 'heartDisease': return heartDisease;
      case 'stroke':       return stroke;
      default:             return false;
    }
  }

  void _toggle(String key) {
    final newHypertension = key == 'hypertension' ? !hypertension : hypertension;
    final newHeartDisease = key == 'heartDisease' ? !heartDisease : heartDisease;
    final newStroke       = key == 'stroke'       ? !stroke       : stroke;
    onChanged(newHypertension, newHeartDisease, newStroke, false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q$questionNumber · 심혈관'),
          const SizedBox(height: 14),
          qTitle(context, '혈관 건강을 알려주세요'),
          const SizedBox(height: 6),
          qSubtitle(context, '혈관 건강도 미세먼지 영향을 받아요'),
          const SizedBox(height: 4),
          qSubtitle(context, '진단 받은 게 있다면 모두 선택해주세요'),
          const SizedBox(height: 28),

          // ── 체크박스 항목 (3개) ──────────────────────────────
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
            onTap: () => onChanged(false, false, false, true),
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
            '혈관 질환이 있으면 미세먼지가 혈관 벽에 더 큰 자극을 줘요.\n'
            '기준치를 최대 25%까지 낮춰 더 일찍 알려드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
