import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 4단계 — 생활 환경 (v2)
///
/// Q8: outdoorMinutes (0=1h미만 1=1~3h 2=3h이상)
/// Q10: discomfortLevel (0=안느낌 1=보통 2=많이불편)
class StepLifestyle extends StatelessWidget {
  final int outdoorMinutes;
  final int discomfortLevel;
  final ValueChanged<int> onOutdoorChanged;
  final ValueChanged<int> onDiscomfortChanged;

  const StepLifestyle({
    super.key,
    required this.outdoorMinutes,
    required this.discomfortLevel,
    required this.onOutdoorChanged,
    required this.onDiscomfortChanged,
  });

  static const _outdoorOptions = [
    (0, Icons.home_outlined,    '1시간 미만', '주로 실내에 있어요',   '+0%'),
    (1, Icons.directions_walk,  '1~3시간',   '매일 외출은 해요',     '+10%'),
    (2, Icons.directions_run,   '3시간 이상', '야외 활동이 많아요',   '+20%'),
  ];

  static const _discomfortOptions = [
    (0, '😌', '안 느껴요',     '마스크가 편해요'),
    (1, '😐', '보통이에요',    '가끔 답답하긴 해요'),
    (2, '😮‍💨', '많이 불편해요', '답답함·김 서림이 심해요'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _questionBadge('생활 환경'),
          const SizedBox(height: 12),
          Text(
            '평소 야외 활동이\n얼마나 되시나요?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '야외 활동이 많을수록 미세먼지 노출 위험이 높아져요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),

          // ── 야외 활동량 ───────────────────────────────────
          ..._outdoorOptions.map((opt) {
            final (value, icon, label, sublabel, badge) = opt;
            final isSelected = outdoorMinutes == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onOutdoorChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              sublabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 20),

          // ── 마스크 불편 정도 ───────────────────────────────
          Text(
            '마스크 착용 시 불편함이\n있으신가요?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '많이 불편하면 알림 기준을 조금 완화해드려요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          Row(
            children: _discomfortOptions.map((opt) {
              final (value, emoji, label, hint) = opt;
              final sel = discomfortLevel == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onDiscomfortChanged(value),
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
                              fontSize: 12,
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
          const SizedBox(height: 28),
          _insightBox(
            '하루 3시간 이상 야외 활동 시 미세먼지 흡입량이 최대 3배 증가해요. '
            '마스크 불편도를 입력하면 무리한 착용 대신 실질적인 타이밍을 알려드려요.',
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
