import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';

/// 온보딩 완료 후 개인 민감도 대시보드 (Step 3)
///
///  ① 헤더 — personaLabel 배지 + displayName + tFinal 수치
///  ② CustomPainter Area Chart — 5단계 위험도 구간 (ratio 기반)
///  ③ 민감도 기여 항목 카드 목록
///  ④ 알림 시뮬레이션 미리보기
///  ⑤ 위치 설정 → 버튼
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 32.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final s       = SensitivityCalculator.compute(profile);
    final tFinal  = profile.tFinal;

    return PopScope(
      canPop: false, // 온보딩 완료 후 뒤로가기로 onboarding 화면으로 돌아가지 않도록
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: Transform.translate(
              offset: Offset(0, _slide.value),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // ① 헤더
                    _DashboardHeader(profile: profile, s: s, tFinal: tFinal),

                    const SizedBox(height: 24),

                    // ② CustomPainter Area Chart
                    _RiskZoneChart(tFinal: tFinal),

                    const SizedBox(height: 20),

                    // ③ 민감도 기여 카드
                    _ContributionList(profile: profile, s: s),

                    const SizedBox(height: 20),

                    // ④ 알림 시뮬레이션 미리보기
                    _SimulationCard(
                      profile: profile,
                      tFinal: tFinal,
                      onDetailTap: () =>
                          _showWeightSheet(context, profile, s, tFinal),
                    ),

                    const SizedBox(height: 28),

                    // ⑤ CTA 버튼
                    AppButton.primary(
                      label: '위치 설정하고 시작하기 →',
                      onTap: () => context.go('/location_setup', extra: true),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
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
      builder: (_) => _WeightSheet(profile: profile, s: s, tFinal: tFinal),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ① 헤더 — personaLabel + displayName + tFinal
// ══════════════════════════════════════════════════════════════

class _DashboardHeader extends StatelessWidget {
  final UserProfile profile;
  final double s;
  final double tFinal;

  const _DashboardHeader({
    required this.profile,
    required this.s,
    required this.tFinal,
  });

  @override
  Widget build(BuildContext context) {
    final persona = profile.personaLabel;
    // s=0.10 클램프 최솟값에서는 "1.1배" 표시가 어색 — 의미 있는 수준(s>0.15)부터만 표시
    final multiplier = (1.0 - s) > 0 ? (1.0 / (1.0 - s)) : double.infinity;
    final multiplierText =
        multiplier.isInfinite ? '∞배' : '${multiplier.toStringAsFixed(1)}배';
    // 실질적으로 민감도가 올라간 경우만 배율 문구 표시
    final showMultiplier = s > 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 퍼소나 배지
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
                  color: AppColors.coral, size: 16),
              const SizedBox(width: 6),
              Text(
                persona,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 이름
        Text(
          '${profile.displayName},',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        if (showMultiplier)
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 21, color: AppColors.textPrimary),
              children: [
                const TextSpan(text: '일반인보다 '),
                TextSpan(
                  text: multiplierText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const TextSpan(text: ' 더 민감하게\n관리해드릴게요'),
              ],
            ),
          )
        else
          const Text(
            '맞춤형 알림 기준으로\n관리해드릴게요',
            style: TextStyle(
              fontSize: 21,
              color: AppColors.textPrimary,
            ),
          ),
        const SizedBox(height: 14),

        // tFinal 수치 강조 카드
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.primaryLight.withValues(alpha: 0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '나에게 맞는 알림 기준',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: tFinal.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text: ' μg/m³',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '일반 기준',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '35.0 μg/m³',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '민감도 ${SensitivityCalculator.label(s)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ② CustomPainter — 5단계 위험도 구간 Area Chart
//
//  X축: PM2.5 농도 (0 ~ ceil(2.5 * tFinal / 10) * 10)
//  구간 경계: 0.5·T / T / 1.5·T / 2·T / 이후
//  색상: low(초록) / normal(노랑) / warning(주황) / danger(빨강) / critical(보라)
//  표시선: ① 내 기준 (coral 수직선)  ② 일반 기준 35 (gray 수직선, tFinal≠35 시)
// ══════════════════════════════════════════════════════════════

class _RiskZoneChart extends StatelessWidget {
  final double tFinal;

  const _RiskZoneChart({required this.tFinal});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 헤더
          Row(
            children: [
              const Text(
                '위험도 구간 차트',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'PM2.5 μg/m³',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '내 기준 ${tFinal.toStringAsFixed(1)}μg/m³에서 다섯 단계로 나뉘어요',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // CustomPainter 차트
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _RiskZonePainter(tFinal: tFinal),
            ),
          ),

          const SizedBox(height: 16),

          // 범례
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: const [
              _LegendChip(color: Color(0xFF10B981), label: '낮음'),
              _LegendChip(color: Color(0xFF84CC16), label: '보통'),
              _LegendChip(color: Color(0xFFF59E0B), label: '주의'),
              _LegendChip(color: Color(0xFFEF4444), label: '위험'),
              _LegendChip(color: Color(0xFF7C3AED), label: '매우위험'),
              _LegendChip(color: AppColors.coral, label: '내 기준', isDash: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDash;

  const _LegendChip({
    required this.color,
    required this.label,
    this.isDash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDash
            ? SizedBox(
                width: 16,
                child: CustomPaint(
                  size: const Size(16, 2),
                  painter: _DashPainter(color: color),
                ),
              )
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashLen = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(math.min(x + dashLen, size.width), size.height / 2),
          paint);
      x += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// CustomPainter: 5구간 배경 + 곡선 + 수직선
class _RiskZonePainter extends CustomPainter {
  final double tFinal;

  const _RiskZonePainter({required this.tFinal});

  // 구간 경계 (ratio 기준, 실제 μg/m³ = ratio * tFinal)
  static const _ratios = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5];
  static const _zoneColors = [
    Color(0xFF10B981), // low
    Color(0xFF84CC16), // normal
    Color(0xFFF59E0B), // warning
    Color(0xFFEF4444), // danger
    Color(0xFF7C3AED), // critical
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final maxPm = tFinal * 2.5;

    // 구간을 x좌표로 변환
    double pmToX(double pm) => (pm / maxPm).clamp(0.0, 1.0) * size.width;

    // 높이 파라미터 (물결 곡선용)
    // 구간별 높이: ratio 0.5 까지는 낮고, ratio 1.0 근처에서 높아짐
    double ratioToH(double ratio) {
      // 0→0.15h, 0.5→0.35h, 1.0→0.75h, 1.5→0.90h, 2.0→0.85h, 2.5→0.70h
      const heights = [0.15, 0.35, 0.75, 0.90, 0.85, 0.70];
      if (ratio <= 0) return heights[0] * size.height;
      if (ratio >= 2.5) return heights[5] * size.height;
      for (int i = 0; i < _ratios.length - 1; i++) {
        if (ratio <= _ratios[i + 1]) {
          final t = (ratio - _ratios[i]) / (_ratios[i + 1] - _ratios[i]);
          return (heights[i] + (heights[i + 1] - heights[i]) * t) * size.height;
        }
      }
      return heights[5] * size.height;
    }

    // ── 구간별 채색 (배경 밴드) ──────────────────────────────
    for (int i = 0; i < _zoneColors.length; i++) {
      final x0 = pmToX(_ratios[i] * tFinal);
      final x1 = pmToX(_ratios[i + 1] * tFinal);
      final rect = Rect.fromLTWH(x0, 0, x1 - x0, size.height * 0.80);

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _zoneColors[i].withValues(alpha: 0.15),
          _zoneColors[i].withValues(alpha: 0.06),
        ],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }

    // ── 곡선 (물결 Area) ─────────────────────────────────────
    final curvePoints = _ratios
        .map((r) => Offset(pmToX(r * tFinal), size.height * 0.80 - ratioToH(r)))
        .toList();

    // 베지어 곡선 경로
    final path = Path()..moveTo(curvePoints[0].dx, size.height * 0.80);
    path.lineTo(curvePoints[0].dx, curvePoints[0].dy);

    for (int i = 0; i < curvePoints.length - 1; i++) {
      final cp1x = (curvePoints[i].dx + curvePoints[i + 1].dx) / 2;
      path.cubicTo(
        cp1x, curvePoints[i].dy,
        cp1x, curvePoints[i + 1].dy,
        curvePoints[i + 1].dx, curvePoints[i + 1].dy,
      );
    }

    path.lineTo(curvePoints.last.dx, size.height * 0.80);
    path.close();

    // 곡선 채우기 (그라디언트)
    final areaRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.80);
    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x3542A5F5),
          Color(0x0042A5F5),
        ],
      ).createShader(areaRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, areaPaint);

    // 곡선 테두리
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.60)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    // 테두리만 그리기 위해 bottom 라인 없는 경로 재생성
    final linePath = Path()..moveTo(curvePoints[0].dx, curvePoints[0].dy);
    for (int i = 0; i < curvePoints.length - 1; i++) {
      final cp1x = (curvePoints[i].dx + curvePoints[i + 1].dx) / 2;
      linePath.cubicTo(
        cp1x, curvePoints[i].dy,
        cp1x, curvePoints[i + 1].dy,
        curvePoints[i + 1].dx, curvePoints[i + 1].dy,
      );
    }
    canvas.drawPath(linePath, linePaint);

    // ── X축 ─────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.80),
      Offset(size.width, size.height * 0.80),
      axisPaint,
    );

    // X축 레이블
    final labelStyle = const TextStyle(
      fontSize: 10,
      color: AppColors.textSecondary,
    );
    void drawXLabel(String text, double x) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((x - tp.width / 2).clamp(0, size.width - tp.width),
            size.height * 0.82),
      );
    }

    drawXLabel('0', 0);
    drawXLabel('${(0.5 * tFinal).round()}', pmToX(0.5 * tFinal));
    drawXLabel('${tFinal.round()}', pmToX(tFinal));
    drawXLabel('${(1.5 * tFinal).round()}', pmToX(1.5 * tFinal));
    drawXLabel('${(2.0 * tFinal).round()}', pmToX(2.0 * tFinal));

    // ── 일반 기준선 (35 μg/m³) — tFinal과 다를 때만 ────────
    const tStandard = 35.0;
    if ((tFinal - tStandard).abs() > 1.0) {
      final stdX = pmToX(tStandard);
      final stdPaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.60)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      _drawDashedLine(canvas, Offset(stdX, 0),
          Offset(stdX, size.height * 0.78), stdPaint);
    }

    // ── 내 기준선 (tFinal) ────────────────────────────────
    final myX = pmToX(tFinal);
    final myPaint = Paint()
      ..color = AppColors.coral
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset(myX, 0),
        Offset(myX, size.height * 0.78), myPaint);

    // 내 기준 삼각형 마커
    final markerPath = Path()
      ..moveTo(myX - 6, 0)
      ..lineTo(myX + 6, 0)
      ..lineTo(myX, 8)
      ..close();
    canvas.drawPath(
      markerPath,
      Paint()
        ..color = AppColors.coral
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 5.0;
    const gapLen = 4.0;
    final totalLen = (p2 - p1).distance;
    final dir = (p2 - p1) / totalLen;
    double traveled = 0;
    while (traveled < totalLen) {
      final start = p1 + dir * traveled;
      final end = p1 + dir * math.min(traveled + dashLen, totalLen);
      canvas.drawLine(start, end, paint);
      traveled += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_RiskZonePainter old) => old.tFinal != tFinal;
}

