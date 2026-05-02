import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/engine/threshold_engine.dart';
import '../data/models/user_profile.dart';

// ── ProfileStateHeader ─────────────────────────────────────
// 이름 한 줄 (그룹 뱃지 제거 — E-5)

class ProfileStateHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileStateHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Text(
      profile.displayName.isNotEmpty
          ? '${profile.displayName}, 이렇게 알려드릴게요.'
          : '이렇게 알려드릴게요.',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
    );
  }
}

// ── ThresholdCompareCard ───────────────────────────────────
// 일반인 기준 35 vs 내 기준 tFinal + 마스크 등급 비교

class ThresholdCompareCard extends StatelessWidget {
  final UserProfile profile;

  const ThresholdCompareCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final tFinal = profile.tFinal;
    final maskType = const ThresholdEngine().recommendedMaskType(profile);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompareColumn(
              label: '일반인 기준',
              value: '35 μg/m³',
              subValue: 'KF80',
              highlight: false,
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.divider),
          Expanded(
            child: _CompareColumn(
              label: '내 기준',
              value: '${tFinal.toStringAsFixed(0)} μg/m³',
              subValue: maskType,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareColumn extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final bool highlight;

  const _CompareColumn({
    required this.label,
    required this.value,
    required this.subValue,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── SensitivityBreakdown ───────────────────────────────────
// 5개 카테고리 막대 + 가중치 합계

class SensitivityBreakdown extends StatelessWidget {
  final UserProfile profile;

  const SensitivityBreakdown({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final bd = const ThresholdEngine().breakdown(profile);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상태 분석',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _BreakdownRow(
            label: '연령',
            sublabel: '${profile.age}세 (${_ageGroupLabel(profile.age)})',
            weight: bd.wAge,
            cap: 0.13,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '호흡기',
            sublabel: _respiratorySublabel(profile),
            weight: bd.wRespiratory,
            cap: 0.30,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '심혈관',
            sublabel: _cardiovascularSublabel(profile),
            weight: bd.wCardiovascular,
            cap: 0.25,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '흡연',
            sublabel: _smokingSublabel(profile),
            weight: bd.wSmoking,
            cap: 0.20,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '특별 상태',
            sublabel: _specialSublabel(profile),
            weight: bd.wSpecial,
            cap: 0.20,
          ),
          const Divider(height: 28, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '건강 가중치 합계',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                bd.wTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _BreakdownRow ──────────────────────────────────────────
// 개별 카테고리 막대 + 가중치 + 레이블 + 서브레이블
// 색상 3단계: 0→회색 / 0<w<cap→파랑 / w>=cap→주황

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double weight;
  final double cap;

  const _BreakdownRow({
    required this.label,
    required this.sublabel,
    required this.weight,
    required this.cap,
  });

  Color _barColor() {
    if (weight == 0) return AppColors.divider;
    if (weight >= cap) return AppColors.coral;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = cap > 0 ? (weight / cap).clamp(0.0, 1.0) : 0.0;
    final color = _barColor();
    final isActive = weight > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '+${weight.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? color : AppColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          sublabel,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ── SensitivityActionGuide ─────────────────────────────────
// 가장 강한 요인 기준 한 줄 행동 가이드

class SensitivityActionGuide extends StatelessWidget {
  final UserProfile profile;

  const SensitivityActionGuide({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final bd = const ThresholdEngine().breakdown(profile);
    final guide = _guideText(profile, bd);

    return Text(
      guide,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary.withValues(alpha: 0.65),
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _guideText(UserProfile p, ThresholdBreakdown bd) {
    final name = p.nickname.isNotEmpty ? '${p.nickname}님' : '';
    final prefix = name.isNotEmpty ? '$name, ' : '';
    if (bd.floorApplied) {
      return '${prefix}최고 수준 민감도가 적용됐어요. 외출 전 꼭 확인하세요.';
    }
    if (bd.wSpecial > 0) {
      return '${prefix}임신 중에는 항상 마스크를 권장해요.';
    }
    if (bd.wRespiratory > 0) {
      return '${prefix}환절기·꽃가루 많은 날 특히 주의해요.';
    }
    if (bd.wCardiovascular > 0) {
      return '${prefix}미세먼지 높은 날 야외 운동은 피하세요.';
    }
    if (bd.wSmoking > 0) {
      return '${prefix}외출 전 미세먼지 확인이 더 중요해요.';
    }
    return '${prefix}공기가 나빠지기 전에 먼저 알려드릴게요.';
  }
}

// ── 헬퍼 함수 ──────────────────────────────────────────────

String _ageGroupLabel(int age) {
  if (age < 12) return '어린이';
  if (age < 50) return '일반';
  if (age < 60) return '50대';
  if (age < 70) return '60대';
  if (age < 80) return '70대';
  return '80대 이상';
}

String _respiratorySublabel(UserProfile p) {
  final parts = <String>[];
  if (p.asthma)   parts.add('천식');
  if (p.rhinitis) parts.add('비염');
  if (p.copd)     parts.add('COPD');
  if (p.allergy)  parts.add('알레르기');
  return parts.isEmpty ? '건강해요' : parts.join(' · ');
}

String _cardiovascularSublabel(UserProfile p) {
  final parts = <String>[];
  if (p.hypertension) parts.add('고혈압');
  if (p.heartDisease) parts.add('심장 질환');
  if (p.stroke)       parts.add('뇌졸중');
  return parts.isEmpty ? '건강해요' : parts.join(' · ');
}

String _smokingSublabel(UserProfile p) {
  switch (p.smokingStatus) {
    case SmokingStatus.current: return '현재 흡연 중';
    case SmokingStatus.former:  return '과거 흡연';
    case SmokingStatus.never:   return '비흡연';
  }
}

String _specialSublabel(UserProfile p) {
  return p.isPregnant ? '임신 중' : '해당 없음';
}
