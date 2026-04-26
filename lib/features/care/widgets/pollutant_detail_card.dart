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
      child: Container(
        decoration: BoxDecoration(
          color:        DT.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 2), blurRadius: 12, color: Color(0x0A000000)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 카드 제목 ─────────────────────────────────
            const Text(
              '세부 수치',
              style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      DT.text,
              ),
            ),
            const SizedBox(height: 12),

            // ── PM2.5 / PM10 ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PollutantBox(
                    name:      'PM2.5',
                    value:     data.pm25,
                    unit:      'µg/m³',
                    grade:     data.pm25Grade,
                    precision: 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PollutantBox(
                    name:      'PM10',
                    value:     data.pm10,
                    unit:      'µg/m³',
                    grade:     data.pm10Grade,
                    precision: 0,
                  ),
                ),
              ],
            ),

            // ── 확장: O3 / NO2 / CO / SO2 ─────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve:    Curves.easeOutCubic,
              child:    _expanded ? _buildExtended(data) : const SizedBox.shrink(),
            ),

            // ── 토글 힌트 ─────────────────────────────────
            _buildToggleHint(),
          ],
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);

    if (!isLoading) return card;
    return card.animate().shimmer(duration: 1200.ms, color: const Color(0xFFF9FAFB));
  }

  Widget _buildExtended(PollutantCardData data) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1, color: DT.border),
        const SizedBox(height: 16),

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
    );
  }

  Widget _buildToggleHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _expanded ? '접기' : '세부 항목 보기',
            style: const TextStyle(fontSize: 13, color: DT.gray),
          ),
          AnimatedRotation(
            turns:    _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more, size: 16, color: DT.gray),
          ),
        ],
      ),
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
