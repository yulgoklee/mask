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
/// 표시 정보:
///  - 일반인 대비 민감도 배율 (X.X배)
///  - S 기반 알림 임계치 vs 일반 기준선 비교 Area Chart
///  - 마스크 권장 등급
///  - 알림 미리보기 카드 (다음 알림 시간 연동 + 탭 → 가중치 설명 bottom sheet)
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

                    // ── 알림 미리보기 카드 (탭 → 가중치 설명) ─────
                    _NotificationPreviewCard(
                      profile: profile,
                      setting: setting,
                      s: s,
                      tFinal: tFinal,
                      onTap: () => _showWeightSheet(context, profile, s, tFinal),
                    ),

                    const SizedBox(height: 32),

                    // ── 다음 단계 버튼 (위치 설정으로 이동) ────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/location_setup'),
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

  // ── 가중치 설명 Bottom Sheet ──────────────────────────────

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
        // 민감도 레벨 배지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            style: const TextStyle(fontSize: 22, color: AppColors.textPrimary),
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
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              _LegendDot(
                  color: AppColors.textSecondary, label: '일반 기준 (35 μg/m³)'),
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
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
//
// ① 실제 설정된 다음 알림 시간 표시
//    ("내일 오전 08:00에 이런 알림이 울릴 예정이에요")
// ② 탭 → 가중치 설명 bottom sheet 열기

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

  /// 다음 예약 알림 시간 문자열 ("내일 오전 08:00" 형식)
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
      final m = setting.eveningForecastMinute.toString().padLeft(2, '0');
      return '오늘 저녁 $hh:$m';
    }
    return null;
  }

  /// 미리보기 알림 제목 — 실제 문구 스타일과 동일
  String _previewTitle() {
    final name = profile.displayName;
    return '😷 $name, 오늘 마스크를 챙기는 게 좋아요';
  }

  /// 미리보기 알림 본문 — T_final 기준 근거 표시
  String _previewBody() {
    final lines = [
      'PM2.5 ${tFinal.toStringAsFixed(0)}μg/m³ · 보통',
      '당신의 기준(${tFinal.toStringAsFixed(1)}μg/m³)을 넘었어요.',
      '마스크 착용을 권해드려요 😊',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final nextLabel = _nextAlertLabel();

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
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 행
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  '알림 미리보기',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                // 탭 힌트
                Row(
                  children: [
                    const Text(
                      '가중치 보기',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.primary),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right,
                        size: 14,
                        color: AppColors.primary.withAlpha(180)),
                  ],
                ),
              ],
            ),

            // 다음 알림 예정 시간
            if (nextLabel != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
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

            // 모의 알림 카드
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        Text(
                          _previewTitle(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _previewBody(),
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

// ── 가중치 설명 Bottom Sheet ──────────────────────────────
//
// S = min(w1 + w2 + w3, 0.6) 계산 과정을 사용자에게 투명하게 공개
// → "나만을 위한 세밀한 관리" 안도감 제공

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
    final w1 = SensitivityCalculator.conditionWeight(profile);
    final w2 = SensitivityCalculator.activityWeight(profile.activityLevel);
    final w3 = SensitivityCalculator.sensitivityWeight(profile.sensitivity);
    final rawSum = w1 + w2 + w3;
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

              // 제목
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
                '세 가지 항목을 더해 민감도 계수(S)를 산출합니다.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // 가중치 항목 3개
              _WeightRow(
                icon: Icons.favorite_outline,
                label: '기저질환',
                sublabel: profile.hasCondition
                    ? '${profile.conditionType.label} · ${profile.severity.label}'
                    : '해당 없음',
                value: w1,
                maxValue: 0.3,
              ),
              const SizedBox(height: 10),
              _WeightRow(
                icon: Icons.directions_walk,
                label: '야외 활동량',
                sublabel: profile.activityLevel.description,
                value: w2,
                maxValue: 0.2,
              ),
              const SizedBox(height: 10),
              _WeightRow(
                icon: Icons.tune,
                label: '주관적 민감도',
                sublabel: profile.sensitivity.label,
                value: w3,
                maxValue: 0.2,
              ),

              // 구분선
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.divider),
              ),

              // S 계산 결과
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary),
                            children: [
                              const TextSpan(text: 'S = '),
                              TextSpan(
                                text: 'min(${w1.toStringAsFixed(1)} + '
                                    '${w2.toStringAsFixed(1)} + '
                                    '${w3.toStringAsFixed(1)}, 0.6)',
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
                                  text: '  (상한 0.6 적용)',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary),
                            children: [
                              const TextSpan(text: '알림 기준 = 35 × (1 − '),
                              TextSpan(
                                text: s.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: AppColors.coral),
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
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 요약 문구
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(100),
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
}

// ── 가중치 행 위젯 ─────────────────────────────────────────

class _WeightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final double value;
  final double maxValue;

  const _WeightRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final fillRatio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final hasWeight = value > 0;

    return Row(
      children: [
        // 아이콘
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasWeight
                ? AppColors.coral.withAlpha(26)
                : AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18,
              color: hasWeight ? AppColors.coral : AppColors.textHint),
        ),
        const SizedBox(width: 12),
        // 라벨 + 바
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
                  // 배경 바
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // 채워진 바
                  FractionallySizedBox(
                    widthFactor: fillRatio,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasWeight ? AppColors.coral : AppColors.divider,
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
        // 값
        Text(
          '+${value.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: hasWeight ? AppColors.coral : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
