import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../diagnosis/diagnosis_screen.dart';
import '../diagnosis/result_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final temporaryStates = ref.watch(temporaryStatesProvider);
    final todaySituations = ref.watch(todaySituationProvider);
    final calcResult = ref.watch(dustCalculationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '내 정보',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 4),

          // ── 요약 카드 ───────────────────────────────────────
          _SummaryCard(
            profile: profile,
            calcResult: calcResult,
            temporaryStates: temporaryStates,
            todaySituations: todaySituations,
          ),
          const SizedBox(height: 16),

          // ── 민감도 진단 배너 ─────────────────────────────────
          _DiagnosisBanner(profile: profile),
          const SizedBox(height: 24),

          // ── 오늘 섹션 (Tier 3) ──────────────────────────────
          _SectionHeader(
            title: '오늘',
            badge: '자동 만료',
            tooltip: '오늘 하루가 지나면 자동으로 해제돼요',
          ),
          const SizedBox(height: 10),
          _TodaySection(todaySituations: todaySituations),
          const SizedBox(height: 28),

          // ── 현재 상태 섹션 (Tier 2) ─────────────────────────
          _SectionHeader(
            title: '현재 상태',
            badge: '기간 적용',
            tooltip: '만료일까지 마스크 기준이 달라져요',
          ),
          const SizedBox(height: 10),
          _TemporaryStatesSection(
            temporaryStates: temporaryStates,
            profile: profile,
          ),
          const SizedBox(height: 28),

          // ── 기본 정보 섹션 (Tier 1) ─────────────────────────
          _SectionHeader(
            title: '기본 정보',
            badge: '거의 안 바뀜',
          ),
          const SizedBox(height: 10),
          _BasicInfoSection(profile: profile),
          const SizedBox(height: 16),

          // ── 알림 방해 금지 ─────────────────────────────────
          const _SectionHeader(
            title: '방해 금지',
            badge: '알림 차단',
            tooltip: '설정한 시간대에는 미세먼지 알림을 보내지 않아요',
          ),
          const SizedBox(height: 10),
          const _QuietHoursSection(),
          const SizedBox(height: 24),

          const Text(
            '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단이나 처방을 대체하지 않습니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── 민감도 진단 배너 ────────────────────────────────────────

class _DiagnosisBanner extends StatelessWidget {
  final UserProfile profile;

  const _DiagnosisBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final s = profile.sensitivityIndex;
    final levelLabel = SensitivityCalculator.label(s);
    final tFinal = profile.tFinal;

    // S 레벨에 따른 강조색
    final Color accentColor;
    if (s >= 0.5) {
      accentColor = AppColors.dustBad;
    } else if (s >= 0.3) {
      accentColor = AppColors.dustNormal;
    } else {
      accentColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아이콘
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child:
                    Icon(Icons.shield_outlined, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),

              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '나만의 마스크 기준',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            levelLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tFinal <= 15.0
                          ? '최고 수준의 민감도 적용 중  ·  S = ${s.toStringAsFixed(2)}'
                          : 'PM2.5 ${tFinal.toStringAsFixed(0)} μg/m³ 이상 시 알림  ·  S = ${s.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 액션 버튼 행
          Row(
            children: [
              // 리포트 보기
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ResultScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 15, color: accentColor),
                        const SizedBox(width: 5),
                        Text(
                          '내 리포트 보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 재진단
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DiagnosisScreen(),
                      fullscreenDialog: true,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 15, color: AppColors.textSecondary),
                        SizedBox(width: 5),
                        Text(
                          '재진단',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Evidence link (Remote Config)
          const _EvidenceLink(),
        ],
      ),
    );
  }
}

