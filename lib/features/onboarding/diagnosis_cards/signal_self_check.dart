import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q5.5 — 잠재 민감군 자가 점검 (선택, 1.1.0+)
//
//  `FeatureFlags.kEnableSignalSelfCheck` 가 true 일 때만 노출.
//  Q5(심혈관) 다음, Q6(흡연) 이전. 4개 신호 (A1·B1·C1·D3) 체크리스트.
//  복수 선택, 답하지 않아도 됨 (모두 false 가능 → 건너뛰기 효과).
//  자세한 매핑: `docs/research/signal_weight_mapping_v0.md`
// ══════════════════════════════════════════════════════════════

class DiagSignalSelfCheck extends StatelessWidget {
  /// SignalId.* → bool. 누락된 키는 false로 간주.
  final Map<String, bool> answers;

  /// 토글 시 갱신된 전체 답변 맵을 부모에 전달.
  final ValueChanged<Map<String, bool>> onChanged;

  /// 진행 표시용 페이지 번호 (Q5와 Q6 사이라서 5나 6의 변형이 아닌 임의 표시).
  final int questionNumber;

  const DiagSignalSelfCheck({
    super.key,
    required this.answers,
    required this.onChanged,
    this.questionNumber = 6,
  });

  /// 신호 카드 정의 (id, iconData, label, hint)
  ///
  /// 라벨은 의학적 진단 표현이 아닌 일상 언어. 답하기 쉬운 형태.
  static const _signals = <(String, IconData, String, String)>[
    (
      'signal_a1', // SignalId.a1
      Icons.water_drop_outlined,
      '콧물·코막힘이 한 주에 4일 이상 있다',
      '계절·환경과 관계없이 자주 반복되는 경우',
    ),
    (
      'signal_b1', // SignalId.b1
      Icons.nights_stay_outlined,
      '자다가 천식 증상으로 깬 적 있다',
      '쌕쌕거림·가슴 답답함으로 새벽에 깬 경험',
    ),
    (
      'signal_c1', // SignalId.c1
      Icons.directions_run,
      '운동 시작 5~10분 후 가슴 답답함·기침',
      '평소 활동량 대비 호흡이 더 거칠어지는 경우',
    ),
    (
      'signal_d3', // SignalId.d3
      Icons.air,
      '만성 가래 동반 기침이 3개월 이상 지속',
      '겨울·아침에 가래가 더 심한 편',
    ),
  ];

  bool _isChecked(String id) => answers[id] ?? false;

  void _toggle(String id) {
    final updated = Map<String, bool>.from(answers);
    final next = !_isChecked(id);
    if (next) {
      updated[id] = true;
    } else {
      // false는 키 자체를 제거 — 답변 안 한 것과 동일하게 취급.
      updated.remove(id);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q$questionNumber · 자가 점검 (선택)'),
          const SizedBox(height: 14),
          qTitle(context, '혹시 이런 적\n있으신가요?'),
          const SizedBox(height: 8),
          qSubtitle(context, '복수 선택 가능 · 답하지 않아도 괜찮아요.'),
          const SizedBox(height: 28),

          // ── 4개 신호 체크리스트 ─────────────────────────────
          ..._signals.map((sig) {
            final (id, iconData, label, hint) = sig;
            final sel = _isChecked(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggle(id),
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
                                fontSize: 14,
                                color: sel
                                    ? DT.caution
                                    : DT.text,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hint,
                              style: const TextStyle(
                                fontSize: 12,
                                color: DT.gray,
                                height: 1.4,
                              ),
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

          const SizedBox(height: 16),

          // ── 의료 면책 + 자료 출처 ──────────────────────────
          insightBox(
            '체크해도 진단이 아니에요. "민감군일 가능성"을 기준에 살짝 반영할 뿐이에요.\n\n'
            '자료: ARIA·ATS·GOLD·CB Scale 가이드라인 참조',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
