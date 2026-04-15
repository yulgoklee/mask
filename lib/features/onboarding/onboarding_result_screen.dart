import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';

/// 온보딩 완료 후 개인 민감도 분석 결과 화면
///
/// Phase 3 구성:
///  ① 헤더 — 민감도 레벨 배지 + "N.N배 더 민감" 문구
///  ② 육각형 RadarChart — 6축 가중치 시각화
///  ③ 임계치 Area Chart — T_final vs 일반 기준 35μg/m³
///  ④ 마스크 권장 등급 카드
///  ⑤ 가상 알림 시뮬레이션 카드 (탭 → 가중치 상세 시트)
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
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 28, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile    = ref.watch(profileProvider);
    final setting    = ref.watch(notificationSettingProvider);
    final s          = SensitivityCalculator.compute(profile);
    final tFinal     = SensitivityCalculator.threshold(s);
    final multiplier = SensitivityCalculator.sensitivityMultiplier(s);
    final labelStr   = SensitivityCalculator.label(s);
    final maskStr    = SensitivityCalculator.maskType(s);
    final name       = profile.displayName;

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

                    // ① 헤더 ────────────────────────────────────
                    _Header(
                      name: name,
                      multiplier: multiplier,
                      labelStr: labelStr,
                    ),

                    const SizedBox(height: 28),

                    // ② 육각형 RadarChart ────────────────────────
                    _SensitivityRadarChart(
                      profile: profile,
                      s: s,
                    ),

                    const SizedBox(height: 20),

                    // ③ 임계치 비교 Area Chart ───────────────────
                    _ThresholdChart(tFinal: tFinal),

                    const SizedBox(height: 20),

                    // ④ 마스크 권장 카드 ─────────────────────────
                    if (maskStr != null) ...[
                      _MaskCard(maskType: maskStr),
                      const SizedBox(height: 16),
                    ],

                    // ⑤ 알림 시뮬레이션 카드 ────────────────────
                    _NotificationPreviewCard(
                      profile: profile,
                      setting: setting,
                      s: s,
                      tFinal: tFinal,
                      onTap: () =>
                          _showWeightSheet(context, profile, s, tFinal),
                    ),

                    const SizedBox(height: 32),

                    // 다음 단계 버튼 ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/location_setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '위치 설정 →',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeightSheet(
    BuildContext context,
    UserProfile profile,
    double s,
    double tFinal,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WeightExplanationSheet(
        profile: profile,
        s: s,
        tFinal: tFinal,
      ),
    );
  }
}

// ── ① 헤더 ────────────────────────────────────────────────────

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
    final multiplierText =
        multiplier.isInfinite ? '∞배' : '${multiplier.toStringAsFixed(1)}배';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: 0.10),
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

// ── ② 육각형 RadarChart ────────────────────────────────────────
//
// 6축: 기저질환 / 야외활동 / 신체반응 / 피부·임신 / 부양가족 / 종합민감도
// 각 값은 해당 가중치를 최대치로 나눠 0–100 으로 정규화

class _SensitivityRadarChart extends StatelessWidget {
  final UserProfile profile;
  final double s;

  const _SensitivityRadarChart({
    required this.profile,
    required this.s,
  });

  static const _titles = [
    '기저질환',
    '야외활동',
    '신체반응',
    '피부·임신',
    '부양가족',
    '종합',
  ];

