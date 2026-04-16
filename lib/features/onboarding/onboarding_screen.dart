import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import 'diagnosis_cards.dart';

final _analytics = FirebaseAnalytics.instance;

/// Phase 2: 초개인 정밀 진단 화면
///
/// PageView로 Q1~Q10 카드를 순서대로 보여주고,
/// 상단에 [진단 ● — 분석 — 세팅] 3단계 스테퍼와
/// 질문 내 진행 바를 이중으로 노출합니다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  // ── 진단 임시 상태 (저장은 Phase 4 시뮬레이션 버튼 클릭 시) ──

  String  _nickname           = '';
  int     _birthYear          = DateTime.now().year - 30;
  String  _gender             = 'male';
  int     _respiratoryStatus  = 0;
  int     _sensitivityLevel   = 1;
  bool    _isPregnant         = false;
  bool    _recentSkinTreatment = false;
  int     _outdoorMinutes     = 1;
  List<String> _activityTags  = [];
  int     _discomfortLevel    = 0;

  int _currentPage = 0;

  /// 성별 조건에 따른 전체 페이지 수
  /// - male: Q1~Q3 + Q4~Q5 + Q7~Q10 = 9페이지 (Q6 스킵)
  /// - female: Q1~Q10 = 10페이지
  int get _totalPages => _gender == 'female' ? 10 : 9;

  @override
  void initState() {
    super.initState();
    _analytics.logEvent(name: 'onboarding_step_1');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── 현재 UserProfile 스냅샷 (실시간 가중치 표시용) ──────────

  UserProfile get _currentProfile => UserProfile(
        nickname: _nickname,
        birthYear: _birthYear,
        gender: _gender,
        respiratoryStatus: _respiratoryStatus,
        sensitivityLevel: _sensitivityLevel,
        isPregnant: _isPregnant,
        recentSkinTreatment: _recentSkinTreatment,
        outdoorMinutes: _outdoorMinutes,
        activityTags: _activityTags,
        discomfortLevel: _discomfortLevel,
      );

  // ── 페이지 이동 ─────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      if (_currentPage == 3) {
        _analytics.logEvent(name: 'onboarding_step_4');
      }
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    _analytics.logEvent(name: 'onboarding_completed');
    // 데이터는 메모리에 담아 Dashboard로 넘깁니다.
    // 실제 저장은 Phase 4 시뮬레이션 버튼 클릭 시 수행됩니다.
    Navigator.of(context).pushReplacementNamed(
      '/dashboard',
      arguments: _currentProfile,
    );
  }

  // ── 빌드 ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 3단계 스테퍼 + 질문 진행 바
            _OnboardingHeader(
              currentPage: _currentPage,
              totalPages: _totalPages,
              profile: _currentProfile,
            ),

            // 카드 PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),

            // 하단 네비게이션 버튼
            _BottomNav(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPrev: _prevPage,
              onNext: _nextPage,
            ),
          ],
        ),
      ),
    );
  }

  // ── 페이지 목록 구성 ────────────────────────────────────────

  List<Widget> _buildPages() {
    return [
      // Q1. 닉네임
      DiagnosisCard(
        questionNumber: 'Q1',
        question: '어떻게 불러드릴까요?',
        hint: '닉네임을 알려주시면 맞춤 알림을 보내드려요.',
        child: NicknameInput(
          initialValue: _nickname,
          onChanged: (v) => setState(() => _nickname = v),
        ),
      ),

      // Q2. 출생 연도
      DiagnosisCard(
        questionNumber: 'Q2',
        question: '태어난 연도가 어떻게 되시나요?',
        hint: '연령에 따라 안전 기준이 달라져요.',
        child: BirthYearPicker(
          initialYear: _birthYear,
          onChanged: (v) => setState(() => _birthYear = v),
        ),
      ),

      // Q3. 성별
      DiagnosisCard(
        questionNumber: 'Q3',
        question: '성별을 선택해 주세요.',
        hint: '일부 질문이 성별에 따라 달라져요.',
        child: GenderSelector(
          selected: _gender,
          onChanged: (v) => setState(() {
            _gender = v;
            // 남성 선택 시 임신 여부 초기화
            if (v == 'male') _isPregnant = false;
          }),
        ),
      ),

      // Q4. 기저질환 (호흡기)
      DiagnosisCard(
        questionNumber: 'Q4',
        question: '평소 호흡기가 얼마나 예민하신가요?',
        hint: '호흡기 상태에 따라 마스크 기준이 달라져요.',
        child: SingleChoiceSelector<int>(
          options: const [0, 1, 2],
          selected: _respiratoryStatus,
          labelOf: (v) => switch (v) {
            0 => '튼튼해요',
            1 => '비염이 있어요',
            _ => '천식 등 질환이 있어요',
          },
          onChanged: (v) => setState(() => _respiratoryStatus = v),
        ),
      ),

      // Q5. 체감 민감도
      DiagnosisCard(
        questionNumber: 'Q5',
        question: '공기가 나쁘면 바로 느껴지나요?',
        hint: '체감 예민도가 높을수록 기준선이 낮아져요.',
        child: SingleChoiceSelector<int>(
          options: const [0, 1, 2],
          selected: _sensitivityLevel,
          labelOf: (v) => switch (v) {
            0 => '잘 못 느껴요',
            1 => '보통이에요',
            _ => '바로 느껴요',
          },
          onChanged: (v) => setState(() => _sensitivityLevel = v),
        ),
      ),

      // Q6. 임신 여부 (여성 전용)
      if (_gender == 'female')
        DiagnosisCard(
          questionNumber: 'Q6',
          question: '현재 임신 중이신가요?',
          hint: '임신 중에는 안전 기준을 최우선으로 높여드려요.',
          child: SingleChoiceSelector<bool>(
            options: const [false, true],
            selected: _isPregnant,
            labelOf: (v) => v ? '예, 임신 중이에요' : '아니요',
            onChanged: (v) => setState(() => _isPregnant = v),
          ),
        ),

      // Q7. 피부 시술
      DiagnosisCard(
        questionNumber: _gender == 'female' ? 'Q7' : 'Q6',
        question: '최근 2주 내 피부 시술을 받으셨나요?',
        hint: '피부 시술 후에는 미세먼지에 더 취약할 수 있어요.',
        child: SingleChoiceSelector<bool>(
          options: const [false, true],
          selected: _recentSkinTreatment,
          labelOf: (v) => v ? '네, 받았어요' : '아니요',
          onChanged: (v) => setState(() => _recentSkinTreatment = v),
        ),
      ),

      // Q8. 야외 활동 시간
      DiagnosisCard(
        questionNumber: _gender == 'female' ? 'Q8' : 'Q7',
        question: '하루 야외에서 얼마나 보내시나요?',
        hint: '노출 시간이 길수록 기준선이 조정돼요.',
        child: SingleChoiceSelector<int>(
          options: const [0, 1, 2],
          selected: _outdoorMinutes,
          labelOf: (v) => switch (v) {
            0 => '30분 미만',
            1 => '1~3시간',
            _ => '3시간 이상',
          },
          onChanged: (v) => setState(() => _outdoorMinutes = v),
        ),
      ),

      // Q9. 활동 성격 (중복 선택)
      DiagnosisCard(
        questionNumber: _gender == 'female' ? 'Q9' : 'Q8',
        question: '주로 어떤 야외 활동을 하시나요?',
        hint: '해당하는 것을 모두 선택해 주세요.',
        child: MultiChoiceSelector(
          options: const [
            ActivityTag.commute,
            ActivityTag.walk,
            ActivityTag.exercise,
          ],
          selected: _activityTags,
          labelOf: ActivityTag.label,
          onChanged: (v) => setState(() => _activityTags = v),
        ),
      ),

      // Q10. 마스크 불편함
      DiagnosisCard(
        questionNumber: _gender == 'female' ? 'Q10' : 'Q9',
        question: '마스크가 많이 답답하신가요?',
        hint: '매우 답답하시다면 기준선을 살짝 완화해 드려요.',
        child: SingleChoiceSelector<int>(
          options: const [0, 1, 2],
          selected: _discomfortLevel,
          labelOf: (v) => switch (v) {
            0 => '괜찮아요',
            1 => '가끔 답답해요',
            _ => '매우 답답해요',
          },
          onChanged: (v) => setState(() => _discomfortLevel = v),
        ),
      ),
    ];
  }
}

