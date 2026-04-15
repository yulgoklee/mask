import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// 3단계 — 특별 상태 진단 (w_spec)
///
/// "현재 특별히 보호가 필요한 상태인가요?"
/// 임신 중 / 피부 시술 후 2주 내 / 영유아·고령자 부양
class StepSpecialState extends StatelessWidget {
  final bool isPregnant;          // conditionType == pregnancy
  final bool hasSkinProcedure;
  final bool hasDependents;
  final Gender? gender;
  final ValueChanged<bool> onPregnantChanged;
  final ValueChanged<bool> onSkinProcedureChanged;
  final ValueChanged<bool> onDependentsChanged;

  const StepSpecialState({
    super.key,
    required this.isPregnant,
    required this.hasSkinProcedure,
    required this.hasDependents,
    this.gender,
    required this.onPregnantChanged,
    required this.onSkinProcedureChanged,
    required this.onDependentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showPregnancy =
        gender == null || gender == Gender.female;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _questionBadge('특별 상태'),
          const SizedBox(height: 12),
          Text(
            '지금 특별히\n보호가 필요한 상태인가요?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '해당하는 항목이 있으면 알림 기준을 더 세밀하게 설정해드려요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),

          // ── 임신 중 (여성 또는 성별 미선택 시만 노출) ──────
          if (showPregnancy)
            _StateCard(
              emoji: '🤰',
              label: '임신 중이에요',
              subLabel: '태아 보호를 위해 기준을 30% 강화해요',
              badge: '–30%',
              badgeColor: AppColors.coral,
              selected: isPregnant,
              onTap: () => onPregnantChanged(!isPregnant),
            ),

          if (showPregnancy) const SizedBox(height: 12),

          // ── 피부 시술 ──────────────────────────────────────
          _StateCard(
            emoji: '✨',
            label: '최근 2주 내 피부 시술을 받았어요',
            subLabel: '시술 후 피부 장벽이 약해져 미세먼지 영향이 커요',
            badge: '–25%',
            badgeColor: AppColors.coral,
            selected: hasSkinProcedure,
            onTap: () => onSkinProcedureChanged(!hasSkinProcedure),
          ),

          const SizedBox(height: 12),

          // ── 영유아·고령자 부양 ─────────────────────────────
          _StateCard(
            emoji: '👶🏻👴',
            label: '영유아 또는 고령자와 함께 살아요',
            subLabel: '함께 사는 가족의 건강까지 고려해 알림을 조정해요',
            badge: '–15%',
            badgeColor: AppColors.secondary,
            selected: hasDependents,
            onTap: () => onDependentsChanged(!hasDependents),
          ),

          const SizedBox(height: 12),

          // ── 해당 없음 ──────────────────────────────────────
          GestureDetector(
            onTap: () {
              onPregnantChanged(false);
              onSkinProcedureChanged(false);
              onDependentsChanged(false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (!isPregnant && !hasSkinProcedure && !hasDependents)
                    ? AppColors.surfaceVariant
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (!isPregnant && !hasSkinProcedure && !hasDependents)
                      ? AppColors.primary
                      : AppColors.divider,
                  width: (!isPregnant && !hasSkinProcedure && !hasDependents)
                      ? 2
                      : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('👌', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '해당 사항이 없어요',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: (!isPregnant && !hasSkinProcedure && !hasDependents)
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
            '임신 중에는 미세먼지가 태반을 통해 태아에게 영향을 줄 수 있어요. '
            '피부 시술 직후에는 피부 장벽이 약해져 외부 오염물질 흡수가 늘어납니다.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subLabel;
  final String badge;
  final Color badgeColor;
  final bool selected;
  final VoidCallback onTap;

  const _StateCard({
    required this.emoji,
    required this.label,
    required this.subLabel,
    required this.badge,
    required this.badgeColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? badgeColor.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? badgeColor : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color:
                          selected ? badgeColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 가중치 배지
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? badgeColor
                    : badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : badgeColor,
                ),
              ),
            ),
          ],
        ),
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
