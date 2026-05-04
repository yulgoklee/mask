import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/care_models.dart';
import '../providers/care_providers.dart';

class ProtectionAreaChart extends ConsumerWidget {
  const ProtectionAreaChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(protectionChartProvider);

    final widget = chartAsync.when(
      loading: () => _ChartCard(data: ProtectionChartData.placeholder()),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (data)  => _ChartCard(data: data),
    );

    return widget
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

// ── 차트 카드 ─────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final ProtectionChartData data;
  const _ChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        DT.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: AppTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildEmojiFlow(),
          _buildCta(context),
        ],
      ),
    );
  }

  // ── 헤더: 카드 제목 + 흐름 요약 메시지 ─────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '앞으로 12시간',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.bold,
              color:      DT.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            buildFlowText(data.chartPoints, DateTime.now()),
            style: const TextStyle(
              fontSize: 14,
              color:    DT.gray,
              height:   1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── 표정 흐름: h=0,2,4,6,8,10 이모지 6개 ─────────────────

  Widget _buildEmojiFlow() {
    final now   = DateTime.now();
    final hours = const [0, 2, 4, 6, 8, 10];
    final pts   = data.chartPoints;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: hours.map((h) {
          final ratio = (h < pts.length) ? pts[h].finalRatio : 0.0;
          final emoji = pollutantEmoji(ratio);
          final label = h == 0 ? '지금' : _hourLabel(now, h);
          return _EmojiSpot(emoji: emoji, label: label);
        }).toList(),
      ),
    );
  }

  static String _hourLabel(DateTime now, int h) {
    final dt  = now.add(Duration(hours: h));
    final hr  = dt.hour;
    final isAm = hr < 12;
    final h12  = hr % 12 == 0 ? 12 : hr % 12;
    return '${isAm ? "오전" : "오후"}\n$h12시';
  }

  // ── 하단 링크 ─────────────────────────────────────────────

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 16, 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.go('/report'),
          style: TextButton.styleFrom(
            foregroundColor: DT.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: const Text(
            '지난 7일 평균과 비교하기 ›',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ── 표정 스팟 ─────────────────────────────────────────────

class _EmojiSpot extends StatelessWidget {
  final String emoji;
  final String label;
  const _EmojiSpot({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color:    DT.gray,
            height:   1.3,
          ),
        ),
      ],
    );
  }
}
