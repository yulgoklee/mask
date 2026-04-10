import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Tier 1 — 로컬 상태 (저장 버튼 누를 때만 반영)
  late UserProfile _profile;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _profile = ref.read(profileProvider);
  }

  void _updateTier1(UserProfile updated) {
    setState(() {
      _profile = updated;
      _hasChanges = true;
    });
  }

  Future<void> _saveTier1() async {
    await ref.read(profileProvider.notifier).saveProfile(_profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기본 정보가 저장되었어요.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temporaryStates = ref.watch(temporaryStatesProvider);
    final todaySituation = ref.watch(todaySituationProvider);
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
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveTier1,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 4),

          // ── 요약 카드 ───────────────────────────────────────
          _SummaryCard(
            profile: _profile,
            calcResult: calcResult,
            temporaryStates: temporaryStates,
            todaySituation: todaySituation,
          ),
          const SizedBox(height: 24),

          // ── 오늘 섹션 (Tier 3) ──────────────────────────────
          _SectionHeader(
            title: '오늘',
            badge: '자동 만료',
            tooltip: '오늘 하루가 지나면 자동으로 해제돼요',
          ),
          const SizedBox(height: 10),
          _TodaySection(todaySituation: todaySituation),
          const SizedBox(height: 28),

          // ── 현재 상태 섹션 (Tier 2) ─────────────────────────
          _SectionHeader(
            title: '현재 상태',
            badge: '기간 적용',
            tooltip: '만료일까지 마스크 기준이 달라져요',
          ),
          const SizedBox(height: 10),
          _TemporaryStatesSection(temporaryStates: temporaryStates),
          const SizedBox(height: 28),

          // ── 기본 정보 섹션 (Tier 1) ─────────────────────────
          _SectionHeader(
            title: '기본 정보',
            badge: '거의 안 바뀜',
          ),
          const SizedBox(height: 10),
          _BasicInfoSection(
            profile: _profile,
            onUpdate: _updateTier1,
          ),
          const SizedBox(height: 16),

          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: _saveTier1,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '기본 정보 저장',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 8),
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

