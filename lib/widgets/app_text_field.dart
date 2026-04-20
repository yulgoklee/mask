import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_tokens.dart';

/// 앱 전체 공용 텍스트 입력 필드
///
/// 사용법:
///   AppTextField(hint: '측정소 검색', onChanged: _search)
///   AppTextField(hint: '닉네임', controller: _ctrl, prefixIcon: Icons.person)
class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final IconData? prefixIcon;
  final bool autofocus;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.autofocus = false,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: textInputAction,
      style: AppTokens.bodyMd,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTokens.caption.copyWith(color: AppColors.textHint),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
            : null,
        suffixIcon: onClear != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: AppColors.textSecondary,
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.cardMd,
          vertical: AppTokens.cardSm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
