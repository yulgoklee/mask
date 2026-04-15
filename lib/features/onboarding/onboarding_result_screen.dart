import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../providers/providers.dart';

/// 온보딩 완료 후 개인 민감도 분석 결과 화면
///
/// 표시 정보:
///  - 일반인 대비 민감도 배율 (X.X배)
///  - S 기반 알림 임계치 vs 일반 기준선 비교 Area Chart
///  - 마스크 권장 등급
///  - 알림 미리보기 카드
class OnboardingResultScreen extends ConsumerStatefulWidget {
  const OnboardingResultScreen({super.key});

  @override
  ConsumerState<OnboardingResultScreen> createState() =>
      _OnboardingResultScreenState();
}

class _OnboardingResultScreenState
    extends ConsumerState<OnboardingResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile  = ref.watch(profileProvider);
    final s        = SensitivityCalculator.compute(profile);
    final tFinal   = SensitivityCalculator.threshold(s);
    final multiplier = SensitivityCalculator.sensitivityMultiplier(s);
    final labelStr = SensitivityCalculator.label(s);
    final maskStr  = SensitivityCalculator.maskType(s);
    final name     = profile.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fadeIn,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // ── 헤더 ──────────────────────────────────
                    _Header(name: name, multiplier: multiplier, labelStr: labelStr),

                    const SizedBox(height: 28),

                    // ── 임계치 비교 Area Chart ─────────────────
                    _ThresholdChart(tFinal: tFinal),

                    const SizedBox(height: 20),

                    // ── 마스크 권장 카드 ─────────────────────────
                    if (maskStr != null) ...[
                      _MaskCard(maskType: maskStr),
                      const SizedBox(height: 16),
                    ],

                    // ── 알림 미리보기 카드 ─────────────────────
                    _NotificationPreviewCard(tFinal: tFinal),

                    const SizedBox(height: 32),

                    // ── 다음 단계 버튼 (위치 설정으로 이동) ────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/location_setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '위치 설정 →',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 헤더 위젯 ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String name;
  final double multiplier;
  final String labelStr;

  const _Header({
    required this.name,
    required this.multiplier,
    required this.labelStr,
  });

  @override
  Widget build(BuildContext context) {
    final multiplierText = multiplier.isInfinite
        ? '∞배'
        : '${multiplier.toStringAsFixed(1)}배';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 배율 배지
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.coral.withAlpha(26),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.coral, size: 18),
              const SizedBox(width: 6),
              Text(
                '민감도 $labelStr',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$name,',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 22, color: AppColors.textPrimary),
            children: [
              const TextSpan(text: '일반인보다 '),
              TextSpan(
                text: multiplierText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const TextSpan(text: ' 더\n민감하게 관리돼요'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '더 낮은 농도에서도 마스크 알림을 드릴게요.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── 임계치 비교 Area Chart ─────────────────────────────────

/// 전형적인 아침 PM2.5 상승 곡선 위에
/// 개인 임계치(T_final)와 일반 기준(35 μg/m³)을 비교해 보여줌
class _ThresholdChart extends StatelessWidget {
  final double tFinal;

  const _ThresholdChart({required this.tFinal});

  /// 오전 6시간 대표 PM2.5 패턴 (교통·출근 시간대 상승 모사)
  static const _rawSpots = [
    FlSpot(0, 10),
    FlSpot(1, 15),
    FlSpot(2, 20),
    FlSpot(3, 27),
    FlSpot(4, 33),
    FlSpot(5, 37),
    FlSpot(6, 40),
  ];

  @override
  Widget build(BuildContext context) {
    const tStandard = SensitivityCalculator.tStandard; // 35

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '임계치 비교',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '내 알림 기준 ${tFinal.toStringAsFixed(1)} μg/m³  ·  일반 기준 ${tStandard.toStringAsFixed(0)} μg/m³',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 50,
                clipData: const FlClipData.all(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const Text('지금', style: TextStyle(fontSize: 10, color: AppColors.textSecondary));
                        if (value == 6) return const Text('+6h', style: TextStyle(fontSize: 10, color: AppColors.textSecondary));
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                // 수평 기준선 2개
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: tFinal,
                      color: AppColors.coral,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.coral,
                        ),
                        labelResolver: (_) => '내 기준',
                      ),
                    ),
                    HorizontalLine(
                      y: tStandard,
                      color: AppColors.textSecondary,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        labelResolver: (_) => '일반 기준',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _rawSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withAlpha(51),
                          AppColors.primary.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.coral, label: '내 알림 임계치'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.textSecondary, label: '일반 기준 (35 μg/m³)'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.primary, label: 'PM2.5 예상 곡선'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── 마스크 권장 카드 ─────────────────────────────────────────

class _MaskCard extends StatelessWidget {
  final String maskType;
  const _MaskCard({required this.maskType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Text('😷', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '마스크 권장 등급',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                '$maskType 이상 권장',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 알림 미리보기 카드 ──────────────────────────────────────

class _NotificationPreviewCard extends StatelessWidget {
  final double tFinal;
  const _NotificationPreviewCard({required this.tFinal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_outlined,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                '알림 미리보기',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 모의 알림 카드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.masks_outlined,
                      size: 18, color: AppColors.coral),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '마스크 알림',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PM2.5 ${tFinal.toStringAsFixed(0)} μg/m³ — '
                        '마스크 착용을 권장드려요. 😷\n'
                        '(일반인 기준 미달이지만 건강을 위해 주의하세요)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '* 실제 알림은 측정소 데이터 기반으로 발송됩니다.',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