// ── 요약 카드 ──────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final UserProfile profile;
  final dynamic calcResult;
  final List<TemporaryState> temporaryStates;
  final TodaySituation? todaySituation;

  const _SummaryCard({
    required this.profile,
    required this.calcResult,
    required this.temporaryStates,
    required this.todaySituation,
  });

  @override
  Widget build(BuildContext context) {
    final activeStates = temporaryStates.where((s) => s.isActive).toList();
    final hasTodaySit = todaySituation?.isActive == true;
    final hasAnyState = activeStates.isNotEmpty || hasTodaySit;

    // 현재 적용 중인 마스크 기준 한 줄
    final standardLine = calcResult?.maskType != null
        ? '${calcResult!.maskType} 기준 적용 중'
        : '현재 마스크 불필요';

    // 상태 요약 텍스트
    final stateSummary = hasAnyState
        ? [
            if (hasTodaySit) todaySituation!.type.label,
            ...activeStates.map((s) => s.type.label),
          ].join(' · ')
        : profile.ageGroup.label;

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
                  profile.name != null && profile.name!.isNotEmpty
                      ? '${profile.name}님'
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

// ── 오늘 섹션 (Tier 3) ────────────────────────────────────

class _TodaySection extends ConsumerWidget {
  final TodaySituation? todaySituation;

  const _TodaySection({required this.todaySituation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: TodaySituationType.values.map((type) {
        final isActive = todaySituation?.isActive == true &&
            todaySituation?.type == type;
        return _SettingRow(
          icon: type == TodaySituationType.outdoorExercise ? '🏃' : '🤒',
          title: type.label,
          subtitle: type.description,
          isActive: isActive,
          onToggle: (active) async {
            if (active) {
              await ref.read(todaySituationProvider.notifier).set(type);
            } else {
              await ref.read(todaySituationProvider.notifier).clear();
            }
          },
        );
      }).toList(),
    );
  }
}

// ── 현재 상태 섹션 (Tier 2) ───────────────────────────────

class _TemporaryStatesSection extends ConsumerWidget {
  final List<TemporaryState> temporaryStates;

  const _TemporaryStatesSection({required this.temporaryStates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTypes = temporaryStates.map((s) => s.type).toSet();

    return Column(
      children: [
        // 활성 상태
        ...temporaryStates.map((state) => _ActiveStateTile(
              state: state,
              onRemove: () async {
                final confirmed = await _confirmRemove(context, state.type.label);
                if (confirmed) {
                  await ref
                      .read(temporaryStatesProvider.notifier)
                      .remove(state.type);
                }
              },
            )),

        // 추가 가능한 상태
        ...TemporaryStateType.values
            .where((t) => !activeTypes.contains(t))
            .map((type) => _InactiveStateTile(
                  type: type,
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
        borderRadius: BorderRadius.circular(12),
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

  const _InactiveStateTile({required this.type, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.grey.shade400, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

// ── 기본 정보 섹션 (Tier 1) ───────────────────────────────

class _BasicInfoSection extends StatelessWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onUpdate;

  const _BasicInfoSection({
    required this.profile,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('나이대'),
        const SizedBox(height: 8),
        _ChipGroup<AgeGroup>(
          values: AgeGroup.values,
          selected: profile.ageGroup,
          labelOf: (v) => v.label,
          onSelect: (v) => onUpdate(profile.copyWith(ageGroup: v)),
        ),
        const SizedBox(height: 20),

        _FieldLabel('기저질환'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToggleChip(
                label: '없음',
                selected: !profile.hasCondition,
                onTap: () => onUpdate(profile.copyWith(
                  hasCondition: false,
                  conditionType: ConditionType.none,
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleChip(
                label: '있음',
                selected: profile.hasCondition,
                onTap: () => onUpdate(profile.copyWith(hasCondition: true)),
              ),
            ),
          ],
        ),
        if (profile.hasCondition) ...[
          const SizedBox(height: 14),
          _FieldLabel('질환 종류'),
          const SizedBox(height: 8),
          _ChipGroup<ConditionType>(
            values: ConditionType.values
                .where((c) => c != ConditionType.none)
                .toList(),
            selected: profile.conditionType,
            labelOf: (v) => v.label,
            onSelect: (v) => onUpdate(profile.copyWith(conditionType: v)),
          ),
          const SizedBox(height: 14),
          _FieldLabel('질환 수준'),
          const SizedBox(height: 8),
          _ChipGroup<Severity>(
            values: Severity.values,
            selected: profile.severity,
            labelOf: (v) => v.label,
            onSelect: (v) => onUpdate(profile.copyWith(severity: v)),
          ),
          CheckboxListTile(
            value: profile.isDiagnosed,
            onChanged: (v) =>
                onUpdate(profile.copyWith(isDiagnosed: v ?? false)),
            title: const Text('병원 진단받은 질환',
                style: TextStyle(fontSize: 14)),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
        const SizedBox(height: 20),

        _FieldLabel('야외 활동 빈도'),
        const SizedBox(height: 8),
        _ChipGroup<ActivityLevel>(
          values: ActivityLevel.values,
          selected: profile.activityLevel,
          labelOf: (v) => v.label,
          onSelect: (v) => onUpdate(profile.copyWith(activityLevel: v)),
        ),
        const SizedBox(height: 20),

        _FieldLabel('알림 민감도'),
        const SizedBox(height: 4),
        const Text(
          '높을수록 더 낮은 수치에서 알림을 보내요.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        _ChipGroup<SensitivityLevel>(
          values: SensitivityLevel.values,
          selected: profile.sensitivity,
          labelOf: (v) => v.label,
          onSelect: (v) => onUpdate(profile.copyWith(sensitivity: v)),
        ),
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
        borderRadius: BorderRadius.circular(12),
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
            color:
                isActive ? AppColors.primary : AppColors.textPrimary,
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
          // 핸들
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '적용하기',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
