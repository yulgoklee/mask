import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/report_models.dart';
import '../providers/report_providers.dart';

// ── TrendLine ─────────────────────────────────────────────
//
// §4.4 "추세 한 줄" 위젯.
// trendProvider → TrendData? 를 받아 렌더링.
// null이면 SizedBox.shrink() — 슬롯 자체 미렌더링.
// 별도 카드 박스 없음. Padding만 적용.

class TrendLine extends ConsumerWidget {
  const TrendLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(trendProvider);

    return asyncData.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return _TrendLineContent(data: data);
      },
    );
  }
}

// ── 추세 텍스트 ───────────────────────────────────────────

class _TrendLineContent extends StatelessWidget {
  final TrendData data;

  const _TrendLineContent({required this.data});

  // TrendCategory → (이모지, 카피) 매핑 (§4.4 임계값 매트릭스)
  (String emoji, String copy) _trendText(TrendCategory category) =>
      switch (category) {
        TrendCategory.muchBetter     => ('🌿', '지난주보다 많이 깨끗했어요'),
        TrendCategory.slightlyBetter => ('🌱', '지난주보다 조금 깨끗했어요'),
        TrendCategory.similar        => ('➡️', '지난주와 비슷한 한 주였어요'),
        TrendCategory.slightlyWorse  => ('⚠️', '지난주보다 조금 안 좋았어요'),
        TrendCategory.muchWorse      => ('🌫️', '지난주보다 많이 안 좋았어요'),
      };

  @override
  Widget build(BuildContext context) {
    final (emoji, copy) = _trendText(data.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(
        '$emoji  $copy',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: DT.text,
        ),
      ),
    );
  }
}
