import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

class StepLifestyle extends StatelessWidget {
  final ActivityLevel activityLevel;
  final ValueChanged<ActivityLevel> onChanged;

  const StepLifestyle({
    super.key,
    required this.activityLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const icons = {
      ActivityLevel.low: Icons.home_outlined,
      ActivityLevel.normal: Icons.directions_walk,
      ActivityLevel.high: Icons.directions_run,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '야외 활동 빈도는 어떻게 되나요?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '야외 활동이 많을수록 미세먼지 노출 위험이 높아져요.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          ...ActivityLevel.values.map((level) {
            final isSelected = activityLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : AppColors.surface,
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
                          icons[level],
                          color:
                              isSelected ? Colors.white : AppColors.textSecondary,
                          size: 26,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
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
