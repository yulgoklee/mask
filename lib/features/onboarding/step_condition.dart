import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

class StepCondition extends StatelessWidget {
  final bool hasCondition;
  final ConditionType conditionType;
  final ValueChanged<bool> onConditionChanged;
  final ValueChanged<ConditionType> onTypeChanged;

  const StepCondition({
    super.key,
    required this.hasCondition,
    required this.conditionType,
    required this.onConditionChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '기저질환이 있으신가요?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '기저질환이 있으면 더 낮은 수치에서도 마스크가 필요할 수 있어요.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // 예/아니오 토글
          Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: '없어요',
                  selected: !hasCondition,
                  onTap: () => onConditionChanged(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleButton(
                  label: '있어요',
                  selected: hasCondition,
                  onTap: () => onConditionChanged(true),
                ),
              ),
            ],
          ),

          // 질환 종류 선택 (있을 때만)
          if (hasCondition) ...[
            const SizedBox(height: 28),
            const Text(
              '어떤 질환인가요?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: ConditionType.values
                    .where((c) => c != ConditionType.none)
                    .map((type) {
                  final isSelected = conditionType == type;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => onTypeChanged(type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
