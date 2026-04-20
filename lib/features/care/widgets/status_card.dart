import 'package:animated_digit/animated_digit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/dust_providers.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';

class StatusCard extends ConsumerWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(statusCardProvider);
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

class _StatusCardContent extends StatelessWidget {
  final StatusCardData data;
  const _StatusCardContent({required this.data});

  Color get _bgColor => switch (data.status) {
    CardStatus.safe    => DT.safeBg,
    CardStatus.caution => DT.cautionBg,
    CardStatus.danger  => DT.dangerBg,
  };

  Color get _badgeBg => switch (data.status) {
    CardStatus.safe    => DT.safeLt,
    CardStatus.caution => DT.cautionLt,
    CardStatus.danger  => DT.dangerLt,
  };

  Color get _badgeText => switch (data.status) {
    CardStatus.safe    => DT.safe,
    CardStatus.caution => DT.caution,
    CardStatus.danger  => DT.danger,
  };

  String get _badgeLabel => switch (data.status) {
    CardStatus.safe    => '안전',
    CardStatus.caution => '주의',
    CardStatus.danger  => '위험',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 48),
                ).animate(key: ValueKey(data.status))
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 200.ms)
                    .rotate(begin: -0.1, end: 0, duration: 200.ms),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _badgeLabel,
                    style: TextStyle(
                      color: _badgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              style: const TextStyle(
                color: DT.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (data.personalizedText.isNotEmpty)
              Text(
                data.personalizedText,
                style: const TextStyle(color: DT.gray, fontSize: 14, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                AnimatedDigitWidget(
                  value: data.pm25Value.toInt(),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  textStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _badgeText,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('µg/m³', style: TextStyle(color: DT.gray, fontSize: 10)),
              ],
            ),
            if (data.actionGuide.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.actionGuide,
                style: TextStyle(
                  color: _badgeText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusBottomSheet(data: data),
    );
  }
}

class _StatusBottomSheet extends StatelessWidget {
  final StatusCardData data;
  const _StatusBottomSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: DT.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DT.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '가중치 기여도',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DT.text),
                  ),
                  const SizedBox(height: 12),
                  _WeightBar(label: '호흡기 상태', value: _respWeight(data.respiratoryStatus), color: DT.danger),
                  const SizedBox(height: 8),
                  _WeightBar(label: '민감도', value: data.sensitivityMultiplier / 10, color: DT.caution),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _StatChip(label: '현재 PM2.5', value: '${data.pm25Value.toInt()}µg/m³'),
                      const SizedBox(width: 12),
                      _StatChip(label: '기준치 대비', value: '${data.overRatio.toStringAsFixed(1)}배'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/profile/edit');
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

  double _respWeight(int status) {
    if (status == 3) return 0.45;
    if (status == 2) return 0.25;
    if (status == 1) return 0.20;
    return 0.0;
  }
}

class _WeightBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _WeightBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: DT.gray)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 13, color: DT.gray)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: DT.grayLt,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

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
          color: DT.grayLt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: DT.gray)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DT.text)),
          ],
        ),
      ),
    );
  }
}
