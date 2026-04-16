import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

// ── 공통 진단 카드 래퍼 ─────────────────────────────────────

/// 모든 질문 카드의 공통 래퍼.
/// 흰색 카드 + Q번호 + 질문 + 힌트 + 응답 위젯으로 구성됩니다.
class DiagnosisCard extends StatelessWidget {
  final String questionNumber;
  final String question;
  final String hint;
  final Widget child;

  const DiagnosisCard({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 번호 뱃지
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.splashBackground.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              questionNumber,
              style: const TextStyle(
                color: AppColors.splashBackground,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 질문 텍스트
          Text(
            question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // 힌트 텍스트
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // 응답 위젯
          child,
        ],
      ),
    );
  }
}

// ── Q1: 닉네임 입력 ───────────────────────────────────────────

class NicknameInput extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const NicknameInput({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<NicknameInput> createState() => _NicknameInputState();
}

class _NicknameInputState extends State<NicknameInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          onChanged: widget.onChanged,
          maxLength: 10,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '예) 율곡, 건강이',
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppColors.splashBackground, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '2~10자로 입력해 주세요',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Q2: 출생 연도 휠 피커 ────────────────────────────────────

class BirthYearPicker extends StatefulWidget {
  final int initialYear;
  final ValueChanged<int> onChanged;

  const BirthYearPicker({
    super.key,
    required this.initialYear,
    required this.onChanged,
  });

  @override
  State<BirthYearPicker> createState() => _BirthYearPickerState();
}

class _BirthYearPickerState extends State<BirthYearPicker> {
  late int _selectedYear;
  late final FixedExtentScrollController _scrollCtrl;

  static const int _startYear = 1940;
  static final int _endYear   = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    final initialIndex = _selectedYear - _startYear;
    _scrollCtrl = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  int get _age => DateTime.now().year - _selectedYear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 선택된 연도 + 나이 표시
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.splashBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$_selectedYear년',
                    style: const TextStyle(
                      color: AppColors.splashBackground,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '  (만 $_age세)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 휠 피커
        SizedBox(
          height: 180,
          child: ListWheelScrollView.useDelegate(
            controller: _scrollCtrl,
            itemExtent: 52,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            diameterRatio: 2.0,
            onSelectedItemChanged: (index) {
              final year = _startYear + index;
              setState(() => _selectedYear = year);
              widget.onChanged(year);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index > _endYear - _startYear) return null;
                final year = _startYear + index;
                final isSelected = year == _selectedYear;
                return Center(
                  child: Text(
                    '$year년',
                    style: TextStyle(
                      fontSize: isSelected ? 22 : 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              },
              childCount: _endYear - _startYear + 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Q3: 성별 선택 ────────────────────────────────────────────

class GenderSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const GenderSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GenderTile(
          label: '남성',
          emoji: '👨',
          value: 'male',
          isSelected: selected == 'male',
          onTap: () => onChanged('male'),
        ),
        const SizedBox(width: 12),
        _GenderTile(
          label: '여성',
          emoji: '👩',
          value: 'female',
          isSelected: selected == 'female',
          onTap: () => onChanged('female'),
        ),
      ],
    );
  }
}

class _GenderTile extends StatelessWidget {
  final String label;
  final String emoji;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderTile({
    required this.label,
    required this.emoji,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.splashBackground.withOpacity(0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.splashBackground
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.splashBackground
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 단일 선택 (Q4, Q5, Q6 bool, Q7 bool, Q8, Q10) ───────────

class SingleChoiceSelector<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const SingleChoiceSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = option == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.splashBackground.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.splashBackground
                      : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 라디오 원
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.splashBackground
                            : AppColors.divider,
                        width: isSelected ? 6 : 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      labelOf(option),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Q9: 다중 선택 ────────────────────────────────────────────

class MultiChoiceSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final String Function(String) labelOf;
  final ValueChanged<List<String>> onChanged;

  const MultiChoiceSelector({
    super.key,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '해당하는 것을 모두 선택하세요',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () => _toggle(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.splashBackground.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.splashBackground
                        : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.splashBackground,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labelOf(option),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.splashBackground
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
