import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 5축 가중치 항목 모델
class AxisItem {
  final String key;        // 'respiratory' | 'cardiovascular' | 'smoking' | 'special' | 'age'
  final String label;      // "호흡기 민감"
  final String? sub;       // "천식·비염" | "35세" | null
  final double weight;
  final double delta;      // 음수 (예: -10.5 ㎍/㎥)
  final bool isActive;     // weight > 0

  const AxisItem({
    required this.key,
    required this.label,
    this.sub,
    required this.weight,
    required this.delta,
    required this.isActive,
  });
}

/// 5축 가중치 리스트 — Variant D (시안 profile-components PAxisList variant D)
///
/// 활성 항목: vertical padding 14, hairline 구분선
///   좌: label 15pt w700 + sub 12pt w500 (marginTop 3)
///   우: delta 18pt w700 tabular-nums + "㎍/㎥" 11pt w500 (marginLeft 3)
/// 비활성 항목들: 마지막 active 행 아래에 한 줄 압축
///   "심혈관 · 흡연 · 임신·특별 — 해당 없음" (12pt w500 DT.gray2)
class AxisList extends StatelessWidget {
  final List<AxisItem> axes;
  final Color accentColor;

  const AxisList({
    super.key,
    required this.axes,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = axes.where((a) => a.isActive).toList();
    final neutral = axes.where((a) => !a.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 활성 항목 ─────────────────────────────────────
        ...active.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final isLast = i == active.length - 1;
          final showDivider = !isLast || neutral.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // 좌: label + sub
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DT.text,
                              letterSpacing: -0.15,
                            ),
                          ),
                          if (a.sub != null && a.sub!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              a.sub!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: DT.gray,
                                letterSpacing: -0.06,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 우: delta + 단위
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          a.delta.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: DT.text,
                            letterSpacing: -0.36,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '㎍/㎥',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: DT.gray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showDivider)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: DT.text.withValues(alpha: 0.08),
                ),
            ],
          );
        }),

        // ── 비활성 항목 한 줄 압축 ─────────────────────────
        if (neutral.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${neutral.map((n) => n.label).join(' · ')} — 해당 없음',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: DT.gray2,
                letterSpacing: -0.06,
                height: 1.55,
              ),
            ),
          ),
      ],
    );
  }
}
