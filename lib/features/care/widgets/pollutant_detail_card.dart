import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/dust_providers.dart';
import '../../../providers/profile_providers.dart';
import '../../../widgets/sensitivity_widgets.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';

// ── 세부 수치 카드 ─────────────────────────────────────────

class PollutantDetailCard extends ConsumerStatefulWidget {
  const PollutantDetailCard({super.key});

  @override
  ConsumerState<PollutantDetailCard> createState() => _PollutantDetailCardState();
}

class _PollutantDetailCardState extends ConsumerState<PollutantDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data      = ref.watch(pollutantCardProvider);
    final dustAsync = ref.watch(dustDataProvider);
    final isLoading = dustAsync.isLoading;

    final card = GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drill-down 토글 헤더 ──────────────────────
          _buildToggleHint(),

          // ── 펼침 (열린 경우만 노출) ───────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve:    Curves.easeOutCubic,
            child:    _expanded
                ? _buildExpanded(data)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);

    if (!isLoading) return card;
    return card.animate().shimmer(duration: 1200.ms, color: const Color(0xFFF9FAFB));
  }

  /// 펼친 상태 — Drill-down 깊은 정보
  /// 1. 임계치 비교 (일반 vs 내 임계치)
  /// 2. 5막대 분석 (호흡기·심혈관·흡연·연령·종합)
  /// 3. 모든 오염물질 6개
  /// 4. 자료원 출처
  Widget _buildExpanded(PollutantCardData data) {
    final profile = ref.watch(profileProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. 임계치 비교 ───────────────────────────────
          _SectionLabel(text: '내 임계치'),
          const SizedBox(height: 12),
          ThresholdCompareCard(
            profile: profile,
            showSubtitle: false,
            expandable: true,
          ),
          const SizedBox(height: 32),

          // ── 2. 민감도 분석 ───────────────────────────────
          _SectionLabel(text: '민감도 분석'),
          const SizedBox(height: 12),
          SensitivityBreakdown(profile: profile),
          const SizedBox(height: 32),

          // ── 3. 측정 수치 (모든 오염물질 6개) ──────────────
          _SectionLabel(text: '측정 수치'),
          const SizedBox(height: 12),
          _PollutantTable(data: data),
          const SizedBox(height: 32),

          // ── 4. 자료원 출처 ──────────────────────────────
          _SectionLabel(text: '근거 자료'),
          const SizedBox(height: 12),
          const _SourceList(),
        ],
      ),
    );
  }

  /// Drill-down 진입점 — "더 자세히 보기" / "접기" 토글
  Widget _buildToggleHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _expanded ? '접기' : '더 자세히 보기',
          style: const TextStyle(
            fontSize:      13,
            fontWeight:    FontWeight.w500,
            color:         DT.gray,
            letterSpacing: -0.1,
          ),
        ),
        AnimatedRotation(
          turns:    _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.expand_more, size: 16, color: DT.gray),
        ),
      ],
    );
  }
}

// ── 섹션 라벨 (Drill-down 안에서 사용) ────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize:      12,
        fontWeight:    FontWeight.w600,
        color:         DT.gray,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── 측정 수치 표 (hairline 행 — Drill-down 데이터 표) ─────

class _PollutantTable extends StatelessWidget {
  final PollutantCardData data;
  const _PollutantTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = <_PollutantRowData>[
      _PollutantRowData('초미세먼지',    data.pm25, 'µg/m³', data.pm25Grade, 0),
      _PollutantRowData('미세먼지',      data.pm10, 'µg/m³', data.pm10Grade, 0),
      _PollutantRowData('O3 (오존)',     data.o3,   'ppm',  data.o3Grade,  3),
      _PollutantRowData('NO2 (이산화질소)', data.no2, 'ppm',  data.no2Grade, 3),
      _PollutantRowData('CO (일산화탄소)',  data.co,  'ppm',  data.coGrade,  1),
      _PollutantRowData('SO2 (아황산가스)', data.so2, 'ppm',  data.so2Grade, 3),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              color:  DT.border.withValues(alpha: 0.5),
            ),
          _PollutantRowItem(row: rows[i]),
        ],
      ],
    );
  }
}

class _PollutantRowData {
  final String  label;
  final double? value;
  final String  unit;
  final String? grade;
  final int     precision;

  _PollutantRowData(this.label, this.value, this.unit, this.grade, this.precision);
}

class _PollutantRowItem extends StatelessWidget {
  final _PollutantRowData row;
  const _PollutantRowItem({required this.row});

  @override
  Widget build(BuildContext context) {
    final gradeStr = (row.grade?.isNotEmpty == true) ? row.grade! : null;
    final valueStr = row.value != null
        ? (row.precision == 0
            ? '${row.value!.toInt()}'
            : row.value!.toStringAsFixed(row.precision))
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // 등급 dot
          Container(
            width:  6,
            height: 6,
            decoration: BoxDecoration(
              color: gradeStr != null
                  ? DT.gradeText(gradeStr)
                  : DT.gray.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // 라벨
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize:      14,
                fontWeight:    FontWeight.w500,
                color:         DT.text,
                letterSpacing: -0.1,
              ),
            ),
          ),

          // 수치 + 단위
          Text(
            valueStr,
            style: const TextStyle(
              fontFamily:    'monospace',
              fontSize:      15,
              fontWeight:    FontWeight.w600,
              color:         DT.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            row.unit,
            style: const TextStyle(
              fontSize:   11,
              color:      DT.gray,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 자료원 목록 (Drill-down) ──────────────────────────────

class _SourceList extends StatelessWidget {
  const _SourceList();

  static const _sources = [
    'ARIA — 알레르기성 비염 가이드라인',
    'ATS — 운동 유발 기관지수축 (2013)',
    'WHO Global Air Quality Guidelines (2021)',
    '대한천식알레르기학회 (KAAACI)',
    'GOLD — COPD 가이드라인',
    'Asthma Control Test (ACT)',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _sources
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '· $s',
                  style: const TextStyle(
                    fontSize:      12,
                    fontWeight:    FontWeight.w400,
                    color:         DT.gray,
                    height:        1.5,
                    letterSpacing: -0.1,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

