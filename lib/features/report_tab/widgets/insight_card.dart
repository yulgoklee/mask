import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/report_models.dart';
import '../providers/report_providers.dart';

// ── InsightCard ───────────────────────────────────────────
//
// §4.3 "인사이트 카드" 위젯.
// insightProvider → InsightData? 를 받아 렌더링.
// data null이면 placeholder 카피 표시 (첫 주·데이터 부족).
// loading/error는 SizedBox.shrink — 깜빡거림 방지.

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key});

  /// 데이터 없는 첫 주 placeholder 카피.
  /// 차터 §7.5 톤 규칙: 사실 + 자연스러운 미래 동작. 직접 약속·칭찬 ✕.
  static const String _emptyBodyText =
      '기록이 모이는 중이에요. 한 주가 채워지면 여기에 발견을 적어둘게요.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(insightProvider);

    return asyncData.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => _InsightContent(
        bodyText: data?.bodyText ?? _emptyBodyText,
        footnoteText: data?.footnoteText,
      ),
    );
  }
}

// ── 카드 본문 ─────────────────────────────────────────────

class _InsightContent extends StatelessWidget {
  final String bodyText;
  final String? footnoteText;

  const _InsightContent({required this.bodyText, this.footnoteText});

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
            bodyText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: DT.text,
              height: 1.6,
            ),
          ),
          if (footnoteText != null) ...[
            const SizedBox(height: 8),
            Text(
              footnoteText!,
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
