import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// 온보딩 Step 2 — 성별 선택
///
/// 성별 정보는 임신 등 여성 특화 취약 상태를 노출할지 결정하는 데 사용된다.
/// 선택하지 않아도 다음 단계로 진행할 수 있다.
class StepGender extends StatelessWidget {
  final Gender? selected;
  final ValueChanged<Gender?> onChanged;

  const StepGender({
    super.key,
    required this.selected,
    required this.onChanged,
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
            '성별을 알려주세요',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '임신 등 여성 특화 취약 상태를 맞춤 적용하는 데 사용해요.\n선택하지 않아도 괜찮아요.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // 성별 버튼 3종
          Row(
            children: Gender.values.map((g) {
              final isSelected = selected == g;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: g != Gender.values.last ? 10 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () =>
                        // 이미 선택된 항목 탭 → 선택 해제 (null)
                        onChanged(isSelected ? null : g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _emoji(g),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            g.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
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

          const SizedBox(height: 20),

          // 선택 안 함 안내
          Center(
            child: TextButton(
              onPressed: () => onChanged(null),
              child: const Text(
                '선택 안 함',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emoji(Gender g) {
    switch (g) {
      case Gender.male:   return '👨';
      case Gender.female: return '👩';
      case Gender.other:  return '🧑';
    }
  }
}