  List<double> _values() {
    final w1 = SensitivityCalculator.conditionWeight(profile);
    final w2 = SensitivityCalculator.activityWeight(profile.activityLevel);
    final w3 = SensitivityCalculator.sensitivityWeight(profile.sensitivity);

    // 피부·임신: skinProcedure(0.25) or pregnancy conditionType(0.3) 중 최댓값
    final skinVal = profile.hasSkinProcedure ? 0.25 : 0.0;
    final pregnancyVal =
        profile.conditionType == ConditionType.pregnancy ? 0.30 : 0.0;
    final axis4 = (skinVal > pregnancyVal ? skinVal : pregnancyVal) / 0.30;

    // 부양가족: 0 or 1
    final axis5 = profile.hasDependents ? 1.0 : 0.0;

    // 종합 S (clamped 0.6)
    final axis6 = s / SensitivityCalculator.sMax;

    return [
      (w1 / 0.30).clamp(0.0, 1.0) * 100,
      (w2 / 0.20).clamp(0.0, 1.0) * 100,
      (w3 / 0.20).clamp(0.0, 1.0) * 100,
      axis4.clamp(0.0, 1.0) * 100,
      axis5 * 100,
      axis6.clamp(0.0, 1.0) * 100,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final values = _values();
    // 모두 0이면 최소 표시값 부여 (차트 형태 유지)
    final hasAny = values.any((v) => v > 0);
    final display = hasAny
        ? values
        : List.generate(6, (_) => 5.0);

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
          // 카드 헤더
          Row(
            children: [
              const Text(
                '민감도 프로필',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'S = ${s.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '6개 항목으로 나를 분석한 결과예요',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // RadarChart
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                    color: Colors.transparent, fontSize: 0),
                gridBorderData: BorderSide(
                    color: AppColors.divider, width: 1),
                radarBorderData: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5),
                titleTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                titlePositionPercentageOffset: 0.18,
                getTitle: (index, angle) => RadarChartTitle(
                  text: _titles[index],
                  angle: 0,
                ),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.15),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 4,
                    dataEntries: display
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                  ),
                ],
                radarMaxEntryValue: 100,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 축 범례
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(_titles.length, (i) {
              final pct = display[i].toInt();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pct > 0
                          ? AppColors.primary
                          : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_titles[i]} $pct%',
                    style: TextStyle(
                      fontSize: 11,
                      color: pct > 0
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── ③ 임계치 비교 Area Chart ───────────────────────────────────

class _ThresholdChart extends StatelessWidget {
  final double tFinal;

  const _ThresholdChart({required this.tFinal});

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
    const tStandard = SensitivityCalculator.tStandard;

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
            '알림 임계치 비교',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '내 기준 ${tFinal.toStringAsFixed(1)} μg/m³  ·  일반 기준 ${tStandard.toStringAsFixed(0)} μg/m³',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
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
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        if (value == 0) {
                          return const Text('지금',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary));
                        }
                        if (value == 6) {
                          return const Text('+6h',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
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
                        padding:
                            const EdgeInsets.only(left: 4, bottom: 4),
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
                        padding:
                            const EdgeInsets.only(left: 4, bottom: 4),
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
                          AppColors.primary.withValues(alpha: 0.20),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(
                  color: AppColors.coral, label: '내 알림 임계치'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.textSecondary,
                  label: '일반 기준 (35 μg/m³)'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.primary, label: 'PM2.5 예상 곡선'),
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
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── ④ 마스크 권장 카드 ─────────────────────────────────────────

class _MaskCard extends StatelessWidget {
  final String maskType;
  const _MaskCard({required this.maskType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30)),
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

// ── ⑤ 가상 알림 시뮬레이션 카드 ──────────────────────────────

class _NotificationPreviewCard extends StatelessWidget {
  final UserProfile profile;
  final NotificationSetting setting;
  final double s;
  final double tFinal;
  final VoidCallback onTap;

  const _NotificationPreviewCard({
    required this.profile,
    required this.setting,
    required this.s,
    required this.tFinal,
    required this.onTap,
  });

  String? _nextAlertLabel() {
    if (setting.morningAlertEnabled) {
      final m = setting.morningAlertMinute.toString().padLeft(2, '0');
      final ampm = setting.morningAlertHour < 12 ? '오전' : '오후';
      final h12 = setting.morningAlertHour == 0
          ? 12
          : setting.morningAlertHour <= 12
              ? setting.morningAlertHour
              : setting.morningAlertHour - 12;
      return '내일 $ampm ${h12.toString().padLeft(2, '0')}:$m';
    }
    if (setting.eveningForecastEnabled) {
      final hh = setting.eveningForecastHour.toString().padLeft(2, '0');
      final mm = setting.eveningForecastMinute.toString().padLeft(2, '0');
      return '오늘 저녁 $hh:$mm';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nextLabel = _nextAlertLabel();
    final name = profile.displayName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  '알림 시뮬레이션',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Text(
                  '가중치 보기',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.primary),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7)),
              ],
            ),

            if (nextLabel != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$nextLabel에 이런 알림이 울릴 예정이에요',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
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
                      color: AppColors.coral.withValues(alpha: 0.10),
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
                        Text(
                          '😷 $name, 오늘 마스크를 챙기는 게 좋아요',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PM2.5 ${tFinal.toStringAsFixed(0)}μg/m³ · 보통\n'
                          '당신의 기준(${tFinal.toStringAsFixed(1)}μg/m³)을 넘었어요.\n'
                          '마스크 착용을 권해드려요 😊',
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
            const SizedBox(height: 8),
            const Text(
              '* 실제 알림은 측정소 데이터 기반으로 발송됩니다. 탭하면 계산 방법을 볼 수 있어요.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 가중치 상세 Bottom Sheet ──────────────────────────────────
//
// 5개 가중치 항목 전체 표시:
//   w1 기저질환 / w2 야외활동 / w3 신체반응 / w_spec 특별상태 / w_pref 편의성향

class _WeightExplanationSheet extends StatelessWidget {
  final UserProfile profile;
  final double s;
  final double tFinal;

  const _WeightExplanationSheet({
    required this.profile,
    required this.s,
    required this.tFinal,
  });

  @override
  Widget build(BuildContext context) {
    final w1    = SensitivityCalculator.conditionWeight(profile);
    final w2    = SensitivityCalculator.activityWeight(profile.activityLevel);
    final w3    = SensitivityCalculator.sensitivityWeight(profile.sensitivity);
    final wSpec = SensitivityCalculator.specialStateWeight(profile);
    final wPref = SensitivityCalculator.prefWeight(profile);
    final rawSum = w1 + w2 + w3 + wSpec + wPref;
    final isClamped = rawSum > SensitivityCalculator.sMax;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '나만의 알림 기준, 이렇게 계산했어요',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '다섯 가지 항목을 더해 민감도 계수(S)를 산출합니다.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // w1 기저질환
              _WeightRow(
                icon: Icons.favorite_outline,
                label: '기저질환',
                sublabel: profile.hasCondition
                    ? '${profile.conditionType.label} · ${profile.severity.label}'
                    : '해당 없음',
                value: w1,
                maxValue: 0.3,
                isPositive: true,
              ),
              const SizedBox(height: 10),

              // w2 야외활동
              _WeightRow(
                icon: Icons.directions_walk,
                label: '야외 활동량',
                sublabel: profile.activityLevel.description,
                value: w2,
                maxValue: 0.2,
                isPositive: true,
              ),
              const SizedBox(height: 10),

              // w3 신체반응
              _WeightRow(
                icon: Icons.tune,
                label: '신체 반응도',
                sublabel: profile.sensitivity.label,
                value: w3,
                maxValue: 0.2,
                isPositive: true,
              ),
              const SizedBox(height: 10),

              // w_spec 특별상태
              _WeightRow(
                icon: Icons.health_and_safety_outlined,
                label: '특별 상태',
                sublabel: _specLabel(profile),
                value: wSpec,
                maxValue: 0.4,
                isPositive: true,
              ),
              const SizedBox(height: 10),

              // w_pref 편의성향
              _WeightRow(
                icon: Icons.masks_outlined,
                label: '마스크 편의',
                sublabel: profile.maskDiscomfort
                    ? '답답함 있음 (기준 소폭 완화)'
                    : '착용 문제없음',
                value: wPref.abs(),
                maxValue: 0.08,
                isPositive: false,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.divider),
              ),

              // S 계산 결과
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  children: [
                    const TextSpan(text: 'S = '),
                    TextSpan(
                      text: 'min(${w1.toStringAsFixed(2)} + '
                          '${w2.toStringAsFixed(2)} + '
                          '${w3.toStringAsFixed(2)} + '
                          '${wSpec.toStringAsFixed(2)} '
                          '${wPref < 0 ? '− ${wPref.abs().toStringAsFixed(2)}' : ''}, 0.6)',
                      style: const TextStyle(
                          color: AppColors.textSecondary),
                    ),
                    const TextSpan(text: ' = '),
                    TextSpan(
                      text: s.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.coral,
                      ),
                    ),
                    if (isClamped)
                      const TextSpan(
                        text: '  (상한 적용)',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  children: [
                    const TextSpan(text: '알림 기준 = 35 × (1 − '),
                    TextSpan(
                      text: s.toStringAsFixed(2),
                      style:
                          const TextStyle(color: AppColors.coral),
                    ),
                    const TextSpan(text: ') = '),
                    TextSpan(
                      text: '${tFinal.toStringAsFixed(1)} μg/m³',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PM2.5가 ${tFinal.toStringAsFixed(1)}μg/m³을 넘으면\n'
                  '일반인 기준(35μg/m³)보다 먼저 알림을 드려요.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _specLabel(UserProfile profile) {
    final parts = <String>[];
    if (profile.conditionType == ConditionType.pregnancy) parts.add('임신');
    if (profile.hasSkinProcedure) parts.add('피부 시술');
    if (profile.hasDependents) parts.add('부양가족');
    return parts.isEmpty ? '해당 없음' : parts.join(' · ');
  }
}

// ── 가중치 행 위젯 ─────────────────────────────────────────────

class _WeightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final double value;
  final double maxValue;
  final bool isPositive; // false = 음수 가중치 (완화)

  const _WeightRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.maxValue,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final fillRatio =
        maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final hasWeight = value > 0;
    final barColor = isPositive
        ? (hasWeight ? AppColors.coral : AppColors.divider)
        : (hasWeight ? AppColors.primary : AppColors.divider);
    final iconColor = isPositive
        ? (hasWeight ? AppColors.coral : AppColors.textHint)
        : (hasWeight ? AppColors.primary : AppColors.textHint);
    final bgColor = isPositive
        ? (hasWeight
            ? AppColors.coral.withValues(alpha: 0.10)
            : AppColors.surfaceVariant)
        : (hasWeight
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surfaceVariant);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sublabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fillRatio,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isPositive
              ? '+${value.toStringAsFixed(2)}'
              : '−${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: hasWeight ? barColor : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
