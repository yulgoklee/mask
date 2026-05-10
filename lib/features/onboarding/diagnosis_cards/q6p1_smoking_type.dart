import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q6-1 — 흡연 종류 (현재 흡연 중인 경우만)
// ══════════════════════════════════════════════════════════════

class DiagQ6p1SmokingType extends StatelessWidget {
  final bool cigarette;
  final bool heated;
  final bool vaping;
  final void Function(bool cigarette, bool heated, bool vaping) onChanged;
  final int questionNumber;

  const DiagQ6p1SmokingType({
    super.key,
    required this.cigarette,
    required this.heated,
    required this.vaping,
    required this.onChanged,
    this.questionNumber = 7,
  });

  static const _options = <(String, IconData, String, String)>[
    ('cigarette', Icons.smoking_rooms,     '연초',    '일반 담배'),
    ('heated',    Icons.device_thermostat, '가열식',  'IQOS, glo, lil 등'),
    ('vaping',    Icons.cloud_outlined,    '전자담배', '액상형'),
  ];

  bool _valueOf(String key) {
    switch (key) {
      case 'cigarette': return cigarette;
      case 'heated':    return heated;
      case 'vaping':    return vaping;
      default:          return false;
    }
  }

  void _toggle(String key) {
    onChanged(
      key == 'cigarette' ? !cigarette : cigarette,
      key == 'heated'    ? !heated    : heated,
      key == 'vaping'    ? !vaping    : vaping,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.tune, size: 40, color: DT.primary),
          const SizedBox(height: 12),
          qTitle(context, '피우시는 종류는?'),
          const SizedBox(height: 8),
          qSubtitle(context, '모두 선택해주세요'),
          const SizedBox(height: 28),

          ..._options.map((opt) {
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

          const SizedBox(height: 20),
          insightBox(
            '담배 종류에 따라 폐에 미치는 영향이 달라요. '
            '가열식·전자담배도 미세먼지와 결합하면 폐에 더 큰 자극을 줄 수 있어요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
