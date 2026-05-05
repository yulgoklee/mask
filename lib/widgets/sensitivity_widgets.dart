import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/design_tokens.dart';
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
//
// [showSubtitle] true이면 "초미세먼지 기준" 라벨 + PM10 부가 설명을 표시.
// [expandable]   true이면 카드 탭 시 PM2.5·PM10 상세 기준 펼치기/접기 가능.
//                프로필 탭에서만 true로 사용 권장.

class ThresholdCompareCard extends StatefulWidget {
  final UserProfile profile;
  final bool showSubtitle;
  final bool expandable;

  const ThresholdCompareCard({
    super.key,
    required this.profile,
    this.showSubtitle = false,
    this.expandable = false,
  });

  @override
  State<ThresholdCompareCard> createState() => _ThresholdCompareCardState();
}

class _ThresholdCompareCardState extends State<ThresholdCompareCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tFinal   = widget.profile.tFinal;
    final tFinalPm10 = tFinal * (80.0 / 35.0);
    final maskType = const ThresholdEngine().recommendedMaskType(widget.profile);

    return GestureDetector(
      onTap: widget.expandable
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 상단: 라벨 + chevron ─────────────────────────
            if (widget.showSubtitle) ...[
              Row(
                children: [
                  const Text(
                    '초미세먼지(PM2.5) 기준',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (widget.expandable)
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ] else if (widget.expandable) ...[
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            // ── 메인 비교 행 ─────────────────────────────────
            Row(
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
            // ── PM10 부가 설명 (showSubtitle) ────────────────
            if (widget.showSubtitle) ...[
              const SizedBox(height: 10),
              Text(
                '미세먼지(PM10)·황사도 함께 평가해요',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
            // ── 펼치기 상세 (expandable) ─────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _expanded
                  ? _ExpandedDetail(
                      tFinal: tFinal,
                      tFinalPm10: tFinalPm10,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 펼쳐진 상태의 PM2.5 / PM10 상세 기준표
class _ExpandedDetail extends StatelessWidget {
  final double tFinal;
  final double tFinalPm10;

  const _ExpandedDetail({required this.tFinal, required this.tFinalPm10});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'PM2.5 (초미세먼지)',
          rows: [
            _DetailRow(label: '내 기준', value: '${tFinal.toStringAsFixed(0)} μg/m³', highlight: true),
            const _DetailRow(label: '일반 기준', value: '35 μg/m³  (환경부 \'나쁨\' 진입)', highlight: false),
            const _DetailRow(label: '좋음', value: '15 μg/m³', highlight: false),
          ],
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'PM10 (미세먼지·황사)',
          rows: [
            _DetailRow(
              label: '내 기준',
              value: '${tFinalPm10.toStringAsFixed(0)} μg/m³  (내 PM2.5 기준 × 80/35)',
              highlight: true,
            ),
            const _DetailRow(label: '일반 기준', value: '80 μg/m³', highlight: false),
            const _DetailRow(label: '좋음', value: '30 μg/m³', highlight: false),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DT.grayLt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '알림 발송 시 두 수치 중 비율(내 기준 대비)이 더 큰 쪽이 우선해요.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;

  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: r.highlight
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: r.highlight
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: r.highlight
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: r.highlight
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.highlight,
  });
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

