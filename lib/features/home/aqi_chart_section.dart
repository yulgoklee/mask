import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/engine/threshold_engine.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/today_situation.dart';
import '../../data/repositories/aqi_history_repository.dart';
import '../../providers/providers.dart';

/// PM2.5 추이 Area Chart — 과거 6h 실측 + 미래 3h 예측
///
/// [forecastGrade] : 미래 3시간 예측에 사용할 예보 등급 ('좋음'|'보통'|'나쁨'|'매우나쁨')
class AqiChartSection extends ConsumerWidget {
  final String forecastGrade;

  const AqiChartSection({super.key, required this.forecastGrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(aqiChartDataProvider(forecastGrade));
    final profile = ref.watch(profileProvider);
    final todaySituations = ref.watch(todaySituationProvider);

    final s = SensitivityCalculator.compute(profile);
    double tFinal = SensitivityCalculator.threshold(s);

    // 오늘 야외운동 토글 활성 → W_lifestyle = 3h+(0.15) 적용하여 tFinal 즉시 재계산
    // 이미 3h+ 설정이면 변화 없음
    final isOutdoorToday = todaySituations.any(
      (s) =>
          s.type == TodaySituationType.outdoorExercise && s.isActive,
    );
    if (isOutdoorToday) {
      const engine = ThresholdEngine();
      final wHealth = engine.computeWHealth(profile);
      final currentWL = engine.computeWLifestyle(profile);
      const maxOutdoorW = 0.15;
      if (currentWL < maxOutdoorW) {
        final adjusted =
            (35.0 * (1 - wHealth - maxOutdoorW)).clamp(15.0, 35.0);
        tFinal = min(tFinal, adjusted);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: chartAsync.when(
        loading: () => const _ChartSkeleton(),
        error: (_, __) => const _ChartError(),
        data: (data) => _ChartContent(
          chartData: data,
          tFinal: tFinal,
          nickname: profile.nickname,
        ),
      ),
    );
  }
}

// ── 차트 본문 ─────────────────────────────────────────────────

class _ChartContent extends StatelessWidget {
  final AqiChartData chartData;
  final double tFinal;
  final String nickname;

  const _ChartContent({
    required this.chartData,
    required this.tFinal,
    required this.nickname,
  });

  static String _timeLabel(DateTime t) {
    final h = t.hour;
    final period = h < 12 ? '오전' : '오후';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $displayH시';
  }

  @override
  Widget build(BuildContext context) {
    if (!chartData.hasEnoughData) return const _ZeroDayView();

    final measured =
        chartData.measuredPoints.where((p) => p.pm25 != null).toList();
    final forecast =
        chartData.forecastPoints.where((p) => p.pm25 != null).toList();
    if (measured.isEmpty) return const _ZeroDayView();

    final startTime = measured.first.time;
    double toX(DateTime t) => t.difference(startTime).inMinutes / 60.0;

    final measuredSpots =
        measured.map((p) => FlSpot(toX(p.time), p.pm25!)).toList();
    final forecastSpots = [
      measuredSpots.last, // 연속성 유지
      ...forecast.map((p) => FlSpot(toX(p.time), p.pm25!)),
    ];

    // Y축 범위
    final allValues = [
      ...measured.map((p) => p.pm25!),
      ...forecast.map((p) => p.pm25!),
    ];
    final dataMax = allValues.reduce(max);
    final maxY = max(dataMax, tFinal * 1.3) + 5.0;

    // T_final 기준 그라디언트 정지점 계산 (위→아래: 위험빨강→안전파랑)
    final tStop = (1.0 - tFinal / maxY).clamp(0.01, 0.99);
    const dangerColor = Color(0xFFFF5252);
    const safeColor = Color(0xFF448AFF);

    LinearGradient areaGradient(double opacity) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, tStop - 0.001, tStop + 0.001, 1.0],
          colors: [
            dangerColor.withValues(alpha: 0.40 * opacity),
            dangerColor.withValues(alpha: 0.18 * opacity),
            safeColor.withValues(alpha: 0.18 * opacity),
            safeColor.withValues(alpha: 0.35 * opacity),
          ],
        );

    final nowX = toX(measured.last.time);
    final endX = forecastSpots.last.x;

    // X축 레이블: 시작·지금·끝
    final Map<double, String> labelTimes = {
      0.0: _timeLabel(measured.first.time),
      nowX: '지금',
      endX: _timeLabel(
          forecast.isNotEmpty ? forecast.last.time : measured.last.time),
    };

    final safeResult = chartData.safeTimeResult(tFinal);
    final guideText = safeResult.toGuideText(nickname: nickname);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더: 타이틀 + 신선도 ──────────────────────────────
        Row(
          children: [
            const Text(
              'PM2.5 추이',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              chartData.freshnessLabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Area Chart ────────────────────────────────────────
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: endX,
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),

              // T_final 기준선 (점선 회색)
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: tFinal,
                    color: const Color(0xFF757575),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.bottomRight,
                      padding:
                          const EdgeInsets.only(right: 4, bottom: 2),
                      labelResolver: (_) =>
                          '기준 ${tFinal.toStringAsFixed(0)}μg',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      String? label;
                      for (final entry in labelTimes.entries) {
                        if ((value - entry.key).abs() < 0.25) {
                          label = entry.value;
                          break;
                        }
                      }
                      if (label == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: label == '지금' ? 11 : 10,
                            fontWeight: label == '지금'
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: label == '지금'
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              lineBarsData: [
                // 실측 (과거 6h) — 실선
                LineChartBarData(
                  spots: measuredSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: areaGradient(1.0),
                  ),
                ),
                // 예측 (미래 3h) — 반투명 점선
                if (forecastSpots.length > 1)
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.primary.withValues(alpha: 0.45),
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: areaGradient(0.45),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── 마스크 해제 Time Guide ─────────────────────────────
        if (guideText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: safeResult.isFound
                  ? safeColor.withValues(alpha: 0.08)
                  : dangerColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  safeResult.isFound
                      ? Icons.check_circle_outline
                      : Icons.schedule_outlined,
                  size: 15,
                  color: safeResult.isFound ? safeColor : dangerColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    guideText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: safeResult.isFound ? safeColor : dangerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── 앱 조회 기준 업데이트 시각 ─────────────────────────
        if (chartData.updatedAgoLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              chartData.updatedAgoLabel,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Zero-day (데이터 수집 중) ──────────────────────────────────

class _ZeroDayView extends StatelessWidget {
  const _ZeroDayView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.hourglass_top_outlined,
              size: 32, color: AppColors.textHint),
          SizedBox(height: 10),
          Text(
            '데이터를 수집 중이에요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '잠시 후 PM2.5 추이 차트가 표시됩니다',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ── 로딩 스켈레톤 ─────────────────────────────────────────────

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ── 에러 ─────────────────────────────────────────────────────

class _ChartError extends StatelessWidget {
  const _ChartError();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          '차트 데이터를 불러올 수 없어요',
          style:
              TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
