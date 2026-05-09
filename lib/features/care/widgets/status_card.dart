import 'package:animated_digit/animated_digit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
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

// ── 카드 배경색 (finalRatio 기반 3단계) ──────────────────

Color _bgColor(double ratio) {
  if (ratio < 1.0) return DT.safeLt;
  if (ratio < 1.5) return const Color(0xFFFED7AA); // warning orange
  return DT.dangerLt;
}

BoxBorder? _border(double ratio) =>
    ratio >= 1.5 ? Border.all(color: DT.danger, width: 1) : null;

// ── 카드 위젯 ────────────────────────────────────────────

class _StatusCardContent extends StatelessWidget {
  final StatusCardData data;
  const _StatusCardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final ratio = data.finalRatio;

    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color:        _bgColor(ratio),
          borderRadius: BorderRadius.circular(16),
          border:       _border(ratio),
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
            // ── 닉네임 ────────────────────────────────────
            if (data.nickname.isNotEmpty) ...[
              Text(
                '${data.nickname}님,',
                style: const TextStyle(
                  color:      DT.gray,
                  fontSize:   14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── 큰 아이콘 (3단계) ─────────────────────────
            Text(
              data.emoji,
              style: const TextStyle(fontSize: 64),
            ).animate(key: ValueKey(ratio ~/ 1))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.elasticOut,
                  duration: 300.ms,
                )
                .rotate(begin: -0.05, end: 0, duration: 300.ms),

            const SizedBox(height: 12),

            // ── 답 텍스트 ─────────────────────────────────
            Text(
              data.title,
              style: const TextStyle(
                color:      DT.text,
                fontSize:   26,
                fontWeight: FontWeight.w700,
                height:     1.2,
              ),
            ),

            // ── 서브 카피 ─────────────────────────────────
            if (data.subCopy.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.subCopy,
                style: const TextStyle(
                  color:    DT.gray,
                  fontSize: 14,
                  height:   1.5,
                ),
              ),
            ],

            // ── 수치 행 (데이터 있을 때) ───────────────────
            if (data.status.index > 0) ...[
              const SizedBox(height: 20),
              Divider(
                height:    1,
                thickness: 1,
                color:     DT.gray.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 16),
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
            ],
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
