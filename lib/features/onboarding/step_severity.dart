import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

class StepSeverity extends StatelessWidget {
  final Severity severity;
  final bool isDiagnosed;
  final ValueChanged<Severity> onSeverityChanged;
  final ValueChanged<bool> onDiagnosedChanged;

  const StepSeverity({
    super.key,
    required this.severity,
    required this.isDiagnosed,
    required this.onSeverityChanged,
    required this.onDiagnosedChanged,
  });

  @override
  Widget build(BuildContext context) {
    const descriptions = {
      Severity.mild: '가끔 증상이 있지만 일상생활에 지장이 없어요',
      Severity.moderate: '증상이 자주 있고 관리가 필요해요',
      Severity.severe: '증상이 심하고 활동에 제한이 있어요',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '질환 수준을 선택해 주세요',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '질환 수준에 따라 알림 기준이 더 세밀하게 조정돼요.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          ...Severity.values.map((s) {
            final isSelected = severity == s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSeverityChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
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
                            descriptions[s] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // 병원 진단 여부
          GestureDetector(
            onTap: () => onDiagnosedChanged(!isDiagnosed),
            child: Row(
              children: [
                Checkbox(
                  value: isDiagnosed,
                  onChanged: (v) => onDiagnosedChanged(v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  '병원에서 진단받은 질환이에요',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
