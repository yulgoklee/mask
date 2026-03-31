import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late UserProfile _profile;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _profile = ref.read(profileProvider);
  }

  void _update(UserProfile updated) {
    setState(() {
      _profile = updated;
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).saveProfile(_profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었어요.')),
      );
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '건강 프로필',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _save,
              child: const Text(
                '저장',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('나이대'),
          const SizedBox(height: 10),
          _ChipGroup<AgeGroup>(
            values: AgeGroup.values,
            selected: _profile.ageGroup,
            labelOf: (v) => v.label,
            onSelect: (v) => _update(_profile.copyWith(ageGroup: v)),
          ),
          const SizedBox(height: 24),

          _SectionLabel('기저질환'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToggleChip(
                  label: '없음',
                  selected: !_profile.hasCondition,
                  onTap: () => _update(_profile.copyWith(
                    hasCondition: false,
                    conditionType: ConditionType.none,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToggleChip(
                  label: '있음',
                  selected: _profile.hasCondition,
                  onTap: () =>
                      _update(_profile.copyWith(hasCondition: true)),
                ),
              ),
            ],
          ),
          if (_profile.hasCondition) ...[
            const SizedBox(height: 16),
            _SectionLabel('질환 종류'),
            const SizedBox(height: 10),
            _ChipGroup<ConditionType>(
              values: ConditionType.values
                  .where((c) => c != ConditionType.none)
                  .toList(),
              selected: _profile.conditionType,
              labelOf: (v) => v.label,
              onSelect: (v) => _update(_profile.copyWith(conditionType: v)),
            ),
            const SizedBox(height: 16),
            _SectionLabel('질환 수준'),
            const SizedBox(height: 10),
            _ChipGroup<Severity>(
              values: Severity.values,
              selected: _profile.severity,
              labelOf: (v) => v.label,
              onSelect: (v) => _update(_profile.copyWith(severity: v)),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _profile.isDiagnosed,
              onChanged: (v) =>
                  _update(_profile.copyWith(isDiagnosed: v ?? false)),
              title: const Text('병원 진단받은 질환'),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          const SizedBox(height: 24),

          _SectionLabel('야외 활동 빈도'),
          const SizedBox(height: 10),
          _ChipGroup<ActivityLevel>(
            values: ActivityLevel.values,
            selected: _profile.activityLevel,
            labelOf: (v) => v.label,
            onSelect: (v) => _update(_profile.copyWith(activityLevel: v)),
          ),
          const SizedBox(height: 24),

          _SectionLabel('알림 민감도'),
          const SizedBox(height: 6),
          const Text(
            '민감도가 높을수록 더 낮은 수치에서도 알림을 보내요.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _ChipGroup<SensitivityLevel>(
            values: SensitivityLevel.values,
            selected: _profile.sensitivity,
            labelOf: (v) => v.label,
            onSelect: (v) => _update(_profile.copyWith(sensitivity: v)),
          ),
          const SizedBox(height: 40),

          const Text(
            '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단이나 처방을 대체하지 않습니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
      spacing: 10,
      runSpacing: 10,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color:
                    isSelected ? AppColors.primary : AppColors.divider,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelOf(v),
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
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
          border:
              Border.all(color: selected ? AppColors.primary : AppColors.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
