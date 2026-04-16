import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 2단계 — 신체 민감도 진단 (v2)
///
/// Q4: 호흡기 상태 (0=건강 1=비염 2=천식등)
/// Q5: 체감 민감도 (0=무던 1=보통 2=예민)
class StepBodySensitivity extends StatelessWidget {
  final int respiratoryStatus;
  final int sensitivityLevel;
  final ValueChanged<int> onRespiratoryChanged;
  final ValueChanged<int> onSensitivityChanged;

  const StepBodySensitivity({
    super.key,
    required this.respiratoryStatus,
    required this.sensitivityLevel,
    required this.onRespiratoryChanged,
    required this.onSensitivityChanged,
  });

  static const _respiratoryOptions = [
    (0, '😊', '건강해요',      '호흡기 관련 증상이 없어요',         '+0%'),
    (1, '👃', '비염 있어요',   '코막힘·재채기가 자주 발생해요',     '+15%'),
    (2, '🫁', '천식 등 질환',  '천식·심혈관·호흡기 질환이 있어요', '+30%'),
  ];

  static const _sensitivityOptions = [
    (0, '😶', '무던해요',     '공기 변화를 잘 못 느껴요'),
    (1, '😌', '보통이에요',   '가끔 느끼는 편이에요'),
    (2, '😣', '매우 예민해요','조금만 탁해도 바로 느껴요'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _questionBadge('신체 민감도'),
          const SizedBox(height: 12),
          Text(
            '호흡기 상태와\n체감 민감도를 알려주세요',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '정확할수록 맞춤 알림 기준이 세밀해져요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),

          // ── 호흡기 상태 ───────────────────────────────────
          Text(
            '호흡기 상태',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          ...(_respiratoryOptions.map((opt) {
            final (value, emoji, label, hint, badge) = opt;
            final selected = respiratoryStatus == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onRespiratoryChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
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
                      Text(emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
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
                              hint,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })),

          const SizedBox(height: 20),

          // ── 체감 민감도 ───────────────────────────────────
          Text(
            '체감 민감도',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _sensitivityOptions.map((opt) {
              final (value, emoji, label, hint) = opt;
              final sel = sensitivityLevel == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSensitivityChanged(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
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

          // ── 근거 문구 ─────────────────────────────────────
          const SizedBox(height: 24),
          _insightBox(
            '비염 여부를 체크하면 15% 더 정밀하게 감지합니다. '
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