// ══════════════════════════════════════════════════════════════
//  ③ 민감도 기여 항목 카드
// ══════════════════════════════════════════════════════════════

class _ContributionList extends StatelessWidget {
  final UserProfile profile;
  final double s;

  const _ContributionList({required this.profile, required this.s});

  @override
  Widget build(BuildContext context) {
    final w1    = SensitivityCalculator.conditionWeight(profile);
    final w2    = SensitivityCalculator.activityWeight(profile);
    final w3    = SensitivityCalculator.sensitivityWeightFromProfile(profile);
    final wSpec = SensitivityCalculator.specialStateWeight(profile);
    final wPref = SensitivityCalculator.prefWeight(profile);

    final items = [
      _ContribItem(
        icon: Icons.favorite_outline,
        label: '호흡기 상태',
        value: w1,
        maxValue: 0.45, // 비염(+15%) + 천식(+30%) 중복 최대
        isPositive: true,
        detail: profile.respiratoryLabel,
      ),
      _ContribItem(
        icon: Icons.person_outline,
        label: '연령',
        value: profile.isVulnerableAge ? 0.10 : 0.0,
        maxValue: 0.10,
        isPositive: true,
        detail: profile.isVulnerableAge
            ? '취약 연령 (${profile.age}세)'
            : '일반 연령 (${profile.age}세)',
      ),
      _ContribItem(
        icon: Icons.tune,
        label: '체감 민감도',
        value: w3,
        maxValue: 0.10, // sensitivityWeightFromProfile 최대값 (level 2 = +0.10)
        isPositive: true,
        detail: profile.sensitivityLevel == 2
            ? '매우 예민'
            : profile.sensitivityLevel == 1
                ? '보통'
                : '무던함',
      ),
      _ContribItem(
        icon: Icons.directions_walk,
        label: '야외 활동량',
        value: w2,
        maxValue: 0.20, // Q8(0.10) + Q9 태그(0.10) 최대
        isPositive: true,
        detail: _activityDetail(profile),
      ),
      _ContribItem(
        icon: Icons.health_and_safety_outlined,
        label: '특별 상태',
        value: wSpec,
        maxValue: 0.55,
        isPositive: true,
        detail: _specDetail(profile),
      ),
      _ContribItem(
        icon: Icons.masks_outlined,
        label: '마스크 불편도',
        value: wPref.abs(),
        maxValue: 0.10,
        isPositive: false,
        detail: profile.discomfortLevel == 2
            ? '많이 불편 (기준 완화)'
            : '착용 문제없음',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '민감도 기여 항목',
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
                  '종합 ${(s * 100).round()}% 강화',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContribRow(item: item),
              )),
        ],
      ),
    );
  }

  String _specDetail(UserProfile p) {
    final parts = <String>[];
    if (p.isPregnant) parts.add('임신');
    if (p.isSkinTreatmentActive) parts.add('피부 시술');
    return parts.isEmpty ? '해당 없음' : parts.join(' · ');
  }

  String _activityDetail(UserProfile p) {
    final base = p.outdoorMinutes == 2
        ? '하루 3시간 이상'
        : p.outdoorMinutes == 1
            ? '하루 1~3시간'
            : '하루 1시간 미만';
    if (p.activityTags.isEmpty) return base;
    return '$base · 태그 ${p.activityTags.length}개';
  }
}