// ── 요약 카드 ──────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final UserProfile profile;
  final dynamic calcResult;
  final List<TemporaryState> temporaryStates;
  final List<TodaySituation> todaySituations;

  const _SummaryCard({
    required this.profile,
    required this.calcResult,
    required this.temporaryStates,
    required this.todaySituations,
  });

  @override
  Widget build(BuildContext context) {
    final activeStates = temporaryStates.where((s) => s.isActive).toList();
    final activeTodaySituations =
        todaySituations.where((s) => s.isActive).toList();
    final hasAnyState =
        activeStates.isNotEmpty || activeTodaySituations.isNotEmpty;

    final standardLine = calcResult?.maskType != null
        ? '${calcResult!.maskType} 기준 적용 중'
        : '현재 마스크 불필요';

    String stateSummary;
    if (hasAnyState) {
      stateSummary = [
        ...activeTodaySituations.map((s) => s.type.label),
        ...activeStates.map((s) => s.type.label),
      ].join(' · ');
    } else {
      final now = DateTime.now().year;
      final age = now - profile.birthYear;
      final genderLabel = profile.gender == 'male'
          ? '남성'
          : profile.gender == 'female'
              ? '여성'
              : '';
      stateSummary =
          '$age세${genderLabel.isNotEmpty ? ' · $genderLabel' : ''}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('👤', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName
                      : '내 프로필',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stateSummary,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  standardLine,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String badge;
  final String? tooltip;

  const _SectionHeader({
    required this.title,
    required this.badge,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip!,
            child: const Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 오늘 섹션 (Tier 3) — List 기반 ───────────────────────

class _TodaySection extends ConsumerWidget {
  final List<TodaySituation> todaySituations;

  const _TodaySection({required this.todaySituations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTypes =
        todaySituations.where((s) => s.isActive).map((s) => s.type).toSet();

    return Column(
      children: TodaySituationType.values.map((type) {
        final isActive = activeTypes.contains(type);
        return _SettingRow(
          icon: type == TodaySituationType.outdoorExercise ? '🏃' : '🤒',
          title: type.label,
          subtitle: type.description,
          isActive: isActive,
          onToggle: (active) async {
            await ref.read(todaySituationProvider.notifier).toggle(type);
          },
        );
      }).toList(),
    );
  }
}

// ── 현재 상태 섹션 (Tier 2) ───────────────────────────────

class _TemporaryStatesSection extends ConsumerWidget {
  final List<TemporaryState> temporaryStates;
  final UserProfile profile;

  const _TemporaryStatesSection({
    required this.temporaryStates,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTypes = temporaryStates.map((s) => s.type).toSet();

    // 임신 항목은 여성 사용자에게만 표시
    final orderedInactive = TemporaryStateType.values
        .where((t) => !activeTypes.contains(t))
        .where((t) =>
            t != TemporaryStateType.pregnancy ||
            profile.gender == 'female' ||
            profile.gender.isEmpty) // 성별 미선택도 임신 항목 표시
        .toList();
    // 여성 또는 성별 미선택 → 임신 항목 맨 위 정렬
    if (profile.gender == 'female' || profile.gender.isEmpty) {
      orderedInactive.sort((a, b) {
        if (a == TemporaryStateType.pregnancy) return -1;
        if (b == TemporaryStateType.pregnancy) return 1;
        return 0;
      });
    }

    return Column(
      children: [
        // 활성 상태
        ...temporaryStates.map((state) => _ActiveStateTile(
              state: state,
              onRemove: () async {
                final confirmed =
                    await _confirmRemove(context, state.type.label);
                if (confirmed) {
                  await ref
                      .read(temporaryStatesProvider.notifier)
                      .remove(state.type);
                }
              },
            )),

        // 추가 가능한 상태 (여성/미선택은 임신이 맨 위)
        ...orderedInactive.map((type) => _InactiveStateTile(
              type: type,
              highlight: (profile.gender == 'female' || profile.gender.isEmpty) &&
                  type == TemporaryStateType.pregnancy,
              onAdd: () => _showAddSheet(context, type),
            )),
      ],
    );
  }

  Future<bool> _confirmRemove(BuildContext context, String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('상태 해제'),
            content: Text('$label 상태를 해제할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('해제',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAddSheet(BuildContext context, TemporaryStateType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStateSheet(type: type),
    );
  }
}

// ── 활성 기간 상태 타일 ────────────────────────────────────

class _ActiveStateTile extends StatelessWidget {
  final TemporaryState state;
  final VoidCallback onRemove;

  const _ActiveStateTile({required this.state, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final expiryText = state.expiryDate != null
        ? '${state.expiryDate!.month}/${state.expiryDate!.day}까지'
        : '수동 해제 전까지';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.type.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      expiryText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── 비활성 기간 상태 타일 ──────────────────────────────────

class _InactiveStateTile extends StatelessWidget {
  final TemporaryStateType type;
  final VoidCallback onAdd;
  final bool highlight;

  const _InactiveStateTile({
    required this.type,
    required this.onAdd,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              highlight ? Icons.pregnant_woman : Icons.add,
              color: highlight ? AppColors.primary : Colors.grey.shade400,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: highlight
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  type.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '추가',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 기본 정보 섹션 (Tier 1) — 자동 저장 ─────────────────

class _BasicInfoSection extends ConsumerWidget {
  final UserProfile profile;

  const _BasicInfoSection({required this.profile});

  void _save(BuildContext context, WidgetRef ref, UserProfile updated) {
    ref.read(profileProvider.notifier).update(updated);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('저장됐어요'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 성별 ────────────────────────────────────────────
        _FieldLabel('성별'),
        const SizedBox(height: 8),
        _ChipGroup<String>(
          values: const ['male', 'female', 'other'],
          selected: profile.gender,
          labelOf: (v) => v == 'male' ? '남성' : v == 'female' ? '여성' : '기타',
          onSelect: (v) => _save(context, ref, profile.copyWith(gender: v)),
        ),
        const SizedBox(height: 20),

        // ── 출생연도 ─────────────────────────────────────────
        _FieldLabel('출생연도'),
        const SizedBox(height: 8),
        _BirthYearPicker(
          birthYear: profile.birthYear,
          onChanged: (year) => _save(context, ref, profile.copyWith(birthYear: year)),
        ),
        const SizedBox(height: 20),

        // ── 호흡기 상태 ──────────────────────────────────────
        _FieldLabel('호흡기 상태'),
        const SizedBox(height: 8),
        _ChipGroup<int>(
          values: const [0, 1, 2, 3],
          selected: profile.respiratoryStatus,
          labelOf: (v) => switch (v) {
            1 => '비염',
            2 => '천식 등',
            3 => '비염+천식',
            _ => '건강해요',
          },
          onSelect: (v) => _save(context, ref, profile.copyWith(respiratoryStatus: v)),
        ),
        const SizedBox(height: 20),

        // ── 야외 활동량 ──────────────────────────────────────
        _FieldLabel('야외 활동 시간'),
        const SizedBox(height: 8),
        _ChipGroup<int>(
          values: const [0, 1, 2],
          selected: profile.outdoorMinutes,
          labelOf: (v) => v == 0 ? '1시간 미만' : v == 1 ? '1~3시간' : '3시간 이상',
          onSelect: (v) => _save(context, ref, profile.copyWith(outdoorMinutes: v)),
        ),
        const SizedBox(height: 20),

        // ── 알림 민감도 ──────────────────────────────────────
        _FieldLabel('체감 민감도'),
        const SizedBox(height: 4),
        const Text(
          '높을수록 더 낮은 수치에서 알림을 보내요.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        _ChipGroup<int>(
          values: const [0, 1, 2],
          selected: profile.sensitivityLevel,
          labelOf: (v) => v == 0 ? '무던해요' : v == 1 ? '보통이에요' : '매우 예민해요',
          onSelect: (v) => _save(context, ref, profile.copyWith(sensitivityLevel: v)),
        ),
        const SizedBox(height: 20),

        // ── 마스크 불편함 ─────────────────────────────────────
        _FieldLabel('마스크 불편 정도'),
        const SizedBox(height: 8),
        _ChipGroup<int>(
          values: const [0, 1, 2],
          selected: profile.discomfortLevel,
          labelOf: (v) => v == 0 ? '안 느껴요' : v == 1 ? '보통이에요' : '많이 불편해요',
          onSelect: (v) => _save(context, ref, profile.copyWith(discomfortLevel: v)),
        ),
      ],
    );
  }
}

// ── 출생연도 피커 ──────────────────────────────────────────

class _BirthYearPicker extends StatelessWidget {
  final int birthYear;
  final ValueChanged<int> onChanged;

  const _BirthYearPicker({
    required this.birthYear,
    required this.onChanged,
  });

  void _showPicker(BuildContext context) {
    final now = DateTime.now().year;
    int tempYear = birthYear;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Text('출생연도',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        onChanged(tempYear);
                        Navigator.pop(context);
                      },
                      child: const Text('확인',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: birthYear - (now - 90),
                  ),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) {
                    tempYear = (now - 90) + i;
                  },
                  children: List.generate(
                    91,
                    (i) {
                      final year = (now - 90) + i;
                      return Center(
                        child: Text(
                          '$year년',
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final age = now - birthYear;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              '$birthYear년',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '만 $age세',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── 공통 설정 행 (Switch) ─────────────────────────────────

class _SettingRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Text(icon, style: const TextStyle(fontSize: 22)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: onToggle,
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ── 기간 상태 추가 바텀시트 ────────────────────────────────

class _AddStateSheet extends ConsumerStatefulWidget {
  final TemporaryStateType type;

  const _AddStateSheet({required this.type});

  @override
  ConsumerState<_AddStateSheet> createState() => _AddStateSheetState();
}

class _AddStateSheetState extends ConsumerState<_AddStateSheet> {
  DateTime? _expiryDate;
  bool _noExpiry = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == TemporaryStateType.skinProcedureRecovery) {
      _expiryDate = DateTime.now().add(const Duration(days: 7));
    }
    if (widget.type == TemporaryStateType.immunoSuppressed) {
      _noExpiry = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.type.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.type.description,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          if (!_noExpiry) ...[
            const Text(
              '언제까지 적용할까요?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _expiryDate != null
                          ? '${_expiryDate!.year}년 ${_expiryDate!.month}월 ${_expiryDate!.day}일'
                          : '만료일 선택 (선택사항)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _expiryDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Checkbox(
                value: _noExpiry,
                onChanged: (v) => setState(() {
                  _noExpiry = v ?? false;
                  if (_noExpiry) _expiryDate = null;
                }),
                activeColor: AppColors.primary,
              ),
              const Text(
                '만료일 없이 유지 (수동으로 해제)',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AppButton.primary(
            label: '적용하기',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate:
            _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        locale: const Locale('ko', 'KR'),
      );
      if (picked != null && mounted) {
        setState(() => _expiryDate = picked);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('날짜 선택을 불러올 수 없어요. 만료일 없이 적용할 수 있어요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final state = TemporaryState(
      type: widget.type,
      startDate: DateTime.now(),
      expiryDate: _noExpiry ? null : _expiryDate,
    );
    try {
      await ref.read(temporaryStatesProvider.notifier).add(state);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }
}

// ── 공통 UI 컴포넌트 ──────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Evidence link — Remote Config URL ────────────────────
class _EvidenceLink extends StatefulWidget {
  const _EvidenceLink();

  @override
  State<_EvidenceLink> createState() => _EvidenceLinkState();
}

class _EvidenceLinkState extends State<_EvidenceLink> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  Future<void> _fetchUrl() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 12),
      ));
      await rc.fetchAndActivate();
      final url = rc.getString('sensitivity_evidence_url');
      if (url.isNotEmpty && mounted) {
        setState(() => _url = url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.tryParse(_url!);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.science_outlined, size: 13, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              '민감도 산출 근거 보기',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 방해 금지 시간 설정 ──────────────────────────────────
class _QuietHoursSection extends ConsumerWidget {
  const _QuietHoursSection();

  String _fmt(int hour) {
    final suffix = hour < 12 ? '오전' : '오후';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$suffix ${display}시';
  }

  Future<void> _pickHour(
    BuildContext context,
    WidgetRef ref,
    NotificationSetting setting,
    bool isStart,
  ) async {
    final initial = TimeOfDay(
        hour: isStart ? setting.quietHoursStartHour : setting.quietHoursEndHour,
        minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? '방해 금지 시작 시간' : '방해 금지 종료 시간',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    ref.read(notificationSettingProvider.notifier).update(
          isStart
              ? setting.copyWith(quietHoursStartHour: picked.hour)
              : setting.copyWith(quietHoursEndHour: picked.hour),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('방해 금지 시간이 저장됐어요'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    final enabled = setting.quietHoursEnabled;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: const Text('🌙', style: TextStyle(fontSize: 22)),
            title: Text(
              '방해 금지 시간',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              '이 시간대에는 모든 알림을 차단해요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: Switch(
              value: enabled,
              onChanged: (v) {
                ref
                    .read(notificationSettingProvider.notifier)
                    .update(setting.copyWith(quietHoursEnabled: v));
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v ? '방해 금지가 켜졌어요' : '방해 금지가 꺼졌어요'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: '시작',
                      time: _fmt(setting.quietHoursStartHour),
                      onTap: () => _pickHour(context, ref, setting, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeChip(
                      label: '종료',
                      time: _fmt(setting.quietHoursEndHour),
                      onTap: () => _pickHour(context, ref, setting, false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  const _ChipGroup({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelOf(v),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
