import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_tokens.dart';

/// 앱 전체 공용 버튼 컴포넌트
///
/// 사용법:
///   AppButton.primary(label: '시작하기', onTap: _next)
///   AppButton.secondary(label: '다음에', onTap: _skip)
///   AppButton.text(label: '건너뛰기', onTap: _skip)
///   AppButton.primary(label: '저장', onTap: _save, isLoading: true)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final _AppButtonType _type;
  final bool isLoading;
  final bool fullWidth;
  final Widget? leading;
  final double? height;

  const AppButton._({
    required this.label,
    required this.onTap,
    required _AppButtonType type,
    this.isLoading = false,
    this.fullWidth = true,
    this.leading,
    this.height,
  }) : _type = type;

  factory AppButton.primary({
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool fullWidth = true,
    Widget? leading,
    double? height,
  }) => AppButton._(
        label: label,
        onTap: onTap,
        type: _AppButtonType.primary,
        isLoading: isLoading,
        fullWidth: fullWidth,
        leading: leading,
        height: height,
      );

  factory AppButton.secondary({
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool fullWidth = true,
    Widget? leading,
    double? height,
  }) => AppButton._(
        label: label,
        onTap: onTap,
        type: _AppButtonType.secondary,
        isLoading: isLoading,
        fullWidth: fullWidth,
        leading: leading,
        height: height,
      );

  factory AppButton.text({
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) => AppButton._(
        label: label,
        onTap: onTap,
        type: _AppButtonType.text,
      );

  @override
  Widget build(BuildContext context) {
    final h = height ?? (
      _type == _AppButtonType.primary
          ? AppTokens.btnHeightPrimary
          : AppTokens.btnHeightSecondary
    );

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _type == _AppButtonType.primary
                  ? Colors.white
                  : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(label),
            ],
          );

    if (_type == _AppButtonType.text) {
      return TextButton(
        onPressed: onTap,
        child: Text(label, style: AppTokens.btnText),
      );
    }

    final button = _type == _AppButtonType.primary
        ? ElevatedButton(
            onPressed: isLoading ? null : onTap,
            child: child,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onTap,
            child: child,
          );

    return fullWidth
        ? SizedBox(width: double.infinity, height: h, child: button)
        : SizedBox(height: h, child: button);
  }
}

enum _AppButtonType { primary, secondary, text }