class _ContribItem {
  final IconData icon;
  final String label;
  final double value;
  final double maxValue;
  final bool isPositive;
  final String detail;

  const _ContribItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.isPositive,
    required this.detail,
  });
}

class _ContribRow extends StatelessWidget {
  final _ContribItem item;
  const _ContribRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasWeight = item.value > 0;
    final barColor = item.isPositive
        ? (hasWeight ? AppColors.coral : AppColors.divider)
        : (hasWeight ? AppColors.primary : AppColors.divider);
    final iconColor = item.isPositive
        ? (hasWeight ? AppColors.coral : AppColors.textHint)
        : (hasWeight ? AppColors.primary : AppColors.textHint);
    final bgColor = item.isPositive
        ? (hasWeight
            ? AppColors.coral.withValues(alpha: 0.10)
            : AppColors.surfaceVariant)
        : (hasWeight
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surfaceVariant);

    final fillRatio = item.maxValue > 0
        ? (item.value / item.maxValue).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(item.icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.detail,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LayoutBuilder(
                builder: (_, constraints) => Stack(
                  children: [
                    Container(
                      height: 5,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      height: 5,
                      width: constraints.maxWidth * fillRatio,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          hasWeight
              ? (item.isPositive
                  ? '+${(item.value * 100).round()}%'
                  : '−${(item.value * 100).round()}%')
              : '+0%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: hasWeight ? barColor : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ④ 알림 시뮬레이션 카드
// ══════════════════════════════════════════════════════════════

class _SimulationCard extends StatelessWidget {
  final UserProfile profile;
  final double tFinal;
  final VoidCallback onDetailTap;

  const _SimulationCard({
    required this.profile,
    required this.tFinal,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName;

    return GestureDetector(
      onTap: onDetailTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  '이런 알림이 울려요',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Text(
                  '기준이 궁금해요',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.primary),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 14, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
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
                      color:
                          AppColors.coral.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.masks_outlined,
                        size: 17, color: AppColors.coral),
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
                          '미세먼지가 내 기준(${tFinal.toStringAsFixed(1)}μg/m³)에\n'
                          '도달할 것으로 예상돼요.',
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
              '* 실제 알림은 측정소 데이터 기반으로 발송됩니다.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  가중치 상세 Bottom Sheet
// ══════════════════════════════════════════════════════════════

class _WeightSheet extends StatelessWidget {
  final UserProfile profile;
  final double s;
  final double tFinal;

  const _WeightSheet({
    required this.profile,
    required this.s,
    required this.tFinal,
  });

  @override
  Widget build(BuildContext context) {
    final w1    = SensitivityCalculator.conditionWeight(profile);
    final w2    = SensitivityCalculator.activityWeight(profile);
    final w3    = SensitivityCalculator.sensitivityWeightFromProfile(profile);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
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
                '건강 상태·활동량·민감도를 합산해 일반 기준 35μg/m³에서\n'
                '개인 기준을 낮춰드려요. 항목이 많을수록 더 일찍 알려드려요.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),

              _SheetWeightRow(
                icon: Icons.favorite_outline,
                label: '호흡기 상태',
                sublabel: profile.respiratoryLabel == '건강함'
                    ? '해당 없음'
                    : profile.respiratoryLabel,
                value: w1,
                maxValue: 0.45,
                isPositive: true,
              ),
              const SizedBox(height: 10),
              _SheetWeightRow(
                icon: Icons.directions_walk,
                label: '야외 활동량',
                sublabel: () {
                  final base = profile.outdoorMinutes == 2
                      ? '3시간 이상'
                      : profile.outdoorMinutes == 1
                          ? '1~3시간'
                          : '1시간 미만';
                  return profile.activityTags.isEmpty
                      ? base
                      : '$base · 태그 ${profile.activityTags.length}개';
                }(),
                value: w2,
                maxValue: 0.20,
                isPositive: true,
              ),
              const SizedBox(height: 10),
              _SheetWeightRow(
                icon: Icons.tune,
                label: '신체 반응도',
                sublabel: profile.sensitivityLevel == 2
                    ? '매우 예민'
                    : profile.sensitivityLevel == 1
                        ? '보통'
                        : '무던함',
                value: w3,
                maxValue: 0.10,
                isPositive: true,
              ),
              const SizedBox(height: 10),
              _SheetWeightRow(
                icon: Icons.health_and_safety_outlined,
                label: '특별 상태',
                sublabel: _specLabel(profile),
                value: wSpec,
                maxValue: 0.55,
                isPositive: true,
              ),
              const SizedBox(height: 10),
              _SheetWeightRow(
                icon: Icons.masks_outlined,
                label: '마스크 편의',
                sublabel: profile.discomfortLevel == 2
                    ? '많이 불편 (기준 완화)'
                    : '착용 문제없음',
                value: wPref.abs(),
                maxValue: 0.10,
                isPositive: false,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.divider),
              ),

              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  children: [
                    const TextSpan(text: '항목 합계 '),
                    TextSpan(
                      text: '+${(w1 * 100).round()}% + '
                          '+${(w2 * 100).round()}% + '
                          '+${(w3 * 100).round()}% + '
                          '+${(wSpec * 100).round()}%'
                          '${wPref < 0 ? ' − ${(wPref.abs() * 100).round()}%' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const TextSpan(text: ' = '),
                    TextSpan(
                      text: '${(s * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.coral,
                      ),
                    ),
                    if (isClamped)
                      const TextSpan(
                        text: '  (최대 60% 적용)',
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
                    const TextSpan(text: '35μg/m³ × (1 − '),
                    TextSpan(
                      text: '${(s * 100).round()}%',
                      style: const TextStyle(color: AppColors.coral),
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
                  '일반 기준(35μg/m³)보다 먼저 알림을 드려요.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _specLabel(UserProfile p) {
    final parts = <String>[];
    if (p.isPregnant) parts.add('임신');
    if (p.recentSkinTreatment) parts.add('피부 시술');
    return parts.isEmpty ? '해당 없음' : parts.join(' · ');
  }
}

class _SheetWeightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final double value;
  final double maxValue;
  final bool isPositive;

  const _SheetWeightRow({
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
          decoration:
              BoxDecoration(color: bgColor, shape: BoxShape.circle),
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
                      color: AppColors.textPrimary,
                    ),
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
              LayoutBuilder(
                builder: (_, c) => Stack(
                  children: [
                    Container(
                      height: 5,
                      width: c.maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      height: 5,
                      width: c.maxWidth * fillRatio,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          hasWeight
              ? (isPositive
                  ? '+${(value * 100).round()}%'
                  : '−${(value * 100).round()}%')
              : '+0%',
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
