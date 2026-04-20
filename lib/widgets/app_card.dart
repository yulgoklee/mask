import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_tokens.dart';

/// 앱 전체 공용 카드 컴포넌트
///
/// 사용법:
///   AppCard(child: ...)                        // 기본: border + 흰 배경
///   AppCard.elevated(child: ...)               // 강조: border + 그림자
///   AppCard.tinted(color: primary, child: ...) // 틴트: 컬러 배경
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final _AppCardType _type;
  final Color? tintColor;
  final VoidCallback? onTap;

  const AppCard._({
    required this.child,
    required _AppCardType type,
    this.padding,
    this.radius,
    this.tintColor,
    this.onTap,
  }) : _type = type;

  factory AppCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? radius,
    VoidCallback? onTap,
  }) => AppCard._(
        type: _AppCardType.basic,
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );

  factory AppCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? radius,
    VoidCallback? onTap,
  }) => AppCard._(
        type: _AppCardType.elevated,
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );

  factory AppCard.tinted({
    required Widget child,
    required Color color,
    EdgeInsetsGeometry? padding,
    double? radius,
    VoidCallback? onTap,
  }) => AppCard._(
        type: _AppCardType.tinted,
        tintColor: color,
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTokens.radiusLg;
    final p = padding ?? const EdgeInsets.all(AppTokens.cardLg);

    BoxDecoration decoration;
    switch (_type) {
      case _AppCardType.basic:
        decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: AppColors.divider),
        );
      case _AppCardType.elevated:
        decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppTokens.shadowSm,
        );
      case _AppCardType.tinted:
        final c = tintColor ?? AppColors.primary;
        decoration = BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: c.withValues(alpha: 0.2)),
        );
    }

    final container = Container(
      decoration: decoration,
      padding: p,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}

enum _AppCardType { basic, elevated, tinted }
