import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../data/models/user_profile.dart';
import '../../features/settings/widgets/s_item.dart';
import '../../features/settings/widgets/s_label.dart';
import '../../features/settings/widgets/s_switch.dart';
import '../../features/settings/widgets/settings_drill_header.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/app_button.dart';

/// 프로필 편집 화면 (건강 정보)
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

  @override
  void initState() {
    super.initState();
    _draft = ref.read(profileProvider);
    // Re-sync once after the first frame: schedule as microtask so it runs
    // after profileProvider's async loadProfile().then() has fired.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (!mounted) return;
        final loaded = ref.read(profileProvider);
        setState(() {
          _draft = loaded;
        });
      });
    });
  }

  void _save() {
    // nickname은 변경하지 않고 기존 값 그대로 보존
    ref.read(profileProvider.notifier).update(_draft);
    Navigator.of(context).pop();
  }

  // ── 성별 BottomSheet ──────────────────────────────────────────

  void _showGenderSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: DT.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DT.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '성별',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DT.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SheetItem(
              label: '남성',
              selected: _draft.gender == 'male',
              onTap: () {
                setState(() => _draft = _draft.copyWith(gender: 'male'));
                Navigator.pop(ctx);
              },
            ),
            _SheetItem(
              label: '여성',
              selected: _draft.gender == 'female',
              onTap: () {
                setState(() => _draft = _draft.copyWith(gender: 'female'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── 흡연 여부 BottomSheet ─────────────────────────────────────

  void _showSmokingSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: DT.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DT.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '흡연 여부',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DT.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SheetItem(
              label: '안 피워요',
              selected: _draft.smokingStatus == SmokingStatus.never,
              onTap: () {
                setState(() => _draft = _draft.copyWith(
                      smokingStatus: SmokingStatus.never,
                      smokesCigarette: false,
                      smokesHeated: false,
                      smokesVaping: false,
                    ));
                Navigator.pop(ctx);
              },
            ),
            _SheetItem(
              label: '끊었어요',
              selected: _draft.smokingStatus == SmokingStatus.former,
              onTap: () {
                setState(() => _draft = _draft.copyWith(
                      smokingStatus: SmokingStatus.former,
                      smokesCigarette: false,
                      smokesHeated: false,
                      smokesVaping: false,
                    ));
                Navigator.pop(ctx);
              },
            ),
            _SheetItem(
              label: '현재 흡연 중',
              selected: _draft.smokingStatus == SmokingStatus.current,
              onTap: () {
                setState(
                    () => _draft = _draft.copyWith(smokingStatus: SmokingStatus.current));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── 출생연도 피커 ─────────────────────────────────────────────

  void _showBirthYearPicker() {
    final now = DateTime.now().year;
    const startYear = 1930;
    final totalItems = now - startYear + 1;
    int tempYear = _draft.birthYear;
    final initialItem =
        (_draft.birthYear - startYear).clamp(0, totalItems - 1);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: DT.white,
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
                color: DT.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소',
                        style: TextStyle(color: DT.gray)),
                  ),
                  const Text('출생연도',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(
                          () => _draft = _draft.copyWith(birthYear: tempYear));
                      Navigator.pop(ctx);
                    },
                    child: const Text('확인',
                        style: TextStyle(color: DT.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: initialItem),
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

  // ── 성별 값 레이블 ────────────────────────────────────────────

  String get _genderLabel {
    return switch (_draft.gender) {
      'male' => '남성',
      'female' => '여성',
      _ => '선택 안 함',
    };
  }

  // ── 흡연 값 레이블 ────────────────────────────────────────────

  String get _smokingLabel {
    return switch (_draft.smokingStatus) {
      SmokingStatus.current => '현재 흡연 중',
      SmokingStatus.former => '끊었어요',
      SmokingStatus.never => '안 피워요',
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final age = now - _draft.birthYear;

    return Scaffold(
      backgroundColor: DT.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────────
            SettingsDrillHeader(
              title: '건강 정보',
              onBack: () => Navigator.of(context).pop(),
            ),

            // ── 본문 (스크롤) ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 기본 정보 ────────────────────────────────
                    const SLabel('기본 정보'),
                    SItem(
                      label: '성별',
                      value: _genderLabel,
                      onClick: _showGenderSheet,
                    ),
                    SItem(
                      label: '출생연도',
                      value: '${_draft.birthYear}년 (만 $age세)',
                      onClick: _showBirthYearPicker,
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 호흡기 질환 ──────────────────────────────
                    const SLabel('호흡기 질환'),
                    SItem(
                      label: '비염',
                      trailing: SSwitch(
                        value: _draft.rhinitis,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(rhinitis: v)),
                      ),
                    ),
                    SItem(
                      label: '천식',
                      trailing: SSwitch(
                        value: _draft.asthma,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(asthma: v)),
                      ),
                    ),
                    SItem(
                      label: 'COPD (만성 폐쇄성 폐질환)',
                      trailing: SSwitch(
                        value: _draft.copd,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(copd: v)),
                      ),
                    ),
                    SItem(
                      label: '알레르기 (꽃가루 등)',
                      trailing: SSwitch(
                        value: _draft.allergy,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(allergy: v)),
                      ),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 심혈관 질환 ──────────────────────────────
                    const SLabel('심혈관 질환'),
                    SItem(
                      label: '고혈압',
                      trailing: SSwitch(
                        value: _draft.hypertension,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(hypertension: v)),
                      ),
                    ),
                    SItem(
                      label: '심장 질환',
                      trailing: SSwitch(
                        value: _draft.heartDisease,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(heartDisease: v)),
                      ),
                    ),
                    SItem(
                      label: '뇌졸중 (중풍 경험)',
                      trailing: SSwitch(
                        value: _draft.stroke,
                        onChange: (v) =>
                            setState(() => _draft = _draft.copyWith(stroke: v)),
                      ),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 흡연 ─────────────────────────────────────
                    const SLabel('흡연'),
                    SItem(
                      label: '흡연 여부',
                      value: _smokingLabel,
                      onClick: _showSmokingSheet,
                      last: _draft.smokingStatus != SmokingStatus.current,
                    ),
                    if (_draft.smokingStatus == SmokingStatus.current) ...[
                      SItem(
                        label: '연초',
                        trailing: SSwitch(
                          value: _draft.smokesCigarette,
                          onChange: (v) => setState(
                              () => _draft = _draft.copyWith(smokesCigarette: v)),
                        ),
                      ),
                      SItem(
                        label: '가열식',
                        trailing: SSwitch(
                          value: _draft.smokesHeated,
                          onChange: (v) => setState(
                              () => _draft = _draft.copyWith(smokesHeated: v)),
                        ),
                      ),
                      SItem(
                        label: '전자담배',
                        trailing: SSwitch(
                          value: _draft.smokesVaping,
                          onChange: (v) => setState(
                              () => _draft = _draft.copyWith(smokesVaping: v)),
                        ),
                        last: true,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── 하단 고정 저장 버튼 (D-2) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: AppButton.primary(
                label: '저장',
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BottomSheet 선택 항목 위젯 ─────────────────────────────────

class _SheetItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? DT.primary : DT.text,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 20, color: DT.primary),
          ],
        ),
      ),
    );
  }
}
