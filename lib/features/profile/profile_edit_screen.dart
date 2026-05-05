import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';

/// 프로필 편집 화면
///
/// _draft 패턴: 진입 시 현재 profile 복사 → 필드 변경 시 _draft 갱신
/// [저장] 버튼: _draft를 profileProvider에 저장 후 pop
/// 뒤로 가기: _draft 버림 (다이얼로그 없음)
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late UserProfile _draft;
  late TextEditingController _nicknameCtrl;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(profileProvider);
    _nicknameCtrl = TextEditingController(text: _draft.nickname);
    // Re-sync once after the first frame: schedule as microtask so it runs
    // after profileProvider's async loadProfile().then() has fired.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (!mounted) return;
        final loaded = ref.read(profileProvider);
        setState(() {
          _draft = loaded;
          _nicknameCtrl.text = loaded.nickname;
        });
      });
    });
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(profileProvider.notifier).update(
          _draft.copyWith(nickname: _nicknameCtrl.text.trim()),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '프로필 수정',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '저장',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── 기본 정보 ─────────────────────────────────────
          _SectionLabel('기본 정보'),
          const SizedBox(height: 10),

          _FieldLabel('닉네임'),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameCtrl,
            readOnly: true,
            maxLength: 10,
            decoration: InputDecoration(
              hintText: '닉네임 입력 (최대 10자)',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '현재는 변경할 수 없어요',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('성별'),
          const SizedBox(height: 8),
          _ChipGroup<String>(
            values: const ['male', 'female'],
            // 기존에 'other' 등록한 경우 빈 문자열로 처리 (칩 미선택 상태)
            selected: (_draft.gender == 'male' || _draft.gender == 'female')
                ? _draft.gender
                : '',
            labelOf: (v) => v == 'male' ? '남성' : '여성',
            onSelect: (v) => setState(() => _draft = _draft.copyWith(gender: v)),
          ),
          const SizedBox(height: 20),

          _FieldLabel('출생연도'),
          const SizedBox(height: 8),
          _BirthYearPicker(
            birthYear: _draft.birthYear,
            onChanged: (year) =>
                setState(() => _draft = _draft.copyWith(birthYear: year)),
          ),
          const SizedBox(height: 20),

          _FieldLabel('마스크 불편 정도'),
          const SizedBox(height: 8),
          _ChipGroup<int>(
            values: const [0, 1, 2],
            selected: _draft.discomfortLevel,
            labelOf: (v) =>
                v == 0 ? '안 느껴요' : v == 1 ? '보통이에요' : '많이 불편해요',
            onSelect: (v) =>
                setState(() => _draft = _draft.copyWith(discomfortLevel: v)),
          ),
          const SizedBox(height: 32),

          // ── 호흡기 질환 ───────────────────────────────────
          _SectionLabel('호흡기 질환'),
          const SizedBox(height: 10),
          _SettingRow(
            icon: '👃',
            title: '비염',
            subtitle: '알레르기성 또는 비알레르기성 비염',
            isActive: _draft.rhinitis,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(rhinitis: v)),
          ),
          _SettingRow(
            icon: '🫁',
            title: '천식',
            subtitle: '기관지 천식 진단 또는 증상',
            isActive: _draft.asthma,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(asthma: v)),
          ),
          _SettingRow(
            icon: '🌬️',
            title: 'COPD (만성 폐쇄성 폐질환)',
            subtitle: '만성기관지염, 폐기종 포함',
            isActive: _draft.copd,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(copd: v)),
          ),
          _SettingRow(
            icon: '🌸',
            title: '알레르기 (꽃가루 등)',
            subtitle: '꽃가루·먼지·음식 등 알레르기 반응',
            isActive: _draft.allergy,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(allergy: v)),
          ),
          const SizedBox(height: 24),

          // ── 심혈관 질환 ───────────────────────────────────
          _SectionLabel('심혈관 질환'),
          const SizedBox(height: 10),
          _SettingRow(
            icon: '🩺',
            title: '고혈압',
            subtitle: '고혈압 진단 또는 약 복용 중',
            isActive: _draft.hypertension,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(hypertension: v)),
          ),
          _SettingRow(
            icon: '❤️',
            title: '심장 질환',
            subtitle: '협심증, 심근경색, 부정맥 등',
            isActive: _draft.heartDisease,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(heartDisease: v)),
          ),
          _SettingRow(
            icon: '🧠',
            title: '뇌졸중 (중풍 경험)',
            subtitle: '뇌졸중 또는 뇌혈관 질환 병력',
            isActive: _draft.stroke,
            onToggle: (v) =>
                setState(() => _draft = _draft.copyWith(stroke: v)),
          ),
          const SizedBox(height: 24),

          // ── 흡연 ─────────────────────────────────────────
          _SectionLabel('흡연'),
          const SizedBox(height: 10),
          _FieldLabel('흡연 여부'),
          const SizedBox(height: 8),
          _ChipGroup<SmokingStatus>(
            values: SmokingStatus.values,
            selected: _draft.smokingStatus,
            labelOf: (v) => v == SmokingStatus.current
                ? '현재 흡연 중'
                : v == SmokingStatus.former
                    ? '끊었어요'
                    : '안 피워요',
            onSelect: (v) {
              if (v != SmokingStatus.current) {
                setState(() => _draft = _draft.copyWith(
                      smokingStatus: v,
                      smokesCigarette: false,
                      smokesHeated: false,
                      smokesVaping: false,
                    ));
              } else {
                setState(() => _draft = _draft.copyWith(smokingStatus: v));
              }
            },
          ),
          if (_draft.smokingStatus == SmokingStatus.current) ...[
            const SizedBox(height: 16),
            _FieldLabel('흡연 종류'),
            const SizedBox(height: 8),
            _SettingRow(
              icon: '🚬',
              title: '연초',
              subtitle: '일반 담배',
              isActive: _draft.smokesCigarette,
              onToggle: (v) =>
                  setState(() => _draft = _draft.copyWith(smokesCigarette: v)),
            ),
            _SettingRow(
              icon: '💨',
              title: '가열식',
              subtitle: 'IQOS, glo 등',
              isActive: _draft.smokesHeated,
              onToggle: (v) =>
                  setState(() => _draft = _draft.copyWith(smokesHeated: v)),
            ),
            _SettingRow(
              icon: '☁️',
              title: '전자담배',
              subtitle: '액상형 전자담배',
              isActive: _draft.smokesVaping,
              onToggle: (v) =>
                  setState(() => _draft = _draft.copyWith(smokesVaping: v)),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── 섹션 레이블 ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── 필드 레이블 ───────────────────────────────────────────

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

// ── ChipGroup ─────────────────────────────────────────────

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
    const startYear = 1930;
    final totalItems = now - startYear + 1;
    int tempYear = birthYear;
    final initialItem = (birthYear - startYear).clamp(0, totalItems - 1);

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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const Text('출생연도',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      onChanged(tempYear);
                      Navigator.pop(ctx);
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
                    initialItem: initialItem),
                itemExtent: 44,
                onSelectedItemChanged: (i) => tempYear = startYear + i,
                children: List.generate(
                  totalItems,
                  (i) => Center(
                    child: Text(
                      '${startYear + i}년',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final age = now - birthYear;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
