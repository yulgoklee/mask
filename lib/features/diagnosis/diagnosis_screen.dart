import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';
import 'result_screen.dart';

/// 민감도 진단 화면 — 3파트 step-by-step 카드
///
/// Part 1: 기저질환 여부  (w1)
/// Part 2: 야외 활동 시간 (w2)
/// Part 3: 체감 민감도   (w3)
/// 결과  : S값 + 나만의 마스크 기준 표시
///
/// 완료 시 UserProfile(hasCondition, activityLevel, sensitivity) 업데이트 후 저장.
class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // 진단 응답 — 기존 프로필 값으로 초기화
  late bool _hasCondition;
  late ActivityLevel _activityLevel;
  late SensitivityLevel _sensitivity;

  // 결과 페이지용 계산된 S값
  double _s = 0.0;

  @override
  void initState() {
    super.initState();
    // ConsumerState에서는 initState에서 ref.read 사용 가능
    final profile = ref.read(profileProvider);
    _hasCondition = profile.hasCondition;
    _activityLevel = profile.activityLevel;
    _sensitivity = profile.sensitivity;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── 페이지 이동 ────────────────────────────────────────────

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  /// Part 3 → 결과 페이지: S 계산 후 프로필 저장
  Future<void> _goToResult() async {
    final profile = ref.read(profileProvider);
    final updated = profile.copyWith(
      hasCondition: _hasCondition,
      conditionType: _hasCondition ? profile.conditionType : ConditionType.none,
      activityLevel: _activityLevel,
      sensitivity: _sensitivity,
    );

    final s = SensitivityCalculator.compute(updated);
    await ref.read(profileProvider.notifier).saveProfile(updated);

    if (!mounted) return;
    setState(() => _s = s);
    _next();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final nameOf = profile.name?.isNotEmpty == true
        ? '${profile.name}님의'
        : '나의';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _currentPage < 3 ? '$nameOf 민감도 진단' : '진단 완료',
              showBack: _currentPage > 0 && _currentPage < 3,
              onBack: _prev,
              onClose: () => Navigator.pop(context),
            ),
            if (_currentPage < 3) _ProgressBar(step: _currentPage + 1, total: 3),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Part1(
                    hasCondition: _hasCondition,
                    onChanged: (v) => setState(() => _hasCondition = v),
                  ),
                  _Part2(
                    activityLevel: _activityLevel,
                    onChanged: (v) => setState(() => _activityLevel = v),
                  ),
                  _Part3(
                    sensitivity: _sensitivity,
                    onChanged: (v) => setState(() => _sensitivity = v),
                  ),
                  _ResultPage(s: _s, profile: profile),
                ],
              ),
            ),
            if (_currentPage < 3)
              _BottomButton(
                label: _currentPage == 2 ? '분석하기' : '다음',
                onTap: _currentPage == 2 ? _goToResult : _next,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Part 1 — 기저질환
// ─────────────────────────────────────────────────────────

class _Part1 extends StatelessWidget {
  final bool hasCondition;
  final ValueChanged<bool> onChanged;

  const _Part1({required this.hasCondition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const _PartLabel('Part 1 · 건강 상태'),
          const SizedBox(height: 14),
          const Text(
            '비염, 천식, 호흡기 질환이\n있으신가요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '기저질환이 있으면 일반 기준보다 일찍 마스크가 필요해요.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: _SquareChoice(
                  icon: Icons.sentiment_satisfied_outlined,
                  label: '없어요',
                  sublabel: '해당 없음',
                  selected: !hasCondition,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SquareChoice(
                  icon: Icons.medical_services_outlined,
                  label: '있어요',
                  sublabel: '비염·천식·기타',
                  selected: hasCondition,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Part 2 — 야외 활동 시간
// ─────────────────────────────────────────────────────────

class _Part2 extends StatelessWidget {
  final ActivityLevel activityLevel;
  final ValueChanged<ActivityLevel> onChanged;

  const _Part2({required this.activityLevel, required this.onChanged});

  static const _items = [
    (ActivityLevel.low, Icons.home_outlined, '1시간 미만', '주로 실내에 있어요', 0.0),
    (ActivityLevel.normal, Icons.directions_walk, '1~3시간', '매일 외출은 해요', 0.1),
    (ActivityLevel.high, Icons.directions_run, '3시간 이상', '야외 활동이 많아요', 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const _PartLabel('Part 2 · 일상 패턴'),
          const SizedBox(height: 14),
          const Text(
            '하루에 밖에서 보내는\n시간이 얼마나 되나요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '외출 시간이 길수록 미세먼지에 노출될 위험이 높아요.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ..._items.map((item) {
            final (level, icon, label, sublabel, _) = item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CardChoice(
                icon: icon,
                label: label,
                sublabel: sublabel,
                selected: activityLevel == level,
                onTap: () => onChanged(level),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Part 3 — 체감 민감도
// ─────────────────────────────────────────────────────────

class _Part3 extends StatelessWidget {
  final SensitivityLevel sensitivity;
  final ValueChanged<SensitivityLevel> onChanged;

  const _Part3({required this.sensitivity, required this.onChanged});

  static const _items = [
    (SensitivityLevel.low, Icons.sentiment_neutral_outlined, '잘 모르겠어요', '느끼지 못하는 편이에요'),
    (SensitivityLevel.normal, Icons.sentiment_satisfied_outlined, '가끔 느껴요', '심할 때만 불편해요'),
    (SensitivityLevel.high, Icons.sentiment_dissatisfied_outlined, '바로 느껴요', '조금만 탁해도 달라요'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const _PartLabel('Part 3 · 체감 민감도'),
          const SizedBox(height: 14),
          const Text(
            '공기가 안 좋을 때\n바로 느껴지는 편인가요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '주관적인 체감도예요. 솔직하게 선택해주세요.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ..._items.map((item) {
            final (level, icon, label, sublabel) = item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CardChoice(
                icon: icon,
                label: label,
                sublabel: sublabel,
                selected: sensitivity == level,
                onTap: () => onChanged(level),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 결과 페이지
// ─────────────────────────────────────────────────────────

class _ResultPage extends StatelessWidget {
  final double s;
  final UserProfile profile;

  const _ResultPage({required this.s, required this.profile});

  @override
  Widget build(BuildContext context) {
    final levelLabel = SensitivityCalculator.label(s);
    final levelColor = _levelColor(s);

    // S ≥ sThreshold 이면 T_final 적용, 아니면 일반 기준(36) 표시
    final bool usesFinal = s >= SensitivityCalculator.sThreshold;
    final double tFinal = usesFinal ? SensitivityCalculator.threshold(s) : 36.0;
    final String compareText = usesFinal
        ? '일반 기준(36 μg/m³)보다 ${(36 - tFinal).toStringAsFixed(0)} 낮아요'
        : '일반 기준과 동일해요';

    final name = profile.name?.isNotEmpty == true
        ? '${profile.name}님은'
        : '분석 완료!';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // 아이콘
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: levelColor, size: 42),
          ),
          const SizedBox(height: 22),

          // 이름 + 레이블
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              children: [
                const TextSpan(text: '호흡기 민감도가 '),
                TextSpan(
                  text: levelLabel,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' 수준이에요.'),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // 결과 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ResultRow(
                  label: '민감도 계수 (S)',
                  value: s.toStringAsFixed(2),
                  color: levelColor,
                ),
                const Divider(height: 28, color: AppColors.divider),
                _ResultRow(
                  label: '나만의 마스크 기준',
                  value: 'PM2.5  ${tFinal.toStringAsFixed(0)} μg/m³ 이상',
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  compareText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            '앞으로 ${profile.displayName} 기준으로 알림을 드릴게요 😊',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // 상세 리포트 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 진단 화면 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResultScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '상세 리포트 보기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 닫기 (리포트 없이 종료)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '닫기',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _levelColor(double s) {
    if (s >= 0.5) return AppColors.dustBad;
    if (s >= 0.3) return AppColors.dustNormal;
    if (s >= 0.1) return AppColors.secondary;
    return AppColors.textSecondary;
  }
}

// ─────────────────────────────────────────────────────────
// 공통 레이아웃 위젯
// ─────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.showBack,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppColors.textPrimary,
                  onPressed: onBack,
                )
              : const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            color: AppColors.textSecondary,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: step / total,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$step / $total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 선택 UI 컴포넌트
// ─────────────────────────────────────────────────────────

/// 정방형 선택 버튼 (Part 1 — 예/아니오)
class _SquareChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _SquareChoice({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 가로형 카드 선택 버튼 (Part 2, 3 — 3지 선택)
class _CardChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _CardChoice({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 아이콘 박스
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 체크 아이콘
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: selected ? 1.0 : 0.0,
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 결과 행
// ─────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 파트 레이블 배지
class _PartLabel extends StatelessWidget {
  final String text;
  const _PartLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
