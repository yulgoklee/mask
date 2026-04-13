import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/persona_generator.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';
import 'diagnosis_screen.dart';

/// 분석 결과 상세 화면 — Phase 2
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
    final persona = PersonaGenerator.generate(profile);
    final s = SensitivityCalculator.compute(profile);

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

          // ── 1. 페르소나 카드 ────────────────────────────────
          _PersonaCard(persona: persona),
          const SizedBox(height: 20),

          // ── 2. 민감도 분해 ──────────────────────────────────
          _SectionTitle('민감도 분석'),
          const SizedBox(height: 12),
          _SensitivityBreakdown(profile: profile, s: s),
          const SizedBox(height: 20),

          // ── 3. 마스크 기준 카드 ─────────────────────────────
          _SectionTitle('나만의 마스크 기준'),
          const SizedBox(height: 12),
          _ThresholdCard(s: s),
          const SizedBox(height: 20),

          // ── 4. 행동 가이드 ───────────────────────────────────
          _SectionTitle('맞춤 행동 가이드'),
          const SizedBox(height: 12),
          _ActionGuideList(guides: persona.actionGuides),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 1. 페르소나 카드
// ─────────────────────────────────────────────────────────

class _PersonaCard extends StatelessWidget {
  final Persona persona;
  const _PersonaCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor(persona.type);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이모지 + 이름 + 서브타이틀
          Row(
            children: [
              Text(persona.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      persona.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 설명
          Text(
            persona.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // 키워드 태그
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: persona.keywords
                .map((kw) => _KeywordTag(label: kw, color: accentColor))
                .toList(),
          ),
        ],
      ),
    );
  }

  Color _accentColor(PersonaType type) {
    switch (type) {
      case PersonaType.compound:
        return AppColors.dustBad;
      case PersonaType.medicalCare:
        return AppColors.dustNormal;
      case PersonaType.activeAndSensitive:
        return AppColors.dustNormal;
      case PersonaType.activeOutdoor:
        return AppColors.primary;
      case PersonaType.sensitiveFeel:
        return AppColors.primary;
      case PersonaType.general:
        return AppColors.secondary;
    }
  }
}

class _KeywordTag extends StatelessWidget {
  final String label;
  final Color color;
  const _KeywordTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '# $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 2. 민감도 분해 (w1 / w2 / w3 + S 합산)
// ─────────────────────────────────────────────────────────

class _SensitivityBreakdown extends StatelessWidget {
  final UserProfile profile;
  final double s;
  const _SensitivityBreakdown({required this.profile, required this.s});

  @override
  Widget build(BuildContext context) {
    final w1 = _w1(profile);
    final w2 = _w2(profile);
    final w3 = _w3(profile);

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
            label: '기저질환',
            sublabel: profile.hasCondition
                ? profile.conditionType.label
                : '해당 없음',
            weight: w1,
            maxWeight: 0.3,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '야외 활동',
            sublabel: profile.activityLevel.description,
            weight: w2,
            maxWeight: 0.2,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: '체감 민감도',
            sublabel: _sensitivityDesc(profile.sensitivity),
            weight: w3,
            maxWeight: 0.2,
          ),
          const Divider(height: 28, color: AppColors.divider),

          // S 합산 게이지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '민감도 계수 (S)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${s.toStringAsFixed(2)}  /  0.60',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: s / SensitivityCalculator.sMax,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_sColor(s)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              SensitivityCalculator.label(s),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _sColor(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sensitivityDesc(SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.low:    return '잘 느끼지 못함';
      case SensitivityLevel.normal: return '가끔 느낌';
      case SensitivityLevel.high:   return '바로 느낌';
    }
  }

  double _w1(UserProfile p) =>
      p.hasCondition ? (p.severity == Severity.mild ? 0.2 : 0.3) : 0.0;
  double _w2(UserProfile p) {
    switch (p.activityLevel) {
      case ActivityLevel.low:    return 0.0;
      case ActivityLevel.normal: return 0.1;
      case ActivityLevel.high:   return 0.2;
    }
  }
  double _w3(UserProfile p) {
    switch (p.sensitivity) {
      case SensitivityLevel.low:    return 0.0;
      case SensitivityLevel.normal: return 0.1;
      case SensitivityLevel.high:   return 0.2;
    }
  }

  Color _sColor(double s) {
    if (s >= 0.5) return AppColors.dustBad;
    if (s >= 0.3) return AppColors.dustNormal;
    if (s >= 0.1) return AppColors.secondary;
    return AppColors.textSecondary;
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
  final double s;
  const _ThresholdCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final usesFinal = s >= SensitivityCalculator.sThreshold;
    final tFinal = usesFinal ? SensitivityCalculator.threshold(s) : 36.0;
    final diff = 36.0 - tFinal;
    final maskType = s >= 0.4 ? 'KF94' : 'KF80';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // 비교 행 — 일반인 vs 나
          Row(
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
                  subValue: usesFinal ? maskType : 'KF80',
                  highlight: true,
                ),
              ),
            ],
          ),
          if (usesFinal && diff > 0) ...[
            const Divider(height: 24, color: AppColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_downward,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: '일반 기준보다 '),
                      TextSpan(
                        text: '${diff.toStringAsFixed(0)} μg/m³ 낮은',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' 수치에서 알림을 드려요'),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
// 4. 행동 가이드
// ─────────────────────────────────────────────────────────

class _ActionGuideList extends StatelessWidget {
  final List<String> guides;
  const _ActionGuideList({required this.guides});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: guides.asMap().entries.map((e) {
          final index = e.key;
          final guide = e.value;
          final isLast = index == guides.length - 1;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guide,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast) const SizedBox(height: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
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
