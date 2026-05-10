import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/constants/location_stations.dart';
import '../../data/models/user_profile.dart';

// ══════════════════════════════════════════════════════════════
//  Q1 — 닉네임
// ══════════════════════════════════════════════════════════════

class DiagQ1Nickname extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final int questionNumber;

  const DiagQ1Nickname({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.questionNumber = 1,
  });

  @override
  State<DiagQ1Nickname> createState() => _DiagQ1NicknameState();
}

class _DiagQ1NicknameState extends State<DiagQ1Nickname> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q${widget.questionNumber} · 이름'),
          const SizedBox(height: 14),
          _qTitle(context, '어떻게 불러드릴까요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '알림 메시지에 이름이 표시돼요. "지수님, 지금 마스크를 쓰세요!"처럼요.'),
          const SizedBox(height: 36),
          _fieldLabel('이름'),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration('예: 지수'),
            onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
          ),
          const SizedBox(height: 32),
          _insightBox('이름을 입력하면 "지수님, 오늘 미세먼지가 높아요" 처럼 알림이 개인화돼요.'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

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
  static final int _minYear = 1924;
  static final int _maxYear = DateTime.now().year;
  static final int _defaultYear = 1990;

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
              _qBadge('Q${widget.questionNumber} · 연령'),
              const SizedBox(height: 14),
              _qTitle(context, '출생연도를 알려주세요'),
              const SizedBox(height: 8),
              _qSubtitle(context, '연령별 기초 민감도를 자동으로 반영해요.'),
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
          child: _insightBox(
            '취약 연령(18세 미만 · 60세 이상)은 미세먼지 영향이 더 커요. '
            '기준치를 자동으로 조정해드릴게요.',
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q3 — 성별
// ══════════════════════════════════════════════════════════════

class DiagQ3Gender extends StatelessWidget {
  final String? value; // 'male'|'female'|null
  final ValueChanged<String?> onChanged;
  final int questionNumber;

  const DiagQ3Gender({super.key, this.value, required this.onChanged, this.questionNumber = 3});

  static const _options = <(String, String)>[
    ('male',   '남성'),
    ('female', '여성'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 성별'),
          const SizedBox(height: 14),
          _qTitle(context, '성별을 알려주세요'),
          const SizedBox(height: 40),
          Row(
            children: List.generate(_options.length, (i) {
              final (val, label) = _options[i];
              final selected = value == val;
              // 카드 사이 간격만 오른쪽 패딩 — 마지막 카드는 패딩 없음
              final isLast = i == _options.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 12),
                  child: GestureDetector(
                    // 이미 선택된 항목 재탭 시 null 토글 방지 — 항상 해당 값 설정
                    onTap: () => onChanged(val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: selected
                            ? DT.primary.withValues(alpha: 0.08)
                            : DT.grayLt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? DT.primary : DT.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            val == 'male' ? Icons.male : Icons.female,
                            size: 40,
                            color: selected ? DT.primary : DT.gray2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: selected ? DT.primary : DT.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q4 — 호흡기 상태
// ══════════════════════════════════════════════════════════════

class DiagQ4Respiratory extends StatelessWidget {
  final bool rhinitis;
  final bool asthma;
  final bool copd;
  final bool allergy;
  final bool noneSelected;
  final void Function(bool rhinitis, bool asthma, bool copd, bool allergy, bool noneSelected) onChanged;
  final int questionNumber;

  const DiagQ4Respiratory({
    super.key,
    required this.rhinitis,
    required this.asthma,
    required this.copd,
    required this.allergy,
    required this.noneSelected,
    required this.onChanged,
    this.questionNumber = 4,
  });

  static const _conditions = <(String, IconData, String, String)>[
    ('rhinitis', Icons.water_drop_outlined,   '비염 (알레르기성·비알레르기성)',  '콧물·코막힘·재채기·코 가려움'),
    ('asthma',   Icons.air,                   '천식 (운동 유발 포함)',         '쌕쌕거림·가슴 답답함·만성 기침'),
    ('copd',     Icons.waves_outlined,        'COPD / 만성 기관지염',         '만성 기침·가래·계단 시 숨 참'),
    ('allergy',  Icons.local_florist_outlined, '흡입성 알레르기',              '꽃가루·먼지·동물 털 등에 반응'),
  ];

  bool _valueOf(String key) {
    switch (key) {
      case 'rhinitis': return rhinitis;
      case 'asthma':   return asthma;
      case 'copd':     return copd;
      case 'allergy':  return allergy;
      default:         return false;
    }
  }

  void _toggle(String key) {
    final newRhinitis = key == 'rhinitis' ? !rhinitis : rhinitis;
    final newAsthma   = key == 'asthma'   ? !asthma   : asthma;
    final newCopd     = key == 'copd'     ? !copd     : copd;
    final newAllergy  = key == 'allergy'  ? !allergy  : allergy;
    onChanged(newRhinitis, newAsthma, newCopd, newAllergy, false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 호흡기'),
          const SizedBox(height: 14),
          _qTitle(context, '호흡기 상태를 알려주세요'),
          const SizedBox(height: 6),
          _qSubtitle(context, '호흡기 상태는 마스크 판단에 가장 중요해요'),
          const SizedBox(height: 4),
          _qSubtitle(context, '진단 받은 게 있다면 모두 선택해주세요'),
          const SizedBox(height: 28),

          // ── 체크박스 항목 (4개) ──────────────────────────────
          ..._conditions.map((opt) {
            final (key, iconData, label, hint) = opt;
            final sel = _valueOf(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggle(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? DT.caution.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? DT.caution : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? DT.caution : DT.gray2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: sel ? DT.caution : DT.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DT.gray),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel ? Icons.check_box : Icons.check_box_outline_blank,
                        color: sel ? DT.caution : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── 구분선 ────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: DT.border),
          ),

          // ── "진단 받은 게 없어요" 라디오 ─────────────────────
          GestureDetector(
            onTap: () => onChanged(false, false, false, false, true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: noneSelected
                    ? DT.safe.withValues(alpha: 0.07)
                    : DT.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: noneSelected ? DT.safe : DT.border,
                  width: noneSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 26, color: noneSelected ? DT.safe : DT.gray2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '진단 받은 게 없어요',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: noneSelected
                            ? DT.safe
                            : DT.text,
                      ),
                    ),
                  ),
                  Icon(
                    noneSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: noneSelected ? DT.safe : DT.gray2,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _insightBox(
            '호흡기 질환이 있으면 같은 농도에서 더 일찍 반응해요.\n'
            '기준치를 최대 30%까지 낮춰 더 일찍 알려드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q5 — 심혈관
// ══════════════════════════════════════════════════════════════

class DiagQ5Cardiovascular extends StatelessWidget {
  final bool hypertension;
  final bool heartDisease;
  final bool stroke;
  final bool noneSelected;
  final void Function(bool hypertension, bool heartDisease, bool stroke, bool noneSelected) onChanged;
  final int questionNumber;

  const DiagQ5Cardiovascular({
    super.key,
    required this.hypertension,
    required this.heartDisease,
    required this.stroke,
    required this.noneSelected,
    required this.onChanged,
    this.questionNumber = 5,
  });

  static const _conditions = <(String, IconData, String, String)>[
    ('hypertension', Icons.monitor_heart_outlined, '고혈압',           '혈압이 높아 심혈관 부담이 있어요'),
    ('heartDisease', Icons.favorite_outline,       '심장 질환',         '심장 관련 질환을 진단받았어요'),
    ('stroke',       Icons.electric_bolt_outlined, '뇌졸중 (중풍) 경험', '뇌혈관 질환을 경험한 적 있어요'),
  ];

  bool _valueOf(String key) {
    switch (key) {
      case 'hypertension': return hypertension;
      case 'heartDisease': return heartDisease;
      case 'stroke':       return stroke;
      default:             return false;
    }
  }

  void _toggle(String key) {
    final newHypertension = key == 'hypertension' ? !hypertension : hypertension;
    final newHeartDisease = key == 'heartDisease' ? !heartDisease : heartDisease;
    final newStroke       = key == 'stroke'       ? !stroke       : stroke;
    onChanged(newHypertension, newHeartDisease, newStroke, false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 심혈관'),
          const SizedBox(height: 14),
          _qTitle(context, '혈관 건강을 알려주세요'),
          const SizedBox(height: 6),
          _qSubtitle(context, '혈관 건강도 미세먼지 영향을 받아요'),
          const SizedBox(height: 4),
          _qSubtitle(context, '진단 받은 게 있다면 모두 선택해주세요'),
          const SizedBox(height: 28),

          // ── 체크박스 항목 (3개) ──────────────────────────────
          ..._conditions.map((opt) {
            final (key, iconData, label, hint) = opt;
            final sel = _valueOf(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggle(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? DT.caution.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? DT.caution : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? DT.caution : DT.gray2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: sel ? DT.caution : DT.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DT.gray),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel ? Icons.check_box : Icons.check_box_outline_blank,
                        color: sel ? DT.caution : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── 구분선 ────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: DT.border),
          ),

          // ── "진단 받은 게 없어요" 라디오 ─────────────────────
          GestureDetector(
            onTap: () => onChanged(false, false, false, true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: noneSelected
                    ? DT.safe.withValues(alpha: 0.07)
                    : DT.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: noneSelected ? DT.safe : DT.border,
                  width: noneSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 26, color: noneSelected ? DT.safe : DT.gray2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '진단 받은 게 없어요',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: noneSelected
                            ? DT.safe
                            : DT.text,
                      ),
                    ),
                  ),
                  Icon(
                    noneSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: noneSelected ? DT.safe : DT.gray2,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _insightBox(
            '혈관 질환이 있으면 미세먼지가 혈관 벽에 더 큰 자극을 줘요.\n'
            '기준치를 최대 25%까지 낮춰 더 일찍 알려드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q5.5 — 잠재 민감군 자가 점검 (선택, 1.1.0+)
//
//  `FeatureFlags.kEnableSignalSelfCheck` 가 true 일 때만 노출.
//  Q5(심혈관) 다음, Q6(흡연) 이전. 4개 신호 (A1·B1·C1·D3) 체크리스트.
//  복수 선택, 답하지 않아도 됨 (모두 false 가능 → 건너뛰기 효과).
//  자세한 매핑: `docs/research/signal_weight_mapping_v0.md`
// ══════════════════════════════════════════════════════════════

class DiagSignalSelfCheck extends StatelessWidget {
  /// SignalId.* → bool. 누락된 키는 false로 간주.
  final Map<String, bool> answers;

  /// 토글 시 갱신된 전체 답변 맵을 부모에 전달.
  final ValueChanged<Map<String, bool>> onChanged;

  /// 진행 표시용 페이지 번호 (Q5와 Q6 사이라서 5나 6의 변형이 아닌 임의 표시).
  final int questionNumber;

  const DiagSignalSelfCheck({
    super.key,
    required this.answers,
    required this.onChanged,
    this.questionNumber = 6,
  });

  /// 신호 카드 정의 (id, iconData, label, hint)
  ///
  /// 라벨은 의학적 진단 표현이 아닌 일상 언어. 답하기 쉬운 형태.
  static const _signals = <(String, IconData, String, String)>[
    (
      'signal_a1', // SignalId.a1
      Icons.water_drop_outlined,
      '콧물·코막힘이 한 주에 4일 이상 있다',
      '계절·환경과 관계없이 자주 반복되는 경우',
    ),
    (
      'signal_b1', // SignalId.b1
      Icons.nights_stay_outlined,
      '자다가 천식 증상으로 깬 적 있다',
      '쌕쌕거림·가슴 답답함으로 새벽에 깬 경험',
    ),
    (
      'signal_c1', // SignalId.c1
      Icons.directions_run,
      '운동 시작 5~10분 후 가슴 답답함·기침',
      '평소 활동량 대비 호흡이 더 거칠어지는 경우',
    ),
    (
      'signal_d3', // SignalId.d3
      Icons.air,
      '만성 가래 동반 기침이 3개월 이상 지속',
      '겨울·아침에 가래가 더 심한 편',
    ),
  ];

  bool _isChecked(String id) => answers[id] ?? false;

  void _toggle(String id) {
    final updated = Map<String, bool>.from(answers);
    final next = !_isChecked(id);
    if (next) {
      updated[id] = true;
    } else {
      // false는 키 자체를 제거 — 답변 안 한 것과 동일하게 취급.
      updated.remove(id);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 자가 점검 (선택)'),
          const SizedBox(height: 14),
          _qTitle(context, '혹시 이런 적\n있으신가요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '복수 선택 가능 · 답하지 않아도 괜찮아요.'),
          const SizedBox(height: 28),

          // ── 4개 신호 체크리스트 ─────────────────────────────
          ..._signals.map((sig) {
            final (id, iconData, label, hint) = sig;
            final sel = _isChecked(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggle(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? DT.caution.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? DT.caution : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? DT.caution : DT.gray2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: sel
                                    ? DT.caution
                                    : DT.text,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hint,
                              style: const TextStyle(
                                fontSize: 12,
                                color: DT.gray,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel ? Icons.check_box : Icons.check_box_outline_blank,
                        color: sel ? DT.caution : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── 의료 면책 + 자료 출처 ──────────────────────────
          _insightBox(
            '체크해도 진단이 아니에요. "민감군일 가능성"을 기준에 살짝 반영할 뿐이에요.\n\n'
            '자료: ARIA·ATS·GOLD·CB Scale 가이드라인 참조',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q6 — 흡연 이력
// ══════════════════════════════════════════════════════════════

class DiagQ6Smoking extends StatelessWidget {
  final SmokingStatus? value; // null = 아직 미선택
  final ValueChanged<SmokingStatus> onChanged;
  final int questionNumber;

  const DiagQ6Smoking({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 6,
  });

  static const _options = <(SmokingStatus, IconData, String, String)>[
    (SmokingStatus.current, Icons.smoking_rooms,       '현재 흡연 중',  '지금도 담배를 피워요'),
    (SmokingStatus.former,  Icons.eco,                 '끊었어요',      '과거에 피웠지만 지금은 아니에요'),
    (SmokingStatus.never,   Icons.check_circle_outline, '안 피워요',    '흡연 이력이 없어요'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 흡연'),
          const SizedBox(height: 14),
          _qTitle(context, '흡연 이력을 알려주세요'),
          const SizedBox(height: 8),
          _qSubtitle(context, '흡연은 폐 민감도에 직접적인 영향을 줘요'),
          const SizedBox(height: 28),

          ..._options.map((opt) {
            final (status, iconData, label, hint) = opt;
            final sel = value == status;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onChanged(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? DT.primary.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? DT.primary : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? DT.primary : DT.gray2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: sel
                                    ? DT.primary
                                    : DT.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DT.gray),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: sel ? DT.primary : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          _insightBox(
            '현재 흡연 중이면 기준치를 20% 더 낮춰요.\n'
            '금연 후에도 폐 민감도가 수년간 높게 유지돼요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q6-1 — 흡연 종류 (현재 흡연 중인 경우만)
// ══════════════════════════════════════════════════════════════

class DiagQ6_1SmokingType extends StatelessWidget {
  final bool cigarette;
  final bool heated;
  final bool vaping;
  final void Function(bool cigarette, bool heated, bool vaping) onChanged;
  final int questionNumber;

  const DiagQ6_1SmokingType({
    super.key,
    required this.cigarette,
    required this.heated,
    required this.vaping,
    required this.onChanged,
    this.questionNumber = 7,
  });

  static const _options = <(String, IconData, String, String)>[
    ('cigarette', Icons.smoking_rooms,     '연초',    '일반 담배'),
    ('heated',    Icons.device_thermostat, '가열식',  'IQOS, glo, lil 등'),
    ('vaping',    Icons.cloud_outlined,    '전자담배', '액상형'),
  ];

  bool _valueOf(String key) {
    switch (key) {
      case 'cigarette': return cigarette;
      case 'heated':    return heated;
      case 'vaping':    return vaping;
      default:          return false;
    }
  }

  void _toggle(String key) {
    onChanged(
      key == 'cigarette' ? !cigarette : cigarette,
      key == 'heated'    ? !heated    : heated,
      key == 'vaping'    ? !vaping    : vaping,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 흡연 종류'),
          const SizedBox(height: 14),
          _qTitle(context, '피우시는 종류는?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '모두 선택해주세요'),
          const SizedBox(height: 28),

          ..._options.map((opt) {
            final (key, iconData, label, hint) = opt;
            final sel = _valueOf(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggle(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? DT.primary.withValues(alpha: 0.07)
                        : DT.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? DT.primary : DT.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 26, color: sel ? DT.primary : DT.gray2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: sel
                                    ? DT.primary
                                    : DT.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DT.gray),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel ? Icons.check_box : Icons.check_box_outline_blank,
                        color: sel ? DT.primary : DT.gray2,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          _insightBox(
            '담배 종류에 따라 폐에 미치는 영향이 달라요. '
            '가열식·전자담배도 미세먼지와 결합하면 폐에 더 큰 자극을 줄 수 있어요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  공용 내부 위젯 & 헬퍼
// ══════════════════════════════════════════════════════════════

/// Q배지 (예: "Q4 · 호흡기")
Widget _qBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: DT.primaryLt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: DT.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );

/// 질문 타이틀
Widget _qTitle(BuildContext context, String title) =>
    Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: DT.text,
            height: 1.3,
          ),
    );

/// 서브타이틀
Widget _qSubtitle(BuildContext context, String subtitle) =>
    Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: DT.gray,
          ),
    );

/// 인사이트 박스
Widget _insightBox(String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DT.primaryLt.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DT.primaryLt),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: DT.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DT.gray,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );

/// 텍스트 필드용 레이블
Widget _fieldLabel(String text) => Text(
      text,
      style: const TextStyle(
        color: DT.text,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

/// 텍스트 필드 데코레이션
InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: DT.gray2),
      filled: true,
      fillColor: DT.grayLt,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DT.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

// ══════════════════════════════════════════════════════════════
//  QLocation — 관심 지역 (집 / 회사·학교)
//  에어코리아 API 검증 측정소명을 시도 + 구/군 2단계 드롭다운으로 선택
//  iOS 백그라운드 알림 Fallback + 가장 가까운 측정소 자동 매핑용
// ══════════════════════════════════════════════════════════════

class DiagQLocation extends StatefulWidget {
  final String homeStation;
  final String officeStation;
  final ValueChanged<String> onHomeChanged;
  final ValueChanged<String> onOfficeChanged;
  final int questionNumber;

  const DiagQLocation({
    super.key,
    required this.homeStation,
    required this.officeStation,
    required this.onHomeChanged,
    required this.onOfficeChanged,
    this.questionNumber = 2,
  });

  @override
  State<DiagQLocation> createState() => _DiagQLocationState();
}

class _DiagQLocationState extends State<DiagQLocation> {
  // 집
  String? _homeSido;
  String? _homeDistrict;

  // 회사
  String? _officeSido;
  String? _officeDistrict;

  List<String> _districtsFor(String? sido) {
    if (sido == null) return [];
    return locationRegionStations[sido]?.keys.toList() ?? [];
  }

  String? _stationFor(String? sido, String? district) {
    if (sido == null || district == null) return null;
    return locationRegionStations[sido]?[district];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q${widget.questionNumber} · 관심 지역'),
          const SizedBox(height: 14),
          _qTitle(context, '자주 계시는 곳을\n알려주세요'),
          const SizedBox(height: 8),
          _qSubtitle(
            context,
            '앱이 백그라운드 상태일 때 이 지역의 측정소 데이터로 알림을 보내요.',
          ),
          const SizedBox(height: 36),
          _locationPicker(
            label: '🏠  집',
            sido: _homeSido,
            district: _homeDistrict,
            onSidoChanged: (v) => setState(() {
              _homeSido = v;
              _homeDistrict = null;
              widget.onHomeChanged('');
            }),
            onDistrictChanged: (v) {
              setState(() => _homeDistrict = v);
              final station = _stationFor(_homeSido, v);
              if (station != null) widget.onHomeChanged(station);
            },
          ),
          const SizedBox(height: 24),
          _locationPicker(
            label: '🏢  회사 · 학교',
            sido: _officeSido,
            district: _officeDistrict,
            onSidoChanged: (v) => setState(() {
              _officeSido = v;
              _officeDistrict = null;
              widget.onOfficeChanged('');
            }),
            onDistrictChanged: (v) {
              setState(() => _officeDistrict = v);
              final station = _stationFor(_officeSido, v);
              if (station != null) widget.onOfficeChanged(station);
            },
          ),
          const SizedBox(height: 28),
          _insightBox(
            '선택하지 않아도 앱은 정상 동작해요. '
            '나중에 프로필 탭에서 언제든지 수정할 수 있어요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _locationPicker({
    required String label,
    required String? sido,
    required String? district,
    required ValueChanged<String?> onSidoChanged,
    required ValueChanged<String?> onDistrictChanged,
  }) {
    final districts = _districtsFor(sido);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DT.text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 시도
            Expanded(
              flex: 2,
              child: _dropdownField(
                hint: '시/도',
                value: sido,
                items: locationSidoList,
                onChanged: onSidoChanged,
              ),
            ),
            const SizedBox(width: 10),
            // 구/군 (시도 선택 전 비활성)
            Expanded(
              flex: 3,
              child: _dropdownField(
                hint: '구/군 선택',
                value: district,
                items: districts,
                onChanged: sido == null ? null : onDistrictChanged,
              ),
            ),
          ],
        ),
        if (district != null && sido != null) ...[
          const SizedBox(height: 6),
          Text(
            '측정소: ${_stationFor(sido, district) ?? '-'}',
            style: const TextStyle(
              fontSize: 11,
              color: DT.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: onChanged == null
            ? DT.border
            : DT.grayLt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? DT.primary : DT.border,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: DT.gray,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            fontSize: 13,
            color: DT.text,
          ),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}
