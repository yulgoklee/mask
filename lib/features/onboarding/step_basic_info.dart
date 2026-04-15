import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// 1단계 — 기본 정보 (이름 + 출생연도 + 성별)
///
/// 여성 선택 시 이후 임신 여부 분기 활성화
class StepBasicInfo extends StatefulWidget {
  final String? initialName;
  final int? initialBirthYear;
  final Gender? initialGender;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<int?> onBirthYearChanged;
  final ValueChanged<Gender?> onGenderChanged;

  const StepBasicInfo({
    super.key,
    this.initialName,
    this.initialBirthYear,
    this.initialGender,
    required this.onNameChanged,
    required this.onBirthYearChanged,
    required this.onGenderChanged,
  });

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _yearCtrl;
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _yearCtrl = TextEditingController(
        text: widget.initialBirthYear?.toString() ?? '');
    _gender = widget.initialGender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _questionBadge('기본 정보'),
          const SizedBox(height: 12),
          Text(
            '먼저 간단히\n알려주세요',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '입력한 정보는 맞춤 임계값 계산에만 사용돼요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 36),

          // ── 이름 ──────────────────────────────────────────
          _fieldLabel('이름 (선택)'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            maxLength: 10,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('예: 율곡'),
            onChanged: (v) => widget.onNameChanged(v.isEmpty ? null : v),
          ),
          const SizedBox(height: 20),

          // ── 출생연도 ──────────────────────────────────────
          _fieldLabel('출생연도'),
          const SizedBox(height: 8),
          TextField(
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration('예: 1990'),
            onChanged: (v) {
              final yr = int.tryParse(v);
              final now = DateTime.now().year;
              widget.onBirthYearChanged(
                  (yr != null && yr >= 1920 && yr <= now) ? yr : null);
            },
          ),
          const SizedBox(height: 20),

          // ── 성별 ──────────────────────────────────────────
          _fieldLabel('성별'),
          const SizedBox(height: 12),
          Row(
            children: Gender.values.map((g) {
              final selected = _gender == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _gender = selected ? null : g);
                      widget.onGenderChanged(selected ? null : g);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _genderEmoji(g),
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            g.label,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // ── 근거 문구 ─────────────────────────────────────
          const SizedBox(height: 32),
          _insightBox(
            '출생연도를 입력하면 연령별 기초 민감도가 자동 반영돼요. '
            '취약 연령(18세 미만, 60세 이상)은 기준값이 더 세밀하게 조정됩니다.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _genderEmoji(Gender g) {
    switch (g) {
      case Gender.male:   return '👨';
      case Gender.female: return '👩';
      case Gender.other:  return '🧑';
    }
  }
}

// ── 공용 위젯 헬퍼 ─────────────────────────────────────────

Widget _questionBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );

Widget _fieldLabel(String text) => Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

Widget _insightBox(String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
