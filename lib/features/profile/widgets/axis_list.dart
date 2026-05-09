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

/// AxisList 렌더 방식 변형 (D-4: axis_list.dart 내부 enum)
enum AxisListVariant {
  /// D: 활성 항목 강조 + 비활성 항목 한 줄 압축 (기본값, 기존 사용처 보호 W-3)
  d,

  /// F: 5축 모두 Key-Value 두 열로 렌더링 (Drill 화면용)
  f,
}

/// 5축 가중치 리스트
///
/// [variant] 기본값 AxisListVariant.d — 기존 사용처(결과지·프로필 표면) 깨짐 방지 (W-3)
///
/// Variant D: 활성 항목 강조, 비활성 한 줄 압축
///   활성: vertical padding 14, hairline 구분선
///     좌: label 15pt w700 + sub 12pt w500 (marginTop 3)
///     우: delta 18pt w700 tabular-nums + "㎍/㎥" 11pt w500 (marginLeft 3)
///   비활성: "심혈관 · 흡연 · 임신·특별 — 해당 없음" (12pt w500 DT.gray2)
///
/// Variant F: 5축 전부 Key-Value 두 열 (Drill 화면용)
///   각 행 padding 12, hairline
///   좌: label 14pt — isActive w600/text, else w500/gray
///   우: delta "X.X㎍/㎥" or "해당 없음" 14pt tabular-nums
class AxisList extends StatelessWidget {
  final List<AxisItem> axes;
  final Color accentColor;
  final AxisListVariant variant;

  const AxisList({
    super.key,
    required this.axes,
    required this.accentColor,
    this.variant = AxisListVariant.d,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == AxisListVariant.f) {
      return _buildVariantF();
    }
    return _buildVariantD();
  }

  // ── Variant F: 5축 전부 Key-Value 두 열 ───────────────────────
  Widget _buildVariantF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: axes.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        final isLast = i == axes.length - 1;
        final noData = !a.isActive;
        // 연령 축은 sub가 "N세" 형태이므로 라벨에 포함 (시안 F: "연령 (35세)")
        final label = a.key == 'age' && a.sub != null
            ? '연령 (${a.sub})'
            : a.label;
        final valueText = noData
            ? '해당 없음'
            : '${a.delta.toStringAsFixed(1)}㎍/㎥';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // 좌: 라벨
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: noData
                            ? FontWeight.w500
                            : FontWeight.w600,
                        color: noData ? DT.gray : DT.text,
                        letterSpacing: -0.14,
                      ),
                    ),
                  ),
                  // 우: 값
                  Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: noData
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: noData ? DT.gray2 : DT.text,
                      letterSpacing: -0.14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                color: DT.text.withValues(alpha: 0.08),
              ),
          ],
        );
      }).toList(),
    );
  }

  // ── Variant D: 활성 강조 + 비활성 압축 ───────────────────────
  Widget _buildVariantD() {
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
