import 'package:animated_digit/animated_digit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/utils/dust_calculator.dart';
import '../../../providers/dust_providers.dart';
import '../providers/care_providers.dart';
import '../models/care_models.dart';

class StatusCard extends ConsumerWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data      = ref.watch(statusCardProvider);
    final dustAsync = ref.watch(dustDataProvider);
    final isLoading = dustAsync.isLoading;

    final card = _StatusCardContent(data: data)
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.08, end: 0, duration: 300.ms)
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1), duration: 300.ms);

    if (!isLoading) return card;
    return card.animate().shimmer(duration: 1200.ms, color: const Color(0xFFF9FAFB));
  }
}

// ── 색상 매핑 (§3.2 v3) ──────────────────────────────────

Color _bgColor(RiskLevel s) => switch (s) {
  RiskLevel.low      => DT.safeLt,
  RiskLevel.normal   => DT.cautionBg,
  RiskLevel.warning  => const Color(0xFFFFF0E6),
  RiskLevel.danger   => DT.dangerLt,
  RiskLevel.critical => const Color(0xFFFFCDD2),
  RiskLevel.unknown  => DT.grayLt,
};

// critical에만 1px DT.danger 보더 (danger와 시각 차별화)
BoxBorder? _border(RiskLevel s) =>
    s == RiskLevel.critical
        ? Border.all(color: DT.danger, width: 1)
        : null;

Color _badgeBg(RiskLevel s) => switch (s) {
  RiskLevel.low      => DT.safe.withOpacity(0.15),
  RiskLevel.normal   => DT.primary.withOpacity(0.15),
  RiskLevel.warning  => DT.caution.withOpacity(0.15),
  RiskLevel.danger   => DT.danger.withOpacity(0.12),
  RiskLevel.critical => DT.danger.withOpacity(0.18),
  RiskLevel.unknown  => DT.gray.withOpacity(0.12),
};

Color _badgeText(RiskLevel s) => switch (s) {
  RiskLevel.low      => DT.safe,
  RiskLevel.normal   => DT.primary,
  RiskLevel.warning  => DT.caution,
  RiskLevel.danger   => DT.danger,
  RiskLevel.critical => DT.danger,
  RiskLevel.unknown  => DT.gray,
};

String _badgeLabel(RiskLevel s) => switch (s) {
  RiskLevel.low      => '안전',
  RiskLevel.normal   => '보통',
  RiskLevel.warning  => '주의',
  RiskLevel.danger   => '나쁨',
  RiskLevel.critical => '심각',
  RiskLevel.unknown  => '-',
};

// ── X% 메시지 (주의 이상) ────────────────────────────────

String? _ratioMessage(RiskLevel status, double finalRatio) {
  switch (status) {
    case RiskLevel.warning:
      return '내 기준의 ${(finalRatio * 100).round()}%까지 왔어요';
    case RiskLevel.danger:
      final excess = ((finalRatio - 1.0) * 100).round();
      return '내 기준을 $excess% 넘었어요';
    case RiskLevel.critical:
      return '내 기준의 ${finalRatio.toStringAsFixed(1)}배예요';
    default:
      return null;
  }
}

// ── 카드 위젯 ────────────────────────────────────────────