// ── 상단 헤더 (스테퍼 + 진행 바 + 가중치 캡션) ──────────────

class _OnboardingHeader extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final UserProfile profile;

  const _OnboardingHeader({
    required this.currentPage,
    required this.totalPages,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          // 3단계 스테퍼
          const _PhaseStepperBar(activeStep: 0),
          const SizedBox(height: 14),

          // 질문 진행 바
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (currentPage + 1) / totalPages,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.splashBackground),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 5,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${currentPage + 1} / $totalPages',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 실시간 가중치 캡션
          _WeightCaption(profile: profile),
        ],
      ),
    );
  }
}

/// 3단계 [진단 — 분석 — 세팅] 스테퍼
class _PhaseStepperBar extends StatelessWidget {
  final int activeStep; // 0: 진단, 1: 분석, 2: 세팅

  const _PhaseStepperBar({required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['진단', '분석', '세팅'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // 연결선
          return Expanded(
            child: Container(
              height: 1.5,
              color: i ~/ 2 < activeStep
                  ? AppColors.splashBackground
                  : AppColors.divider,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex == activeStep;
        final isDone = stepIndex < activeStep;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.splashBackground
                    : isDone
                        ? AppColors.splashBackground.withOpacity(0.4)
                        : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                color: isActive
                    ? AppColors.splashBackground
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// 실시간 가중치 캡션
class _WeightCaption extends StatelessWidget {
  final UserProfile profile;

  const _WeightCaption({required this.profile});

  @override
  Widget build(BuildContext context) {
    final s = profile.sensitivityIndex;
    final t = profile.tFinal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.splashBackground.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 13,
            color: AppColors.splashBackground,
          ),
          const SizedBox(width: 6),
          Text(
            '${profile.nickname.isNotEmpty ? "${profile.nickname}님의 " : ""}기준선 업데이트 중 · '
            '${t.toStringAsFixed(1)} μg/m³',
            style: const TextStyle(
              color: AppColors.splashBackground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 네비게이션 버튼 ──────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _BottomNav({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          if (currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onPrev,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast
                    ? AppColors.splashBackground
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isLast ? '분석하기 →' : '다음',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
