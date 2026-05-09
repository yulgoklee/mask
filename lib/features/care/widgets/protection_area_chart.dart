import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ── 12시간 흐름 (카드 X — 배경 통합, Design 권장) ──────────

class _ChartCard extends StatelessWidget {
  final ProtectionChartData data;
  const _ChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildEmojiFlow(),
      ],
    );
  }

  // ── 헤더: 흐름 라벨 + 요약 ────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '앞으로 12시간',
          style: TextStyle(
            fontSize:      13,
            fontWeight:    FontWeight.w600,
            color:         DT.gray,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          buildFlowText(data.chartPoints, DateTime.now()),
          style: const TextStyle(
            fontSize:      18,
            fontWeight:    FontWeight.w600,
            color:         DT.text,
            height:        1.4,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── 시점별 흐름: h=0,2,4,6,8,10 이모지 6개 ───────────────
  //
  // 1.2.0 후보: 라인 차트로 변경 (시안 v3 방향)

  Widget _buildEmojiFlow() {
    final now   = DateTime.now();
    final hours = const [0, 2, 4, 6, 8, 10];
    final pts   = data.chartPoints;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
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