class _StatusCardContent extends StatelessWidget {
  final StatusCardData data;
  const _StatusCardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color:        _bgColor(data.status),
          borderRadius: BorderRadius.circular(16),
          border:       _border(data.status),
          boxShadow: const [
            BoxShadow(
              offset:     Offset(0, 2),
              blurRadius: 12,
              color:      Color(0x0A000000),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 상단 행: 이모지 + 제목 + 배지 ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 48),
                ).animate(key: ValueKey(data.status))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.elasticOut,
                      duration: 200.ms,
                    )
                    .rotate(begin: -0.05, end: 0, duration: 200.ms),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      color:      DT.text,
                      fontSize:   24,
                      fontWeight: FontWeight.w600,
                      height:     1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color:        _badgeBg(data.status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _badgeLabel(data.status),
                    style: TextStyle(
                      color:         _badgeText(data.status),
                      fontSize:      11,
                      fontWeight:    FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            // ── 서브 카피 ────────────────────────────────
            if (data.subCopy.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                data.subCopy,
                style: const TextStyle(
                  color:    DT.gray,
                  fontSize: 15,
                  height:   1.6,
                ),
              ),
            ],

            // ── 구분선 ───────────────────────────────────
            const SizedBox(height: 20),
            Divider(
              height:    1,
              thickness: 1,
              color:     _badgeText(data.status).withOpacity(0.08),
            ),
            const SizedBox(height: 20),

            // ── 오염물질 수치 (PM2.5 + PM10) ────────────
            Row(
              children: [
                Expanded(
                  child: _PollutantRow(
                    label:      'PM2.5',
                    value:      data.pm25Value.round(),
                    grade:      data.dominantPollutant == DominantPollutant.pm25
                        ? data.dominantGrade.label
                        : null,
                    valueColor: data.dominantPollutant == DominantPollutant.pm25
                        ? _badgeText(data.status)
                        : DT.text,
                  ),
                ),
                Expanded(
                  child: _PollutantRow(
                    label:      'PM10',
                    value:      data.pm10Value?.round(),
                    grade:      data.dominantPollutant == DominantPollutant.pm10
                        ? data.dominantGrade.label
                        : null,
                    valueColor: data.dominantPollutant == DominantPollutant.pm10
                        ? _badgeText(data.status)
                        : DT.text,
                  ),
                ),
              ],
            ),

            // ── 게이지 바 (PM2.5 + PM10) ─────────────
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final isDominantPm25 =
                  data.dominantPollutant == DominantPollutant.pm25;
              final accentColor = _badgeText(data.status);

              final pm25Fg = isDominantPm25 ? accentColor : DT.gray;
              final pm10Fg = !isDominantPm25 ? accentColor : DT.gray;

              final ratioPm25 = data.tFinal > 0
                  ? data.pm25Value / data.tFinal
                  : 0.0;
              final tFinalPm10 = data.tFinal * (80.0 / 35.0);
              final ratioPm10 = data.pm10Value != null && tFinalPm10 > 0
                  ? data.pm10Value! / tFinalPm10
                  : null;

              return Column(
                children: [
                  _GaugeRow(
                    label:      'PM2.5',
                    valueMicro: '${data.pm25Value.round()}µg',
                    ratio:      ratioPm25,
                    foreground: pm25Fg,
                    background: pm25Fg.withValues(alpha: 0.12),
                  ),
                  if (ratioPm10 != null) ...[
                    const SizedBox(height: 8),
                    _GaugeRow(
                      label:      'PM10',
                      valueMicro: '${data.pm10Value!.round()}µg',
                      ratio:      ratioPm10,
                      foreground: pm10Fg,
                      background: pm10Fg.withValues(alpha: 0.12),
                    ),
                  ],
                ],
              );
            }),

            // ── X% 메시지 (주의 이상) ──────────────────
            Builder(builder: (context) {
              final msg = _ratioMessage(data.status, data.finalRatio);
              if (msg == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  msg,
                  style: TextStyle(
                    color:      _badgeText(data.status),
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _StatusBottomSheet(data: data),
    );
  }
}

// ── 오염물질 행 ──────────────────────────────────────────

class _PollutantRow extends StatelessWidget {
  final String  label;
  final int?    value;
  final String? grade;
  final Color   valueColor;

  const _PollutantRow({
    required this.label,
    required this.value,
    required this.grade,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color:      DT.gray,
            fontSize:   11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        value != null
            ? AnimatedDigitWidget(
                value:    value!,
                duration: const Duration(milliseconds: 600),
                curve:    Curves.easeOut,
                textStyle: TextStyle(
                  fontFamily:    'monospace',
                  fontSize:      28,
                  fontWeight:    FontWeight.bold,
                  color:         valueColor,
                  letterSpacing: -0.5,
                ),
              )
            : const Text(
                '—',
                style: TextStyle(
                  fontFamily:    'monospace',
                  fontSize:      28,
                  fontWeight:    FontWeight.bold,
                  color:         DT.gray,
                  letterSpacing: -0.5,
                ),
              ),
        const SizedBox(height: 2),
        Text(
          grade ?? '',
          style: const TextStyle(
            color:    DT.gray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── 게이지 행 ────────────────────────────────────────────

class _GaugeRow extends StatelessWidget {
  final String label;
  final String valueMicro;
  final double ratio;
  final Color  foreground;
  final Color  background;

  const _GaugeRow({
    required this.label,
    required this.valueMicro,
    required this.ratio,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio.clamp(0.0, 1.0) * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              color:      foreground,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            valueMicro,
            style: TextStyle(color: foreground, fontSize: 11),
          ),
        ),
        Expanded(
          child: _LinearGaugeBar(
            ratio:      ratio,
            foreground: foreground,
            background: background,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$pct%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color:      foreground,
              fontSize:   11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 선형 게이지 바 ──────────────────────────────────────

class _LinearGaugeBar extends StatelessWidget {
  final double ratio;
  final Color  foreground;
  final Color  background;

  const _LinearGaugeBar({
    required this.ratio,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value:           ratio.clamp(0.0, 1.0),
        color:           foreground,
        backgroundColor: background,
        minHeight:       8,
      ),
    );
  }
}

// ── 바텀시트 ────────────────────────────────────────────

class _StatusBottomSheet extends StatelessWidget {
  final StatusCardData data;
  const _StatusBottomSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize:     0.75,
      minChildSize:     0.35,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color:        DT.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width:  40,
              height: 4,
              decoration: BoxDecoration(
                color:        const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    data.nickname.isNotEmpty ? '${data.nickname}님의 기준치' : '내 기준치',
                    style: const TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                      color:      DT.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _StatChip(
                        label: 'PM2.5',
                        value: '${data.tFinal.toInt()}µg/m³',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'PM10',
                        value: '${(data.tFinal * 80.0 / 35.0).round()}µg/m³',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/my-body-info');
                      },
                      child: const Text('프로필 수정하기 →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 수치 칩 ─────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        DT.grayLt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: DT.gray),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.bold,
                color:      DT.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
