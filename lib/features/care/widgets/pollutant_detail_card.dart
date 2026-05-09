import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/dust_providers.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';

// ── 등급 → Lt 배경색 (§3.4 v4 — 위젯 내부 전용) ─────────
// DT.gradeCardBg 헬퍼는 건드리지 않음 (다른 탭 '보통=흰색' 룰 보존).
// 이 파일에서만 적용: 좋음→safeLt, 보통→primaryLt, 나쁨→cautionLt, 매우나쁨→dangerLt
Color _gradeLt(String? grade) => switch (grade) {
  '좋음'    => DT.safeLt,
  '보통'    => DT.primaryLt,
  '나쁨'    => DT.cautionLt,
  '매우나쁨' => DT.dangerLt,
  _         => DT.grayLt,
};

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

  /// 펼친 상태 — 모든 오염물질 6개 + 등급별 색
  Widget _buildExpanded(PollutantCardData data) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // PM2.5 / PM10 (등급 색)
          Row(
            children: [
              Expanded(
                child: _PollutantBox(
                  name:      '초미세먼지',
                  value:     data.pm25,
                  unit:      'µg/m³',
                  grade:     data.pm25Grade,
                  precision: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PollutantBox(
                  name:      '미세먼지',
                  value:     data.pm10,
                  unit:      'µg/m³',
                  grade:     data.pm10Grade,
                  precision: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // O3 / NO2
          Row(
            children: [
              Expanded(
                child: _PollutantBox(
                  name:      'O3 (오존)',
                  value:     data.o3,
                  unit:      'ppm',
                  grade:     data.o3Grade,
                  precision: 3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PollutantBox(
                  name:      'NO2 (이산화질소)',
                  value:     data.no2,
                  unit:      'ppm',
                  grade:     data.no2Grade,
                  precision: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CO / SO2
          Row(
            children: [
              Expanded(
                child: _PollutantBox(
                  name:      'CO (일산화탄소)',
                  value:     data.co,
                  unit:      'ppm',
                  grade:     data.coGrade,
                  precision: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PollutantBox(
                  name:      'SO2 (아황산가스)',
                  value:     data.so2,
                  unit:      'ppm',
                  grade:     data.so2Grade,
                  precision: 3,
                ),
              ),
            ],
          ),
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

// ── 오염물질 박스 ──────────────────────────────────────────
// PM2.5/PM10 (precision=0, µg/m³) 과 O3/NO2/CO/SO2 (precision=1~3, ppm) 공용.

class _PollutantBox extends StatelessWidget {
  final String  name;
  final double? value;
  final String  unit;
  final String? grade;

  /// 표시 소수점 자리수 (0 = 정수)
  final int precision;

  const _PollutantBox({
    required this.name,
    required this.value,
    required this.unit,
    required this.grade,
    required this.precision,
  });

  @override
  Widget build(BuildContext context) {
    final gradeStr = (grade?.isNotEmpty == true) ? grade! : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _gradeLt(gradeStr),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 항목명 + 등급 배지 ────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      DT.gray,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (gradeStr != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        DT.gradeBadgeBg(gradeStr),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    gradeStr,
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.bold,
                      color:      DT.gradeText(gradeStr),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // ── 숫자 + 단위 ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value != null
                    ? (precision == 0
                        ? '${value!.toInt()}'
                        : value!.toStringAsFixed(precision))
                    : '--',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize:   20,
                  fontWeight: FontWeight.bold,
                  color:      DT.text,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: DT.gray),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
