import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// 온보딩 마지막 스텝 — 알림 민감도
class StepSensitivity extends StatelessWidget {
  final SensitivityLevel sensitivity;
  final ValueChanged<SensitivityLevel> onChanged;

  const StepSensitivity({
    super.key,
    required this.sensitivity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _SensitivityOption(
        level: SensitivityLevel.low,
        icon: Icons.notifications_off_outlined,
        description: '나쁨 이상일 때만 알림을 받아요',
      ),
      _SensitivityOption(
        level: SensitivityLevel.normal,
        icon: Icons.notifications_outlined,
        description: '기본 기준으로 알림을 받아요',
      ),
      _SensitivityOption(
        level: SensitivityLevel.high,
        icon: Icons.notifications_active_outlined,
        description: '보통 이상이면 미리 알림을 받아요',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '알림은 얼마나 민감하게\n받으시겠어요?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '언제 알림을 드릴지 기준을 정해요. 나중에 바꿀 수 있어요.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          ...options.map((opt) {
            final isSelected = sensitivity == opt.level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => onChanged(opt.level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.divider,
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
                          opt.icon,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.level.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),

          const Spacer(),
        ],
      ),
    );
  }
}

class _SensitivityOption {
  final SensitivityLevel level;
  final IconData icon;
  final String description;
  const _SensitivityOption({
    required this.level,
    required this.icon,
    required this.description,
  });
}
