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
  RiskLevel.warning  => const Color(0xFFFED7AA),
  RiskLevel.danger   => DT.dangerLt,
  RiskLevel.critical => DT.dangerLt,
  RiskLevel.unknown  => DT.grayLt,
};

// critical에만 1px DT.danger 보더 (danger와 시각 차별화)
BoxBorder? _border(RiskLevel s) =>
    s == RiskLevel.critical
        ? Border.all(color: DT.danger, width: 1)
        : null;

Color _badgeBg(RiskLevel s) => switch (s) {
  RiskLevel.low      => DT.safe.withValues(alpha: 0.15),
  RiskLevel.normal   => DT.primary.withValues(alpha: 0.15),
  RiskLevel.warning  => DT.caution.withValues(alpha: 0.15),
  RiskLevel.danger   => DT.danger.withValues(alpha: 0.12),
  RiskLevel.critical => DT.danger.withValues(alpha: 0.18),
  RiskLevel.unknown  => DT.gray.withValues(alpha: 0.12),
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
            // ── 상단: 배지 + (이모지 + 제목) ──────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 8),
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
                  ],
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
              color:     _badgeText(data.status).withValues(alpha: 0.08),
            ),
            const SizedBox(height: 20),

            // ── 오염물질 수치 (PM2.5 + PM10) ────────────
            Row(
              children: [
                Expanded(
                  child: _PollutantRow(
                    label: '초미세먼지',
                    value: data.pm25Value.round(),
                  ),
                ),
                Expanded(
                  child: _PollutantRow(
                    label: '미세먼지',
                    value: data.pm10Value?.round(),
                  ),
                ),
              ],
            ),

            // ── 오염물질 카피 (PM2.5 + PM10) ─────────
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final ratioPm25 = data.tFinal > 0
                  ? data.pm25Value / data.tFinal
                  : 0.0;
              final tFinalPm10 = data.tFinal * (80.0 / 35.0);
              final ratioPm10 = data.pm10Value != null && tFinalPm10 > 0
                  ? data.pm10Value! / tFinalPm10
                  : null;
              return Row(
                children: [
                  Expanded(child: _PollutantCopy(ratio: ratioPm25)),
                  Expanded(
                    child: ratioPm10 != null
                        ? _PollutantCopy(ratio: ratioPm10)
                        : const SizedBox.shrink(),
                  ),
                ],
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
  final String label;
  final int?   value;

  const _PollutantRow({
    required this.label,
    required this.value,
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
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedDigitWidget(
                    value:    value!,
                    duration: const Duration(milliseconds: 600),
                    curve:    Curves.easeOut,
                    textStyle: const TextStyle(
                      fontFamily:    'monospace',
                      fontSize:      28,
                      fontWeight:    FontWeight.bold,
                      color:         DT.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'µg/m³',
                      style: TextStyle(fontSize: 11, color: DT.gray),
                    ),
                  ),
                ],
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
      ],
    );
  }
}

// ── 오염물질 카피 행 ─────────────────────────────────────

class _PollutantCopy extends StatelessWidget {
  final double ratio;
  const _PollutantCopy({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(pollutantEmoji(ratio), style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            pollutantCopy(ratio),
            style: const TextStyle(fontSize: 13, color: DT.text),
          ),
        ),
      ],
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
                        label: '초미세먼지',
                        value: '${data.tFinal.toInt()}µg/m³',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: '미세먼지',
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
