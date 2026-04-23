import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';

class MyBodyInfoScreen extends ConsumerWidget {
  const MyBodyInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: DT.background,
      appBar: AppBar(
        backgroundColor: DT.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DT.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '내 몸 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── 기본 정보 ───────────────────────────────────────
          const _SectionHeader('기본 정보'),
          _InfoSection(children: [
            _InfoRow(
              title: '닉네임',
              value: profile.nickname.isNotEmpty ? profile.nickname : '미입력',
              onTap: () => _showNicknameSheet(context, ref, profile),
            ),
            const _Divider(),
            _InfoRow(
              title: '출생 연도',
              value: '${profile.birthYear}년',
              onTap: () => _showBirthYearSheet(context, ref, profile),
            ),
            const _Divider(),
            _InfoRow(
              title: '성별',
              value: _genderLabel(profile.gender),
              onTap: () => _showGenderSheet(context, ref, profile),
            ),
          ]),
          const SizedBox(height: 16),

          // ── 건강 상태 ───────────────────────────────────────
          const _SectionHeader('건강 상태'),
          _InfoSection(children: [
            _InfoRow(
              title: '호흡기',
              value: profile.respiratoryLabel,
              onTap: () => _showRespiratorySheet(context, ref, profile),
            ),
            const _Divider(),
            _InfoRow(
              title: '민감도',
              value: _sensitivityLabel(profile.sensitivityLevel),
              onTap: () => _showSensitivitySheet(context, ref, profile),
            ),
            const _Divider(),
            _InfoRow(
              title: '야외 활동',
              value: _outdoorLabel(profile.outdoorMinutes),
              onTap: () => _showOutdoorSheet(context, ref, profile),
            ),
            const _Divider(),
            _InfoRow(
              title: '활동 유형',
              value: profile.activityTags.isEmpty
                  ? '없음'
                  : '${profile.activityTags.length}개 선택',
              onTap: () => _showActivityTagsSheet(context, ref, profile),
            ),
          ]),
          const SizedBox(height: 16),

          // ── 현재 상황 ───────────────────────────────────────
          const _SectionHeader('현재 상황'),
          _InfoSection(children: [
            _InfoRow(
              title: '임신',
              value: profile.isPregnant ? '예' : '아니오',
              onTap: () => _showPregnantSheet(context, ref, profile),
            ),
            const _Divider(),
            _InfoRow(
              title: '피부 시술',
              value: profile.isSkinTreatmentActive ? '회복 중' : '해당 없음',
              onTap: () => _showSkinTreatmentSheet(context, ref, profile),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── 레이블 헬퍼 ───────────────────────────────────────────

String _genderLabel(String g) => switch (g) {
      'male'   => '남성',
      'female' => '여성',
      'other'  => '기타',
      _        => '미선택',
    };

String _sensitivityLabel(int v) => switch (v) {
      1 => '조금 예민',
      2 => '매우 예민',
      _ => '무던함',
    };

String _outdoorLabel(int v) => switch (v) {
      1 => '30분~3시간',
      2 => '3시간 이상',
      _ => '30분 이하',
    };

// ── 저장 + SnackBar 헬퍼 ─────────────────────────────────

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

// ── 바텀시트 공통 래퍼 ────────────────────────────────────

Widget _sheetShell({required Widget child}) {
  return Builder(
    builder: (context) => Container(
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
          child,
        ],
      ),
    ),
  );
}

// ── 공통 저장/취소 버튼 행 ────────────────────────────────

Widget _actionRow({
  required VoidCallback onSave,
  required VoidCallback onCancel,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: DT.gray,
            side: const BorderSide(color: DT.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('취소'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: DT.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('저장'),
        ),
      ),
    ],
  );
}

// ── ChipGroup (DT 토큰 기반) ─────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? DT.primary : DT.grayLt,
              border: Border.all(
                color: isSelected ? DT.primary : DT.border,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelOf(v),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : DT.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 바텀시트 a: 닉네임 ───────────────────────────────────

void _showNicknameSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  final controller = TextEditingController(text: profile.nickname);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _sheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('닉네임', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLength: 10,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '닉네임 입력 (최대 10자)',
              hintStyle: const TextStyle(color: DT.gray),
              filled: true,
              fillColor: DT.grayLt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            onSave: () {
              _save(ctx, ref, profile.copyWith(nickname: controller.text.trim()));
              Navigator.pop(ctx);
            },
            onCancel: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}

// ── 바텀시트 b: 출생 연도 ─────────────────────────────────

void _showBirthYearSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  final now = DateTime.now().year;
  const startYear = 1930;
  final totalItems = now - startYear + 1;
  int tempYear = profile.birthYear;
  final initialItem = (profile.birthYear - startYear).clamp(0, totalItems - 1);

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SizedBox(
      height: 340,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소', style: TextStyle(color: DT.gray)),
                ),
                const Text('출생 연도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DT.text)),
                TextButton(
                  onPressed: () {
                    _save(ctx, ref, profile.copyWith(birthYear: tempYear));
                    Navigator.pop(ctx);
                  },
                  child: const Text('확인', style: TextStyle(color: DT.primary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: initialItem),
              itemExtent: 44,
              onSelectedItemChanged: (i) => tempYear = startYear + i,
              children: List.generate(totalItems, (i) => Center(
                child: Text('${startYear + i}년', style: const TextStyle(fontSize: 18)),
              )),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── 바텀시트 c: 성별 ─────────────────────────────────────

void _showGenderSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      String selected = profile.gender;
      return StatefulBuilder(
        builder: (ctx, setState) => _sheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('성별', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
              const SizedBox(height: 16),
              _ChipGroup<String>(
                values: const ['male', 'female', 'other'],
                selected: selected,
                labelOf: _genderLabel,
                onSelect: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 20),
              _actionRow(
                onSave: () {
                  _save(ctx, ref, profile.copyWith(gender: selected));
                  Navigator.pop(ctx);
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── 바텀시트 d: 호흡기 ───────────────────────────────────

void _showRespiratorySheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      int selected = profile.respiratoryStatus;
      return StatefulBuilder(
        builder: (ctx, setState) => _sheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('호흡기 상태', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
              const SizedBox(height: 16),
              _ChipGroup<int>(
                values: const [0, 1, 2, 3],
                selected: selected,
                labelOf: (v) => switch (v) {
                  1 => '비염',
                  2 => '천식',
                  3 => '둘 다',
                  _ => '건강함',
                },
                onSelect: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 20),
              _actionRow(
                onSave: () {
                  _save(ctx, ref, profile.copyWith(respiratoryStatus: selected));
                  Navigator.pop(ctx);
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── 바텀시트 e: 민감도 ───────────────────────────────────

void _showSensitivitySheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      int selected = profile.sensitivityLevel;
      return StatefulBuilder(
        builder: (ctx, setState) => _sheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('체감 민감도', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
              const SizedBox(height: 16),
              _ChipGroup<int>(
                values: const [0, 1, 2],
                selected: selected,
                labelOf: (v) => switch (v) {
                  1 => '조금 예민',
                  2 => '매우 예민',
                  _ => '무던함',
                },
                onSelect: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 20),
              _actionRow(
                onSave: () {
                  _save(ctx, ref, profile.copyWith(sensitivityLevel: selected));
                  Navigator.pop(ctx);
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── 바텀시트 f: 야외 활동 ─────────────────────────────────

void _showOutdoorSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      int selected = profile.outdoorMinutes;
      return StatefulBuilder(
        builder: (ctx, setState) => _sheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('야외 활동 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
              const SizedBox(height: 16),
              _ChipGroup<int>(
                values: const [0, 1, 2],
                selected: selected,
                labelOf: (v) => switch (v) {
                  1 => '30분~3시간',
                  2 => '3시간 이상',
                  _ => '30분 이하',
                },
                onSelect: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 20),
              _actionRow(
                onSave: () {
                  _save(ctx, ref, profile.copyWith(outdoorMinutes: selected));
                  Navigator.pop(ctx);
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── 바텀시트 g: 활동 유형 ─────────────────────────────────

const _kActivityOptions = [
  (tag: ActivityTag.commute,   label: '출퇴근'),
  (tag: ActivityTag.walk,      label: '산책'),
  (tag: ActivityTag.exercise,  label: '운동'),
  (tag: ActivityTag.delivery,  label: '배달/외근'),
  (tag: ActivityTag.childcare, label: '아이 등하원'),
];

void _showActivityTagsSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final selected = Set<String>.from(profile.activityTags);
      return StatefulBuilder(
        builder: (ctx, setState) => _sheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('활동 유형', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
              const SizedBox(height: 4),
              const Text('해당하는 활동을 모두 선택해 주세요.',
                  style: TextStyle(fontSize: 13, color: DT.gray)),
              const SizedBox(height: 16),
              ..._kActivityOptions.map((opt) => CheckboxListTile(
                    title: Text(opt.label, style: const TextStyle(fontSize: 15, color: DT.text)),
                    value: selected.contains(opt.tag),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        selected.add(opt.tag);
                      } else {
                        selected.remove(opt.tag);
                      }
                    }),
                    activeColor: DT.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
              const SizedBox(height: 8),
              _actionRow(
                onSave: () {
                  _save(ctx, ref, profile.copyWith(activityTags: selected.toList()));
                  Navigator.pop(ctx);
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── 바텀시트 h: 임신 ─────────────────────────────────────

void _showPregnantSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      bool isPregnant = profile.isPregnant;
      return StatefulBuilder(
        builder: (ctx, setState) => _sheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('임신', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
              const SizedBox(height: 4),
              const Text('임신 중이면 더 낮은 기준을 적용해요.',
                  style: TextStyle(fontSize: 13, color: DT.gray)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('임신 중이에요', style: TextStyle(fontSize: 15, color: DT.text)),
                  Switch(
                    value: isPregnant,
                    onChanged: (v) => setState(() => isPregnant = v),
                    activeThumbColor: DT.primary,
                    activeTrackColor: DT.primaryLt,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _actionRow(
                onSave: () {
                  _save(ctx, ref, profile.copyWith(isPregnant: isPregnant));
                  Navigator.pop(ctx);
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── 바텀시트 i: 피부 시술 ─────────────────────────────────

void _showSkinTreatmentSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      bool hasTreatment = profile.recentSkinTreatment;
      DateTime? treatmentDate = profile.skinTreatmentDate;

      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: treatmentDate ?? now,
              firstDate: now.subtract(const Duration(days: 60)),
              lastDate: now,
              helpText: '시술 날짜를 선택하세요',
              cancelText: '취소',
              confirmText: '확인',
            );
            if (picked != null) setState(() => treatmentDate = picked);
          }

          String dateLabel() {
            if (treatmentDate == null) return '날짜 선택';
            final diff = DateTime.now().difference(treatmentDate!).inDays;
            if (diff == 0) return '오늘';
            if (diff == 1) return '어제';
            return '$diff일 전';
          }

          return _sheetShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('피부 시술', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text)),
                const SizedBox(height: 4),
                const Text('시술 후 14일간 더 낮은 기준을 적용해요.',
                    style: TextStyle(fontSize: 13, color: DT.gray)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('최근 피부 시술했어요', style: TextStyle(fontSize: 15, color: DT.text)),
                    Switch(
                      value: hasTreatment,
                      onChanged: (v) => setState(() {
                        hasTreatment = v;
                        if (!v) treatmentDate = null;
                      }),
                      activeThumbColor: DT.primary,
                      activeTrackColor: DT.primaryLt,
                    ),
                  ],
                ),
                if (hasTreatment) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: DT.grayLt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DT.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: DT.gray),
                          const SizedBox(width: 8),
                          Text(dateLabel(), style: const TextStyle(fontSize: 14, color: DT.text)),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 18, color: DT.gray),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _actionRow(
                  onSave: () {
                    final updated = hasTreatment
                        ? profile.copyWith(
                            recentSkinTreatment: true,
                            skinTreatmentDate: treatmentDate,
                          )
                        : profile.copyWith(
                            recentSkinTreatment: false,
                            clearSkinTreatmentDate: true,
                          );
                    _save(ctx, ref, updated);
                    Navigator.pop(ctx);
                  },
                  onCancel: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ── UI 컴포넌트 ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DT.gray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DT.border),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0F000000)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _InfoRow({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: DT.text)),
            ),
            Text(value, style: const TextStyle(fontSize: 14, color: DT.gray)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: DT.gray),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1, thickness: 1, indent: 20, endIndent: 20, color: DT.border,
    );
  }
}
