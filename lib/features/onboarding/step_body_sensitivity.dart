import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// 2단계 — 신체 민감도 진단
///
/// "미세먼지가 심할 때 즉각적인 반응이 있나요?"
/// 선택지: 안구 건조 / 비염 / 천식·가슴 답답함 (복수 선택)
/// + 강도: 약함 / 보통 / 심함 → Severity 매핑
class StepBodySensitivity extends StatelessWidget {
  final Set<ConditionType> selectedSymptoms;
  final Severity severity;
  final ValueChanged<Set<ConditionType>> onSymptomsChanged;
  final ValueChanged<Severity> onSeverityChanged;

  const StepBodySensitivity({
    super.key,
    required this.selectedSymptoms,
    required this.severity,
    required this.onSymptomsChanged,
    required this.onSeverityChanged,
  });

  static const _symptoms = [
    (type: ConditionType.allergy,       emoji: '👁️', label: '안구 건조·충혈',  hint: '눈이 따갑고 빨개져요'),
    (type: ConditionType.respiratory,   emoji: '👃', label: '비염·콧물',        hint: '코가 막히고 재채기가 나요'),
    (type: ConditionType.asthma,        emoji: '🫁', label: '천식·가슴 답답함', hint: '숨이 막히거나 기침이 심해요'),
    (type: ConditionType.cardiovascular,emoji: '💓', label: '심혈관 불편감',    hint: '두근거림·호흡 곤란이 생겨요'),
  ];

  static const _severityOptions = [
    (value: Severity.mild,     label: '약함',  desc: '조금 불편한 정도예요'),
    (value: Severity.moderate, label: '보통',  desc: '일상에 지장이 생겨요'),
    (value: Severity.severe,   label: '심함',  desc: '활동이 어려울 정도예요'),
  ];

  void _toggleSymptom(ConditionType type) {
    final next = Set<ConditionType>.from(selectedSymptoms);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    onSymptomsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = selectedSymptoms.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _questionBadge('신체 민감도'),
          const SizedBox(height: 12),
          Text(
            '미세먼지가 심한 날\n몸이 어떻게 반응하나요?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '해당하는 항목을 모두 선택해주세요. (복수 선택 가능)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),

          // ── 증상 선택 카드 ────────────────────────────────
          ...(_symptoms.map((s) {
            final selected = selectedSymptoms.contains(s.type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _toggleSymptom(s.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.hint,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.textHint,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          })),

          // ── "해당 없음" 버튼 ──────────────────────────────
          GestureDetector(
            onTap: () => onSymptomsChanged({}),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: hasAny ? AppColors.surfaceVariant : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !hasAny ? AppColors.primary : AppColors.divider,
                  width: !hasAny ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('😌', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '딱히 반응 없어요',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: !hasAny
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '미세먼지에 크게 예민하지 않아요',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 강도 선택 (증상 있을 때만) ─────────────────────
          if (hasAny) ...[
            const SizedBox(height: 28),
            Text(
              '증상이 얼마나 심한가요?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: _severityOptions.map((opt) {
                final sel = severity == opt.value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => onSeverityChanged(opt.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt.desc,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: sel
                                    ? Colors.white70
                                    : AppColors.textSecondary,
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
          ],

          // ── 근거 문구 ─────────────────────────────────────
          const SizedBox(height: 24),
          _insightBox(
            '비염 여부를 체크하면 20% 더 정밀하게 감지합니다. '
            '천식이 있는 분은 일반인보다 낮은 농도에서 알림이 울려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── 공용 위젯 ─────────────────────────────────────────────────

Widget _questionBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );

Widget _insightBox(String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
