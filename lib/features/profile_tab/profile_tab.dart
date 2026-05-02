import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../../data/models/user_profile.dart';
import '../../core/services/app_logger.dart';
import '../../providers/providers.dart';
import '../../widgets/sensitivity_widgets.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final temporaryStates = ref.watch(temporaryStatesProvider);
    final todaySituations = ref.watch(todaySituationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '프로필',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          // ── 보기 영역 ────────────────────────────────────────
          ProfileStateHeader(profile: profile),
          const SizedBox(height: 16),
          ThresholdCompareCard(profile: profile),
          const SizedBox(height: 16),
          SensitivityBreakdown(profile: profile),
          const SizedBox(height: 12),
          SensitivityActionGuide(profile: profile),
          const SizedBox(height: 20),

          // ── 프로필 수정 진입 ─────────────────────────────────
          _EditProfileButton(),
          const SizedBox(height: 28),

          const Divider(color: AppColors.divider),
          const SizedBox(height: 20),

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

          // ── 오늘 섹션 (Tier 3) ──────────────────────────────
          _SectionHeader(
            title: '오늘',
            badge: '자동 만료',
            tooltip: '오늘 하루가 지나면 자동으로 해제돼요',
          ),
          const SizedBox(height: 10),
          _TodaySection(todaySituations: todaySituations),
          const SizedBox(height: 28),

          // ── 방해 금지 ────────────────────────────────────────
          const _SectionHeader(
            title: '방해 금지',
            badge: '알림 차단',
            tooltip: '설정한 시간대에는 미세먼지 알림을 보내지 않아요',
          ),
          const SizedBox(height: 10),
          const _QuietHoursSection(),
          const SizedBox(height: 24),

          // ── 법적 고지 ────────────────────────────────────────
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

// ── 프로필 수정 진입 버튼 ──────────────────────────────────

class _EditProfileButton extends StatefulWidget {
  @override
  State<_EditProfileButton> createState() => _EditProfileButtonState();
}

class _EditProfileButtonState extends State<_EditProfileButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        context.push('/profile/edit');
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프로필 수정하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '기본 정보 · 건강 상태 수정',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
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

// ── 오늘 섹션 (Tier 3) ───────────────────────────────────

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

    final orderedInactive = TemporaryStateType.values
        .where((t) => !activeTypes.contains(t))
        .where((t) =>
            t != TemporaryStateType.pregnancy ||
            profile.gender == 'female' ||
            profile.gender.isEmpty)
        .toList();

    if (profile.gender == 'female' || profile.gender.isEmpty) {
      orderedInactive.sort((a, b) {
        if (a == TemporaryStateType.pregnancy) return -1;
        if (b == TemporaryStateType.pregnancy) return 1;
        return 0;
      });
    }

    return Column(
      children: [
        ...temporaryStates.map((state) => _ActiveStateTile(
              state: state,
              onRemove: () async {
                final confirmed =
                    await _confirmRemove(context, state.type.label);
                if (confirmed) {
                  await ref
                      .read(temporaryStatesProvider.notifier)
                      .remove(state.type);
                  if (state.type == TemporaryStateType.pregnancy) {
                    ref.read(profileProvider.notifier).update(
                          profile.copyWith(isPregnant: false));
                  }
                }
              },
            )),
        ...orderedInactive.map((type) => _InactiveStateTile(
              type: type,
              highlight: (profile.gender == 'female' ||
                      profile.gender.isEmpty) &&
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('적용하기',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
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
    } catch (e, st) {
      AppLogger.error(e, st, reason: 'temporary_state_add');
    }
    if (widget.type == TemporaryStateType.pregnancy) {
      final p = ref.read(profileProvider);
      ref.read(profileProvider.notifier).update(p.copyWith(isPregnant: true));
    }
    if (mounted) Navigator.pop(context);
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
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.white,
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

  const _TimeChip(
      {required this.label, required this.time, required this.onTap});

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
