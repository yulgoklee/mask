import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// 4단계 — 생활 환경 (야외 활동량 + 마스크 편의 성향)
///
/// w2: ActivityLevel → 낮음 0.0 / 보통 +0.1 / 높음 +0.2
/// w_pref: maskDiscomfort → 답답함 심하면 T_final 소폭 완화 (−0.08)
class StepLifestyle extends StatelessWidget {
  final ActivityLevel activityLevel;
  final bool maskDiscomfort;
  final ValueChanged<ActivityLevel> onActivityChanged;
  final ValueChanged<bool> onMaskDiscomfortChanged;

  const StepLifestyle({
    super.key,
    required this.activityLevel,
    required this.maskDiscomfort,
    required this.onActivityChanged,
    required this.onMaskDiscomfortChanged,
  });

  static const _activityIcons = {
    ActivityLevel.low:    Icons.home_outlined,
    ActivityLevel.normal: Icons.directions_walk,
    ActivityLevel.high:   Icons.directions_run,
  };

  static const _activityBadge = {
    ActivityLevel.low:    '+0%',
    ActivityLevel.normal: '+10%',
    ActivityLevel.high:   '+20%',
  };

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

          // ── 활동량 선택 카드 ──────────────────────────────
          ...ActivityLevel.values.map((level) {
            final isSelected = activityLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onActivityChanged(level),
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
                          _activityIcons[level],
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
                              level.label,
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
                              level.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 가중치 배지
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
                          _activityBadge[level]!,
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

          // ── 마스크 편의 성향 ──────────────────────────────
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
            '답답함·김 서림이 심하면 알림 기준을 조금 완화해드려요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          // 답답함 있음
          GestureDetector(
            onTap: () => onMaskDiscomfortChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: maskDiscomfort
                    ? AppColors.coral.withValues(alpha: 0.07)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: maskDiscomfort ? AppColors.coral : AppColors.divider,
                  width: maskDiscomfort ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('😮‍💨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '마스크가 좀 답답해요',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: maskDiscomfort
                                ? AppColors.coral
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '김 서림·압박감이 심해서 오래 착용하기 힘들어요',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: maskDiscomfort
                          ? AppColors.coral
                          : AppColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '완화',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: maskDiscomfort ? Colors.white : AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 문제없음
          GestureDetector(
            onTap: () => onMaskDiscomfortChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: !maskDiscomfort
                    ? AppColors.primary.withValues(alpha: 0.07)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !maskDiscomfort ? AppColors.primary : AppColors.divider,
                  width: !maskDiscomfort ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('😤', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '마스크 착용에 문제없어요',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: !maskDiscomfort
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
