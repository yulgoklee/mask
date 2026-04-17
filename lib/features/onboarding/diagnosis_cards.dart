import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
          _qSubtitle(context, '알림 메시지에 이름이 표시돼요. 비워두셔도 돼요.'),
          const SizedBox(height: 36),
          _fieldLabel('이름 (선택)'),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration('예: 율곡'),
            onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
          ),
          const SizedBox(height: 32),
          _insightBox('이름을 입력하면 "율곡님, 오늘 미세먼지가 높아요" 처럼 알림이 개인화돼요.'),
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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
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
                          color: AppColors.primary,
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
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_isVulnerable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '취약 연령 +10%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.coral,
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
              const SizedBox(height: 16),
            ],
          ),
        ),

        // ── 스크롤 피커 (남은 공간 채우기) ──────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
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
                        color: AppColors.primary.withValues(alpha: 0.12),
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
                                ? AppColors.primary
                                : AppColors.textSecondary,
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
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: _insightBox(
            '취약 연령(18세 미만 · 60세 이상)은 민감도 기준값이 10% 추가 강화돼요. '
            '나이가 어릴수록, 또는 어르신일수록 미세먼지의 영향이 커집니다.',
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

  static const _options = [
    ('male',   '👨', '남성'),
    ('female', '👩', '여성'),
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
          const SizedBox(height: 8),
          _qSubtitle(context, '여성인 경우 임신 관련 항목이 추가돼요.'),
          const SizedBox(height: 40),
          Row(
            children: List.generate(_options.length, (i) {
              final (val, emoji, label) = _options[i];
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
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: selected ? AppColors.primary : AppColors.textPrimary,
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
          _insightBox('성별 정보는 임신 여부 항목 표시 여부에만 사용돼요.'),
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
  /// 비트플래그: 0=건강, 1=비염(bit0), 2=천식(bit1), 3=둘다
  final int value;
  final ValueChanged<int> onChanged;
  final int questionNumber;

  const DiagQ4Respiratory({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 4,
  });

  // 체크박스형 조건 옵션 (bit, emoji, label, hint, badge)
  static const _conditions = [
    (1, '👃', '비염 있어요',   '코막힘·재채기가 자주 발생해요',     '+15%'),
    (2, '🫁', '천식 등 질환',  '호흡기·심혈관 질환을 진단받았어요', '+30%'),
  ];

  @override
  Widget build(BuildContext context) {
    final hasRhinitis = value & 1 != 0;
    final hasAsthma   = value & 2 != 0;
    final isHealthy   = value == 0;

    // 총 영향도
    int totalPct = 0;
    if (hasRhinitis) totalPct += 15;
    if (hasAsthma)   totalPct += 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 호흡기'),
          const SizedBox(height: 14),
          _qTitle(context, '호흡기 상태를 알려주세요'),
          const SizedBox(height: 8),
          _qSubtitle(context, '해당되는 항목을 모두 선택해주세요.'),
          const SizedBox(height: 32),

          // ── 건강해요 (해당 없음) ──────────────────────────────
          GestureDetector(
            onTap: () => onChanged(0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isHealthy
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHealthy ? AppColors.success : AppColors.divider,
                  width: isHealthy ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('😊', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '건강해요',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isHealthy
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '호흡기 관련 증상이 없어요',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _badgeChip('+0%', isHealthy),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── 조건 체크박스 행들 ────────────────────────────────
          ..._conditions.map((opt) {
            final (bit, emoji, label, hint, badge) = opt;
            final sel = value & bit != 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  // 해당 비트 토글
                  final next = value ^ bit;
                  onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.coral.withValues(alpha: 0.07)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppColors.coral : AppColors.divider,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
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
                                    ? AppColors.coral
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hint,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _badgeChip(badge, sel),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── 총 영향도 요약 (조건 선택 시) ─────────────────────
          if (!isHealthy) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.coral.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 15, color: AppColors.coral),
                  const SizedBox(width: 8),
                  Text(
                    '선택한 조건으로 알림 기준이 총 +$totalPct% 강화돼요',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.coral,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          _insightBox(
            '비염이 있으면 +15%, 천식 등 호흡기 질환이 있으면 +30% 강화돼요. '
            '두 가지 모두 해당되면 중복 적용(+45%)되어 더 일찍 알려드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q5 — 체감 민감도
// ══════════════════════════════════════════════════════════════

class DiagQ5Sensitivity extends StatelessWidget {
  final int value; // 0=무던 1=보통 2=예민
  final ValueChanged<int> onChanged;
  final int questionNumber;

  const DiagQ5Sensitivity({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 5,
  });

  static const _options = [
    (0, '😶', '무던해요',      '공기 변화를 잘 못 느껴요', '+0%'),
    (1, '😌', '보통이에요',    '가끔 느끼는 편이에요',     '+10%'),
    (2, '😣', '매우 예민해요', '조금만 탁해도 바로 느껴요', '+20%'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 민감도'),
          const SizedBox(height: 14),
          _qTitle(context, '공기 오염에 얼마나\n민감하게 느끼세요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '체감 민감도가 높을수록 알림이 먼저 울려요.'),
          const SizedBox(height: 32),
          Row(
            children: _options.map((opt) {
              final (val, emoji, label, hint, badge) = opt;
              final sel = value == val;
              final badgeColor = _badgeColor(badge);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
                      decoration: BoxDecoration(
                        color: sel ? badgeColor.withValues(alpha: 0.08) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? badgeColor : AppColors.divider,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: sel ? badgeColor : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _badgeChip(badge, sel),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _insightBox(
            '체감 민감도는 개인 경험에 기반해 알림 기준을 조정해요. '
            '매우 예민하다면 +20% 더 엄격하게 반응해드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q6 — 임신 여부 (female/미선택 시 표시, male/other는 자동 N/A)
// ══════════════════════════════════════════════════════════════

class DiagQ6Pregnancy extends StatelessWidget {
  final bool value;
  final String? genderStr; // 'male'|'female'|null
  final ValueChanged<bool> onChanged;
  final int questionNumber;

  const DiagQ6Pregnancy({
    super.key,
    required this.value,
    this.genderStr,
    required this.onChanged,
    this.questionNumber = 6,
  });

  bool get _isApplicable => genderStr == null || genderStr == 'female';

  @override
  Widget build(BuildContext context) {
    if (!_isApplicable) {
      // 남성/기타: 해당 없음 자동 표시
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            _qBadge('Q$questionNumber · 임신'),
            const SizedBox(height: 14),
            _qTitle(context, '임신 여부'),
            const SizedBox(height: 8),
            _qSubtitle(context, '선택하신 성별에는 해당되지 않아요.'),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Column(
                children: [
                  Text('👌', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text(
                    '해당 없어요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '자동으로 건너뜁니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q6 · 임신'),
          const SizedBox(height: 14),
          _qTitle(context, '현재 임신 중이신가요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '임신 중에는 알림 기준을 30% 강화해요.'),
          const SizedBox(height: 36),
          _YesNoRow(
            selectedYes: value,
            yesEmoji: '🤰',
            yesLabel: '임신 중이에요',
            noEmoji: '🙅',
            noLabel: '해당 없어요',
            onYes: () => onChanged(true),
            onNo: () => onChanged(false),
            yesColor: AppColors.coral,
            noColor: AppColors.success,
          ),
          const SizedBox(height: 32),
          _insightBox(
            '임신 중에는 미세먼지가 태반을 통해 태아에게 영향을 줄 수 있어요. '
            '기준값을 30% 강화해 더 일찍 알려드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q7 — 피부 시술
// ══════════════════════════════════════════════════════════════

class DiagQ7SkinTreatment extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final DateTime? treatmentDate;
  final ValueChanged<DateTime?> onTreatmentDateChanged;
  final int questionNumber;

  const DiagQ7SkinTreatment({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onTreatmentDateChanged,
    this.treatmentDate,
    this.questionNumber = 7,
  });

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return '${diff}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = treatmentDate != null
        ? 14 - DateTime.now().difference(treatmentDate!).inDays
        : null;
    final isActive = treatmentDate != null && daysLeft != null && daysLeft > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 피부'),
          const SizedBox(height: 14),
          _qTitle(context, '최근 피부 시술을\n받으셨나요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '시술 후 피부 장벽이 약해져 미세먼지 영향이 커요.'),
          const SizedBox(height: 36),
          _YesNoRow(
            selectedYes: value,
            yesEmoji: '✨',
            yesLabel: '받았어요',
            noEmoji: '😊',
            noLabel: '해당 없어요',
            onYes: () => onChanged(true),
            onNo: () {
              onChanged(false);
              onTreatmentDateChanged(null);
            },
            yesColor: AppColors.coral,
            noColor: AppColors.success,
          ),
          // 날짜 입력 — "받았어요" 선택 시 표시
          if (value) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: treatmentDate ?? now,
                  firstDate: now.subtract(const Duration(days: 60)),
                  lastDate: now,
                  helpText: '시술 날짜를 선택하세요',
                  cancelText: '취소',
                  confirmText: '확인',
                );
                if (picked != null) onTreatmentDateChanged(picked);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.coral.withValues(alpha: 0.07)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? AppColors.coral.withValues(alpha: 0.40)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: isActive
                          ? AppColors.coral
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treatmentDate != null
                                ? '시술일: ${_formatDate(treatmentDate!)}'
                                : '시술 날짜를 선택해주세요 (선택)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: treatmentDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '강화 알림 ${daysLeft}일 남음',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.coral),
                              ),
                            )
                          else if (treatmentDate != null && !isActive)
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Text(
                                '2주가 지나 강화 알림이 종료됐어요',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isActive
                          ? AppColors.coral
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _insightBox(
            '레이저·필링·보톡스 등 시술 후 2주간 피부 장벽이 저하돼요. '
            '날짜를 입력하면 2주 후 자동으로 강화 알림이 해제돼요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q8 — 야외 활동량
// ══════════════════════════════════════════════════════════════

class DiagQ8Outdoor extends StatelessWidget {
  final int value; // 0=1h미만 1=1~3h 2=3h이상
  final ValueChanged<int> onChanged;
  final int questionNumber;

  const DiagQ8Outdoor({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 8,
  });

  static const _options = [
    (0, Icons.home_outlined,   '1시간 미만', '주로 실내에 있어요',  '+0%'),
    (1, Icons.directions_walk, '1~3시간',    '매일 외출은 해요',    '+5%'),
    (2, Icons.directions_run,  '3시간 이상', '야외 활동이 많아요', '+10%'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 활동량'),
          const SizedBox(height: 14),
          _qTitle(context, '하루 평균 야외 활동 시간이\n얼마나 되나요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '야외 활동이 많을수록 미세먼지 노출 위험이 높아져요.'),
          const SizedBox(height: 32),
          ..._options.map((opt) {
            final (val, icon, label, sublabel, badge) = opt;
            final sel = value == val;
            final badgeColor = _badgeColor(badge);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onChanged(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: sel
                        ? badgeColor.withValues(alpha: 0.07)
                        : AppColors.surface,
                    border: Border.all(
                      color: sel ? badgeColor : AppColors.divider,
                      width: sel ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: sel ? badgeColor.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: sel ? badgeColor : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: sel ? badgeColor : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              sublabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _badgeChip(badge, sel),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          _insightBox(
            '하루 3시간 이상 야외 활동 시 미세먼지 흡입량이 최대 3배 증가해요. '
            '활동 시간에 맞는 실질적인 알림 타이밍을 설정해드려요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q9 — 활동 태그 (복수 선택)
// ══════════════════════════════════════════════════════════════

class DiagQ9ActivityTags extends StatelessWidget {
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final int questionNumber;

  const DiagQ9ActivityTags({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 9,
  });

  // (tag, emoji, label, hint, badge)
  static const _options = [
    (ActivityTag.commute,   '🚇', '출퇴근',     '대중교통·도보 이동',     '+3%'),
    (ActivityTag.walk,      '🚶', '산책',       '공원·동네 가벼운 산책', '+3%'),
    (ActivityTag.exercise,  '🏃', '운동',       '조깅·자전거·야외 운동', '+5%'),
    (ActivityTag.delivery,  '🛵', '배달/외근',  '야외 업무·배달',         '+5%'),
    (ActivityTag.childcare, '👶', '아이 등하원', '아이와 함께 야외 활동', '+3%'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 활동 유형'),
          const SizedBox(height: 14),
          _qTitle(context, '주로 어떤 활동을 하시나요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '복수 선택 가능 · 없으면 건너뛰세요.'),
          const SizedBox(height: 32),
          ..._options.map((opt) {
            final (tag, emoji, label, hint, badge) = opt;
            final sel = value.contains(tag);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  final next = [...value];
                  if (sel) {
                    next.remove(tag);
                  } else {
                    next.add(tag);
                  }
                  onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 26)),
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
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _badgeChip(badge, sel),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: sel ? AppColors.primary : AppColors.divider,
                            width: 2,
                          ),
                        ),
                        child: sel
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          _insightBox(
            '운동·배달처럼 격한 외기 노출은 +5%, 산책·출퇴근은 +3% 기준이 강화돼요. '
            '최대 +10% 한도 내에서 중복 적용됩니다.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Q10 — 마스크 불편도
// ══════════════════════════════════════════════════════════════

class DiagQ10Discomfort extends StatelessWidget {
  final int value; // 0=안느낌 1=보통 2=많이불편
  final ValueChanged<int> onChanged;
  final int questionNumber;

  const DiagQ10Discomfort({
    super.key,
    required this.value,
    required this.onChanged,
    this.questionNumber = 10,
  });

  static const _options = [
    (0, '😌', '편해요',        '마스크 착용이 익숙해요',   '+0%'),
    (1, '😐', '보통이에요',    '가끔 답답하긴 해요',       '+0%'),
    (2, '😮', '많이 불편해요', '답답함·김 서림이 심해요',  '−10%'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _qBadge('Q$questionNumber · 마스크'),
          const SizedBox(height: 14),
          _qTitle(context, '마스크 착용이\n불편하신가요?'),
          const SizedBox(height: 8),
          _qSubtitle(context, '많이 불편하면 알림 기준을 조금 완화해드려요.'),
          const SizedBox(height: 32),
          Row(
            children: _options.map((opt) {
              final (val, emoji, label, hint, badge) = opt;
              final sel = value == val;
              final isNegative = badge.startsWith('−');
              final badgeColor = isNegative
                  ? AppColors.primary   // 완화 → 파랑
                  : _badgeColor(badge); // 나머지 → 트래픽라이트
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
                      decoration: BoxDecoration(
                        color: sel ? badgeColor.withValues(alpha: 0.08) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? badgeColor : AppColors.divider,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: sel ? badgeColor : AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _badgeChip(badge, sel),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _insightBox(
            '마스크가 많이 불편한 경우, 꼭 써야 할 타이밍에만 알려드려요. '
            '무리한 착용보다 실질적인 보호에 집중합니다.',
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
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
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
            color: AppColors.textPrimary,
            height: 1.3,
          ),
    );

/// 서브타이틀
Widget _qSubtitle(BuildContext context, String subtitle) =>
    Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
    );

/// 💡 인사이트 박스
Widget _insightBox(String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
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
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

/// 텍스트 필드 데코레이션
InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

/// 영향도 퍼센트 → 트래픽라이트 색상
Color _badgeColor(String badge) {
  final n = int.tryParse(badge.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  if (n == 0)   return AppColors.success;    // +0%  → 초록
  if (n <= 15)  return AppColors.dustNormal; // +10~15% → 노랑
  return AppColors.coral;                    // +20~30% → 빨강
}

/// 퍼센트 배지 칩 — 영향도 크기에 따라 색상 자동 적용
Widget _badgeChip(String badge, bool selected) {
  final color = _badgeColor(badge);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: selected ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      badge,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: selected ? Colors.white : color,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  Yes / No 두 버튼 Row
// ══════════════════════════════════════════════════════════════

class _YesNoRow extends StatelessWidget {
  final bool selectedYes;
  final String yesEmoji;
  final String yesLabel;
  final String noEmoji;
  final String noLabel;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final Color yesColor;
  /// 선택 시 "아니요" 버튼 색상 — 기본은 primary(파랑)
  final Color noColor;

  const _YesNoRow({
    required this.selectedYes,
    required this.yesEmoji,
    required this.yesLabel,
    required this.noEmoji,
    required this.noLabel,
    required this.onYes,
    required this.onNo,
    required this.yesColor,
    this.noColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onYes,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: selectedYes
                    ? yesColor.withValues(alpha: 0.10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selectedYes ? yesColor : AppColors.divider,
                  width: selectedYes ? 2.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(yesEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(
                    yesLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: selectedYes ? yesColor : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onNo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: !selectedYes
                    ? noColor.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: !selectedYes ? noColor : AppColors.divider,
                  width: !selectedYes ? 2.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(noEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(
                    noLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: !selectedYes ? noColor : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
