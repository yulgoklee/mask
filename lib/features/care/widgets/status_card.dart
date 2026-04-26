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
  RiskLevel.normal   => DT.primaryLt,
  RiskLevel.warning  => DT.cautionLt,
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

// ── 정보 바 오른쪽 부가정보 (§3.2 v3 삼분법) ─────────────

String _thresholdLabel(int dominantValue, double dominantTFinal) {
  final diff = dominantValue - dominantTFinal.round();
  if (diff < 0)  return '기준 이하';
  if (diff == 0) return '기준 도달';
  return '+${diff}µg 초과';
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

            // ── 정보 바 ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: data.dominantPollutant == DominantPollutant.pm10
                        ? 'PM10'
                        : 'PM2.5',
                    value:      data.dominantValue,
                    sub:        data.dominantGrade.label,
                    valueColor: _badgeText(data.status),
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label:      '내 기준',
                    value:      data.dominantTFinal.round(),
                    sub:        _thresholdLabel(data.dominantValue, data.dominantTFinal),
                    valueColor: DT.text,
                  ),
                ),
              ],
            ),
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

// ── 정보 컬럼 ────────────────────────────────────────────

class _InfoColumn extends StatelessWidget {
  final String label;
  final int    value;
  final String sub;
  final Color  valueColor;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.sub,
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
        AnimatedDigitWidget(
          value:    value,
          duration: const Duration(milliseconds: 600),
          curve:    Curves.easeOut,
          textStyle: TextStyle(
            fontFamily:    'monospace',
            fontSize:      28,
            fontWeight:    FontWeight.bold,
            color:         valueColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            color:    DT.gray,
            fontSize: 12,
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
                    '${data.nickname.isNotEmpty ? data.nickname : '사용자'}님의 기준치: ${data.tFinal.toInt()}µg/m³',
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
                        value: '${data.pm25Value.toInt()}µg/m³',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: '기준 대비',
                        value: '${data.overRatio.toStringAsFixed(1)}배',
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
