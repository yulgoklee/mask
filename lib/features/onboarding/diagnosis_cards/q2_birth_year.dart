import 'package:flutter/cupertino.dart';
import '../../../core/constants/design_tokens.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q2 — 출생연도
// ══════════════════════════════════════════════════════════════

class DiagQ2BirthYear extends StatefulWidget {
  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final int questionNumber;

  const DiagQ2BirthYear({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.questionNumber = 2,
  });

  @override
  State<DiagQ2BirthYear> createState() => _DiagQ2BirthYearState();
}

class _DiagQ2BirthYearState extends State<DiagQ2BirthYear> {
  static const int _minYear = 1924;
  static final int _maxYear = DateTime.now().year;
  static const int _defaultYear = 1990;

  late int _selectedYear;
  late final FixedExtentScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialValue ?? _defaultYear;
    final initialIndex = _selectedYear - _minYear;
    _scrollCtrl = FixedExtentScrollController(initialItem: initialIndex);
    // 초기값은 OnboardingScreen._buildProfile()에서 ?? 1990으로 처리되므로
    // postFrameCallback 불필요 — 제거
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  int get _age => DateTime.now().year - _selectedYear;
  bool get _isVulnerable => _age < 18 || _age >= 60;

  @override
  Widget build(BuildContext context) {
    final years = List.generate(_maxYear - _minYear + 1, (i) => _minYear + i);

    // Q2: Column 고정 레이아웃 — 피커를 Expanded로 배치해 스크롤 경합 완전 방지
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 상단 텍스트 ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              qBadge('Q${widget.questionNumber} · 연령'),
              const SizedBox(height: 14),
              qTitle(context, '출생연도를 알려주세요'),
              const SizedBox(height: 8),
              qSubtitle(context, '연령별 기초 민감도를 자동으로 반영해요.'),
              const SizedBox(height: 20),

              // ── 선택된 연도 + 나이 표시 ──────────────────────
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_selectedYear),
                    children: [
                      Text(
                        '$_selectedYear년',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: DT.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '만 $_age세',
                            style: const TextStyle(
                              fontSize: 16,
                              color: DT.gray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_isVulnerable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: DT.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '취약 연령',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DT.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // ── 스크롤 피커 (itemExtent 44 × 5개 = 220px) ──────────
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: DT.grayLt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 선택 영역 하이라이트
                  Center(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: DT.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // 피커
                  CupertinoPicker(
                    scrollController: _scrollCtrl,
                    itemExtent: 44,
                    onSelectedItemChanged: (index) {
                      final yr = years[index];
                      setState(() => _selectedYear = yr);
                      widget.onChanged(yr);
                    },
                    selectionOverlay: const SizedBox.shrink(),
                    children: years.map((yr) {
                      final isSelected = yr == _selectedYear;
                      return Center(
                        child: Text(
                          '$yr년',
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 17,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? DT.primary
                                : DT.gray,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── 인사이트 박스 ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: insightBox(
            '취약 연령(18세 미만 · 60세 이상)은 미세먼지 영향이 더 커요. '
            '기준치를 자동으로 조정해드릴게요.',
          ),
        ),
      ],
    );
  }
}
