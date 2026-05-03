import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/report_models.dart';
import '../providers/report_providers.dart';

// ── InsightCard ───────────────────────────────────────────
//
// §4.3 "인사이트 카드" 위젯.
// insightProvider → InsightData? 를 받아 렌더링.
// null이면 SizedBox.shrink() — 슬롯 자체 미렌더링.

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(insightProvider);

    return asyncData.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return _InsightContent(data: data);
      },
    );
  }
}

// ── 카드 본문 ─────────────────────────────────────────────

class _InsightContent extends StatelessWidget {
  final InsightData data;

  const _InsightContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주의 발견',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DT.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.bodyText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: DT.text,
              height: 1.6,
            ),
          ),
          if (data.footnoteText != null) ...[
            const SizedBox(height: 8),
            Text(
              data.footnoteText!,
              style: const TextStyle(
                fontSize: 12,
                color: DT.gray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
