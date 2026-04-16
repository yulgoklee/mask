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
          // ── 내 기준선 요약 카드 ──────────────────────────────
          _TFinalSummaryCard(profile: _profile),
          const SizedBox(height: 28),

          // ── 닉네임 ──────────────────────────────────────────
          _SectionLabel('닉네임'),
          const SizedBox(height: 10),
          _NicknameField(
            value: _profile.nickname,
            onChanged: (v) => _update(_profile.copyWith(nickname: v)),
          ),
          const SizedBox(height: 24),

          // ── 성별 ─────────────────────────────────────────────
          _SectionLabel('성별'),
          const SizedBox(height: 10),
          _ChipGroup<String>(
            values: const ['male', 'female'],
            selected: _profile.gender,
            labelOf: (v) => v == 'male' ? '남성' : '여성',
            onSelect: (v) => _update(_profile.copyWith(
              gender: v,
              isPregnant: v == 'male' ? false : _profile.isPregnant,
            )),
          ),
          const SizedBox(height: 24),

          // ── 호흡기 상태 ──────────────────────────────────────
          _SectionLabel('호흡기 상태'),
          const SizedBox(height: 10),
          _ChipGroup<int>(
            values: const [0, 1, 2],
            selected: _profile.respiratoryStatus,
            labelOf: (v) => switch (v) {
              0 => '튼튼해요',
              1 => '비염 있어요',
              _ => '천식 등 질환',
            },
            onSelect: (v) =>
                _update(_profile.copyWith(respiratoryStatus: v)),
          ),
          const SizedBox(height: 24),

          // ── 체감 민감도 ──────────────────────────────────────
          _SectionLabel('체감 민감도'),
          const SizedBox(height: 6),
          const Text(
            '예민할수록 기준선이 더 낮아져요.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _ChipGroup<int>(
            values: const [0, 1, 2],
            selected: _profile.sensitivityLevel,
            labelOf: (v) => switch (v) {
              0 => '무던해요',
              1 => '보통이에요',
              _ => '매우 예민해요',
            },
            onSelect: (v) =>
                _update(_profile.copyWith(sensitivityLevel: v)),
          ),
          const SizedBox(height: 24),

          // ── 임신 여부 (여성 전용) ─────────────────────────────
          if (_profile.gender == 'female') ...[
            _SectionLabel('임신 여부'),
            const SizedBox(height: 10),
            _ChipGroup<bool>(
              values: const [false, true],
              selected: _profile.isPregnant,
              labelOf: (v) => v ? '임신 중' : '해당 없음',
              onSelect: (v) =>
                  _update(_profile.copyWith(isPregnant: v)),
            ),
            const SizedBox(height: 24),
          ],

          // ── 피부 시술 ────────────────────────────────────────
          _SectionLabel('최근 피부 시술 (2주 내)'),
          const SizedBox(height: 10),
          _ChipGroup<bool>(
            values: const [false, true],
            selected: _profile.recentSkinTreatment,
            labelOf: (v) => v ? '받았어요' : '없어요',
            onSelect: (v) =>
                _update(_profile.copyWith(recentSkinTreatment: v)),
          ),
          const SizedBox(height: 24),

          // ── 야외 활동 시간 ────────────────────────────────────
          _SectionLabel('하루 야외 활동 시간'),
          const SizedBox(height: 10),
          _ChipGroup<int>(
            values: const [0, 1, 2],
            selected: _profile.outdoorMinutes,
            labelOf: (v) => switch (v) {
              0 => '30분 미만',
              1 => '1~3시간',
              _ => '3시간 이상',
            },
            onSelect: (v) =>
                _update(_profile.copyWith(outdoorMinutes: v)),
          ),
          const SizedBox(height: 24),

          // ── 활동 성격 (멀티) ─────────────────────────────────
          _SectionLabel('활동 성격'),
          const SizedBox(height: 10),
          _MultiChipGroup(
            options: const [
              ActivityTag.commute,
              ActivityTag.walk,
              ActivityTag.exercise,
            ],
            selected: _profile.activityTags,
            labelOf: ActivityTag.label,
            onChanged: (v) =>
                _update(_profile.copyWith(activityTags: v)),
          ),
          const SizedBox(height: 24),

          // ── 마스크 불편함 ─────────────────────────────────────
          _SectionLabel('마스크 착용감'),
          const SizedBox(height: 10),
          _ChipGroup<int>(
            values: const [0, 1, 2],
            selected: _profile.discomfortLevel,
            labelOf: (v) => switch (v) {
              0 => '괜찮아요',
              1 => '가끔 답답해요',
              _ => '매우 답답해요',
            },
            onSelect: (v) =>
                _update(_profile.copyWith(discomfortLevel: v)),
          ),
          const SizedBox(height: 40),

          const Text(
            '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단이나 처방을 대체하지 않습니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── T_final 요약 카드 ────────────────────────────────────────

class _TFinalSummaryCard extends StatelessWidget {
  final UserProfile profile;
  const _TFinalSummaryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.splashBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.splashBackground.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: '나의 기준선 '),
                      TextSpan(
                        text:
                            '${profile.tFinal.toStringAsFixed(1)} μg/m³',
                        style: const TextStyle(
                          color: AppColors.splashBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                          text: '  (S = ${profile.sensitivityIndex.toStringAsFixed(2)})'),
                    ],
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

// ── 닉네임 필드 ───────────────────────────────────────────────

class _NicknameField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _NicknameField({required this.value, required this.onChanged});

  @override
  State<_NicknameField> createState() => _NicknameFieldState();
}

class _NicknameFieldState extends State<_NicknameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      maxLength: 10,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: '닉네임 (2~10자)',
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        counterText: '',
      ),
    );
  }
}

// ── 단일 선택 칩 그룹 ────────────────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider),
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

// ── 다중 선택 칩 그룹 ────────────────────────────────────────

class _MultiChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final String Function(String) labelOf;
  final ValueChanged<List<String>> onChanged;

  const _MultiChipGroup({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  void _toggle(String value) {
    final updated = List<String>.from(selected);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () => _toggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.primary : AppColors.surface,
              border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.divider),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelOf(opt),
              style: TextStyle(
                fontSize: 14,
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
