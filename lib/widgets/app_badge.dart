import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_tokens.dart';
import '../core/constants/dust_standards.dart';

/// 앱 전체 공용 배지/칩 컴포넌트
///
/// 사용법:
///   AppBadge.grade(DustGrade.bad)          // 미세먼지 등급
///   AppBadge.label('KF94')                 // 마스크 타입
///   AppBadge.outline('위험', color: red)   // 위험도
///   AppBadge.soft('복합 고위험군', color: ..) // 온보딩 결과
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final _AppBadgeType _type;

  const AppBadge._({
    required this.text,
    required this.color,
    required _AppBadgeType type,
  }) : _type = type;

  factory AppBadge.grade(DustGrade grade) {
    final color = _gradeColor(grade);
    return AppBadge._(
      text: grade.label,
      color: color,
      type: _AppBadgeType.filled,
    );
  }

  factory AppBadge.label(String text, {Color color = AppColors.primary}) =>
      AppBadge._(
        text: text,
        color: color,
        type: _AppBadgeType.filled,
      );

  factory AppBadge.outline(String text, {Color color = AppColors.primary}) =>
      AppBadge._(
        text: text,
        color: color,
        type: _AppBadgeType.outline,
      );

  factory AppBadge.soft(String text, {Color color = AppColors.primary}) =>
      AppBadge._(
        text: text,
        color: color,
        type: _AppBadgeType.soft,
      );

  static Color _gradeColor(DustGrade grade) {
    switch (grade) {
      case DustGrade.good:    return AppColors.dustGood;
      case DustGrade.normal:  return AppColors.dustNormal;
      case DustGrade.bad:     return AppColors.dustBad;
      case DustGrade.veryBad: return AppColors.dustVeryBad;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_type) {
      case _AppBadgeType.filled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );

      case _AppBadgeType.outline:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );

      case _AppBadgeType.soft:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
    }
  }
}

enum _AppBadgeType { filled, outline, soft }
