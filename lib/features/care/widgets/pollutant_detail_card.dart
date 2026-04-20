import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/dust_providers.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';

class PollutantDetailCard extends ConsumerStatefulWidget {
  const PollutantDetailCard({super.key});

  @override
  ConsumerState<PollutantDetailCard> createState() => _PollutantDetailCardState();
}

class _PollutantDetailCardState extends ConsumerState<PollutantDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(pollutantCardProvider);
    final dustAsync = ref.watch(dustDataProvider);
    final isLoading = dustAsync.isLoading;

    return Skeletonizer(
      enabled: isLoading,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFE5E7EB),
        highlightColor: Color(0xFFF9FAFB),
        duration: Duration(milliseconds: 1200),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          decoration: BoxDecoration(
            color: DT.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            children: [
              _buildPmRow(data),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: _expanded ? _buildExtended(data) : const SizedBox.shrink(),
              ),
              _buildToggleHint(),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);
  }

  Widget _buildPmRow(PollutantCardData data) {
    return Row(
      children: [
        Expanded(child: _PmMiniCard(name: 'PM2.5', value: data.pm25, unit: 'µg/m³', grade: data.pm25Grade)),
        const SizedBox(width: 8),
        Expanded(child: _PmMiniCard(name: 'PM10', value: data.pm10, unit: 'µg/m³', grade: data.pm10Grade)),
      ],
    );
  }

  Widget _buildExtended(PollutantCardData data) {
    final items = <_ExtendedItem>[
      _ExtendedItem(emoji: '☀️', name: 'O3 (오존)', value: data.o3, unit: 'ppm', grade: data.o3Grade ?? '-', bg: DT.tealLt),
      _ExtendedItem(emoji: '🏭', name: 'NO2 (이산화질소)', value: data.no2, unit: 'ppm', grade: data.no2Grade ?? '-', bg: DT.purpleLt),
    ];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: DT.border),
        ),
        AnimationLimiter(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (i) =>
              AnimationConfiguration.staggeredGrid(
                position: i,
                duration: const Duration(milliseconds: 250),
                columnCount: 2,
                child: ScaleAnimation(
                  scale: 0.92,
                  child: FadeInAnimation(child: _ExtendedCard(item: items[i])),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _expanded ? '접기' : '세부 항목 보기',
            style: const TextStyle(fontSize: 12, color: DT.gray),
          ),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more, size: 18, color: DT.gray),
          ),
        ],
      ),
    );
  }
}

class _PmMiniCard extends StatelessWidget {
  final String name;
  final double? value;
  final String unit;
  final String grade;

  const _PmMiniCard({
    required this.name,
    required this.value,
    required this.unit,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: DT.gradeCardBg(grade),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontSize: 11, color: DT.gray)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DT.gradeBadgeBg(grade),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: DT.gradeText(grade),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedDigitWidget(
                value: value?.toInt() ?? 0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                textStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: DT.gradeText(grade),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: const TextStyle(fontSize: 10, color: DT.gray)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtendedItem {
  final String emoji;
  final String name;
  final double? value;
  final String unit;
  final String grade;
  final Color bg;

  const _ExtendedItem({
    required this.emoji,
    required this.name,
    required this.value,
    required this.unit,
    required this.grade,
    required this.bg,
  });
}

class _ExtendedCard extends StatelessWidget {
  final _ExtendedItem item;
  const _ExtendedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 32 - 32 - 8) / 2;
    return Container(
      width: width,
      height: 72,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 18)),
              const Spacer(),
              Text(item.name, style: const TextStyle(fontSize: 11, color: DT.gray)),
            ],
          ),
          const Spacer(),
          Text(
            item.value != null ? item.value!.toStringAsFixed(3) : '--',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DT.text,
            ),
          ),
          Text(
            '${item.unit} · ${item.grade}',
            style: const TextStyle(fontSize: 10, color: DT.gray),
          ),
        ],
      ),
    );
  }
}
