import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/design_tokens.dart';
import '../widgets/onboarding_hero.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  기본정보 — Q1·Q2·Q3 통합 카드
//
//  이름·출생연도·성별을 한 페이지에서 입력.
//  상태는 onboarding_screen 이 소유, 이 위젯은 콜백으로만 전달.
// ══════════════════════════════════════════════════════════════

class DiagBasicInfo extends StatefulWidget {
  final String? nickname;
  final int? birthYear;
  final String? gender; // 'male' | 'female' | null

  final ValueChanged<String?> onNicknameChanged;
  final ValueChanged<int?> onBirthYearChanged;
  final ValueChanged<String?> onGenderChanged;

  const DiagBasicInfo({
    super.key,
    this.nickname,
    this.birthYear,
    this.gender,
    required this.onNicknameChanged,
    required this.onBirthYearChanged,
    required this.onGenderChanged,
  });

  @override
  State<DiagBasicInfo> createState() => _DiagBasicInfoState();
}

class _DiagBasicInfoState extends State<DiagBasicInfo> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _birthYearCtrl;
  late final FocusNode _nicknameFocus;
  late final FocusNode _birthYearFocus;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.nickname ?? '');
    _birthYearCtrl =
        TextEditingController(text: widget.birthYear?.toString() ?? '');
    _nicknameFocus = FocusNode();
    _birthYearFocus = FocusNode();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _birthYearCtrl.dispose();
    _nicknameFocus.dispose();
    _birthYearFocus.dispose();
    super.dispose();
  }

  // ── 취약연령: 18세 미만 또는 60세 이상 ───────────────────────
  bool _isVulnerableAge(int year) {
    final age = DateTime.now().year - year;
    return age < 18 || age >= 60;
  }

  // ── 유효 연도 여부 ────────────────────────────────────────────
  bool _isValidYear(String text) {
    if (text.length != 4) return false;
    final y = int.tryParse(text);
    if (y == null) return false;
    return y >= 1924 && y <= DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── Hero ─────────────────────────────────────────────
            const OnboardingHero(
              main: '기본 정보예요',
              sub: '건강 기준을 만들기 위한 정보예요',
              heroSize: 48,
            ),

            const SizedBox(height: 36),

            // ── 섹션 1: 이름 ────────────────────────────────────
            const Row(
              children: [
                Icon(Icons.person_outline, size: 28, color: DT.primary),
                SizedBox(width: 8),
                Text(
                  '이름 (별명도 좋아요)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DT.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameCtrl,
              focusNode: _nicknameFocus,
              maxLength: 10,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration('예: 지수').copyWith(
                suffixIcon: _nicknameCtrl.text.trim().isNotEmpty
                    ? const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: DT.safe,
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {}); // suffix icon 갱신
                widget.onNicknameChanged(
                    v.trim().isEmpty ? null : v.trim());
              },
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_birthYearFocus);
              },
            ),

            const SizedBox(height: 32),

            // ── 섹션 2: 출생연도 ─────────────────────────────────
            const Row(
              children: [
                Icon(Icons.cake_outlined, size: 28, color: DT.primary),
                SizedBox(width: 8),
                Text(
                  '출생연도',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DT.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _birthYearCtrl,
              focusNode: _birthYearFocus,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputDecoration('예: 1985'),
              onChanged: (v) {
                setState(() {}); // AnimatedSwitcher 트리거
                if (_isValidYear(v)) {
                  widget.onBirthYearChanged(int.parse(v));
                } else {
                  widget.onBirthYearChanged(null);
                }
              },
            ),
            const SizedBox(height: 8),

            // ── 만 나이 + 취약연령 배지 ──────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isValidYear(_birthYearCtrl.text)
                  ? _AgePreview(
                      key: ValueKey(int.parse(_birthYearCtrl.text)),
                      year: int.parse(_birthYearCtrl.text),
                      isVulnerable:
                          _isVulnerableAge(int.parse(_birthYearCtrl.text)),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),

            const SizedBox(height: 32),

            // ── 섹션 3: 성별 ─────────────────────────────────────
            const Row(
              children: [
                Icon(Icons.wc, size: 28, color: DT.primary),
                SizedBox(width: 8),
                Text(
                  '성별',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DT.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    value: 'male',
                    label: '남성',
                    icon: Icons.male,
                    selected: widget.gender == 'male',
                    onTap: () => widget.onGenderChanged('male'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderCard(
                    value: 'female',
                    label: '여성',
                    icon: Icons.female,
                    selected: widget.gender == 'female',
                    onTap: () => widget.onGenderChanged('female'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            insightBox('이름·나이·성별로 내 호흡 기준을 만들어요'),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── 만 나이 + 취약연령 배지 미리보기 ─────────────────────────────

class _AgePreview extends StatelessWidget {
  final int year;
  final bool isVulnerable;

  const _AgePreview({
    super.key,
    required this.year,
    required this.isVulnerable,
  });

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().year - year;
    return Row(
      children: [
        Text(
          '만 $age세',
          style: const TextStyle(
            fontSize: 14,
            color: DT.gray,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isVulnerable) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: DT.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '취약 연령',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: DT.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 성별 선택 카드 ────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.value,
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected
              ? DT.primary.withValues(alpha: 0.08)
              : DT.grayLt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? DT.primary : DT.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? DT.primary : DT.gray2,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? DT.primary : DT.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
