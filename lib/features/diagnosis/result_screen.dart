import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/engine/threshold_engine.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';
import 'diagnosis_screen.dart';

/// 분석 결과 상세 화면 — Phase 2 (v2)
///
/// 섹션 구성:
///   1. 페르소나 카드 (이름 · 설명 · 키워드 태그)
///   2. 민감도 분해 (w1 / w2 / w3 게이지 + S 합산)
///   3. 나만의 마스크 기준 카드
///   4. 맞춤 행동 가이드
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 민감도 리포트',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DiagnosisScreen(),
                fullscreenDialog: true,
              ),
            ),
            child: const Text(
              '재진단',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          // ── 건강 가중치 분해 ────────────────────────────────
          _SectionTitle('민감도 분석'),
          const SizedBox(height: 12),
          _SensitivityBreakdown(profile: profile),
          const SizedBox(height: 20),

          // ── 마스크 기준 카드 ─────────────────────────────────
          _SectionTitle('나만의 마스크 기준'),
          const SizedBox(height: 12),
          _ThresholdCard(profile: profile),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 2. 민감도 분해 (w1 / w2 / w3 + S 합산)
// ─────────────────────────────────────────────────────────

class _SensitivityBreakdown extends StatelessWidget {
  final UserProfile profile;
  const _SensitivityBreakdown({required this.profile});

  @override
  Widget build(BuildContext context) {
    final bd = const ThresholdEngine().breakdown(profile);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: '연령',
            sublabel: '${profile.age}세 (${_ageGroupLabel(profile.age)})',
            weight: bd.wAge,
            maxWeight: 0.13,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '호흡기 · 건강 상태',
            sublabel: _healthSublabel(profile),
            weight: bd.wHealth,
            maxWeight: 0.65,
          ),
          const Divider(height: 28, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '건강 가중치 합계',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                bd.wTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 14,
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


class _BreakdownRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double weight;
  final double maxWeight;
  const _BreakdownRow({
    required this.label,
    required this.sublabel,
    required this.weight,
    required this.maxWeight,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxWeight > 0 ? (weight / maxWeight).clamp(0.0, 1.0) : 0.0;
    final isActive = weight > 0;
    final barColor = isActive ? AppColors.primary : AppColors.divider;

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
              '+${weight.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 3. 마스크 기준 카드
// ─────────────────────────────────────────────────────────

class _ThresholdCard extends StatelessWidget {
  final UserProfile profile;
  const _ThresholdCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final tFinal = profile.tFinal;
    final maskType = const ThresholdEngine().recommendedMaskType(profile);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompareColumn(
              label: '일반인 기준',
              value: '36 μg/m³',
              subValue: 'KF80',
              highlight: false,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.divider,
          ),
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
            fontSize: 12,
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
                ? AppColors.primaryLight
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


// ─────────────────────────────────────────────────────────
// 헬퍼
// ─────────────────────────────────────────────────────────

String _ageGroupLabel(int age) {
  if (age < 12) return '어린이';
  if (age < 50) return '일반';
  if (age < 60) return '50대';
  if (age < 70) return '60대';
  if (age < 80) return '70대';
  return '80대 이상';
}

String _healthSublabel(UserProfile p) {
  final parts = <String>[];
  if (p.asthma)   parts.add('천식');
  if (p.rhinitis) parts.add('비염');
  if (p.copd)     parts.add('COPD');
  if (p.allergy)  parts.add('알레르기');
  if (p.heartDisease) parts.add('심장 질환');
  if (p.hypertension) parts.add('고혈압');
  if (p.stroke)       parts.add('뇌졸중');
  if (p.isPregnant)   parts.add('임신');
  return parts.isEmpty ? '건강해요' : parts.join(' · ');
}

// ─────────────────────────────────────────────────────────
// 공통 섹션 타이틀
// ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
