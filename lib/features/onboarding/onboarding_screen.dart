import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import 'diagnosis_cards.dart';

final _analytics = FirebaseAnalytics.instance;

/// 온보딩 — Q1~Q8 카드 PageView
///
/// Q1 닉네임       Q4 호흡기 (비염/천식/COPD/알레르기)
/// Q2 출생연도      Q5 심혈관 (고혈압/심장/뇌졸중)
/// Q3 성별          Q6 흡연 (필수)  Q6-1 흡연 종류 (현재 흡연만)
///                  Q7 임신 (female/미선택만)  Q8 마스크 불편도
///
/// 총: 9단계(female+현재흡연) / 8단계(female비흡연 or male+현재흡연) / 7단계(male비흡연)
/// 완료 → analysis_loading_screen → dashboard
class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isRediag;
  const OnboardingScreen({super.key, this.isRediag = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Q1: 닉네임 ───────────────────────────────────────────────
  String? _nickname;

  // ── Q2: 출생연도 ─────────────────────────────────────────────
  int? _birthYear;
  bool _birthYearEdited = false; // 사용자가 picker를 한 번이라도 조작했는지

  // ── Q3: 성별 ─────────────────────────────────────────────────
  String? _genderStr; // 'male'|'female'|null

  // ── Q4: 호흡기 ──────────────────────────────────────────────
  bool _hasRhinitis         = false;
  bool _hasAsthma           = false;
  bool _hasCopd             = false;
  bool _hasAllergy          = false;
  bool _hasNoneRespiratory  = true; // 초기값: "없어요" 선택

  // ── Q5: 심혈관 ──────────────────────────────────────────────
  bool _hasHypertension     = false;
  bool _hasHeartDisease     = false;
  bool _hasStroke           = false;
  bool _hasNoneCardiovascular = true; // 초기값: "없어요" 선택

  // ── Q6: 흡연 ────────────────────────────────────────────────
  SmokingStatus? _smokingStatusChoice; // null = 아직 미선택

  // ── Q6-1: 흡연 종류 (현재 흡연 중인 경우만) ─────────────────
  bool _smokesCigarette = false;
  bool _smokesHeated    = false;
  bool _smokesVaping    = false;

  // ── Q8: 마스크 불편도 ───────────────────────────────────────
  int _discomfortLevel = 1;

  // ── 저장 중 상태 (중복 탭 방지) ─────────────────────────────
  bool _saving = false;

  // ── 동적 페이지 조건 ─────────────────────────────────────────

  /// Q6-1(흡연 종류) 포함 여부 — 현재 흡연 중인 경우만
  bool get _includeSmokingType =>
      _smokingStatusChoice == SmokingStatus.current;

  /// 전체 페이지 수 (조건부 페이지 반영)
  int get _totalPages {
    int n = 7; // Q1~Q6 + Q8(불편도) 고정
    if (_includeSmokingType) n++;
    return n;
  }

  /// 실제 렌더할 페이지 위젯 목록
  List<Widget> get _pages => [
        // ── 기본 ───────────────────────────────────────────
        DiagQ1Nickname(
          questionNumber: 1,
          initialValue: _nickname,
          onChanged: (v) => setState(() => _nickname = v),
        ),
        DiagQ2BirthYear(
          questionNumber: 2,
          initialValue: _birthYear,
          onChanged: (v) => setState(() {
            _birthYear = v;
            _birthYearEdited = true;
          }),
        ),
        DiagQ3Gender(
          questionNumber: 3,
          value: _genderStr,
          onChanged: (v) => setState(() => _genderStr = v),
        ),

        // ── Q4: 호흡기 (다중 체크박스) ──────────────────────
        DiagQ4Respiratory(
          questionNumber: 4,
          rhinitis:     _hasRhinitis,
          asthma:       _hasAsthma,
          copd:         _hasCopd,
          allergy:      _hasAllergy,
          noneSelected: _hasNoneRespiratory,
          onChanged: (r, a, c, al, none) => setState(() {
            _hasRhinitis         = r;
            _hasAsthma           = a;
            _hasCopd             = c;
            _hasAllergy          = al;
            _hasNoneRespiratory  = none;
          }),
        ),

        // ── Q5: 심혈관 (다중 체크박스) ──────────────────────
        DiagQ5Cardiovascular(
          questionNumber: 5,
          hypertension: _hasHypertension,
          heartDisease: _hasHeartDisease,
          stroke:       _hasStroke,
          noneSelected: _hasNoneCardiovascular,
          onChanged: (h, hd, s, none) => setState(() {
            _hasHypertension       = h;
            _hasHeartDisease       = hd;
            _hasStroke             = s;
            _hasNoneCardiovascular = none;
          }),
        ),

        // ── Q6: 흡연 이력 (라디오) ─────────────────────────
        DiagQ6Smoking(
          questionNumber: 6,
          value: _smokingStatusChoice,
          onChanged: (v) => setState(() {
            _smokingStatusChoice = v;
            // 비흡연/금연으로 변경 시 흡연 종류 초기화
            if (v != SmokingStatus.current) {
              _smokesCigarette = false;
              _smokesHeated    = false;
              _smokesVaping    = false;
            }
          }),
        ),

        // ── Q6-1: 흡연 종류 (현재 흡연 중인 경우만) ────────
        if (_includeSmokingType)
          DiagQ6_1SmokingType(
            questionNumber: 7,
            cigarette: _smokesCigarette,
            heated:    _smokesHeated,
            vaping:    _smokesVaping,
            onChanged: (c, h, v) => setState(() {
              _smokesCigarette = c;
              _smokesHeated    = h;
              _smokesVaping    = v;
            }),
          ),

        // ── Q8: 마스크 불편도 ───────────────────────────────
        DiagQ10Discomfort(
          questionNumber: _totalPages,
          value: _discomfortLevel,
          onChanged: (v) => setState(() => _discomfortLevel = v),
        ),
      ];

  // ── 라이프사이클 ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _analytics.logEvent(name: 'onboarding_start');

    if (widget.isRediag) {
      // 기존 프로필 데이터 미리 채우기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profile = ref.read(profileProvider);
        setState(() {
          _nickname        = profile.nickname;
          _birthYear       = profile.birthYear;
          _birthYearEdited = true;
          _genderStr       = profile.gender.isNotEmpty ? profile.gender : null;
          _hasRhinitis     = profile.rhinitis;
          _hasAsthma       = profile.asthma;
          _hasCopd         = profile.copd;
          _hasAllergy      = profile.allergy;
          _hasNoneRespiratory =
              !(_hasRhinitis || _hasAsthma || _hasCopd || _hasAllergy);
          _hasHypertension   = profile.hypertension;
          _hasHeartDisease   = profile.heartDisease;
          _hasStroke         = profile.stroke;
          _hasNoneCardiovascular =
              !(_hasHypertension || _hasHeartDisease || _hasStroke);
          _smokingStatusChoice = profile.smokingStatus;
          _smokesCigarette     = profile.smokesCigarette;
          _smokesHeated        = profile.smokesHeated;
          _smokesVaping        = profile.smokesVaping;
          _discomfortLevel     = profile.discomfortLevel;
          // Q3(성별)부터 시작
          _currentPage = 2;
        });
        _pageController.jumpToPage(2);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── 네비게이션 ───────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      _analytics.logEvent(name: 'onboarding_q${_currentPage + 1}');
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_saving) return;
    setState(() => _saving = true);

    final profile = _buildProfile();
    bool saved = false;

    try {
      await ref.read(profileProvider.notifier).saveProfile(profile);
      await ref.read(profileRepositoryProvider).completeOnboarding();
      await ref.read(profileRepositoryProvider).completeTutorial();
      saved = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장 중 오류가 발생했어요. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _saving = false);
    if (!saved) return; // 저장 실패 시 이동하지 않음

    await _analytics.logEvent(name: 'onboarding_completed');

    if (mounted) {
      if (widget.isRediag) {
        context.go('/diagnosis_result', extra: {'rediag': true});
      } else {
        context.go('/analysis_loading');
      }
    }
  }

  Future<void> _skipOnboarding() async {
    if (_saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
        title: const Text('지금 건너뛰시겠어요?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text(
          '이후 질문들을 모두 건너뜁니다.\n'
          '입력하지 않은 항목은 일반 기준으로 설정되며,\n'
          '나중에 \'내 몸 정보\'에서 언제든 수정할 수 있어요.\n\n'
          '※ 진단 정확도가 낮아질 수 있어요.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('계속 진행'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _saving = true);

    await _analytics.logEvent(name: 'onboarding_skipped');
    bool saved = false;

    try {
      await ref.read(profileProvider.notifier).saveProfile(_buildProfile());
      await ref.read(profileRepositoryProvider).completeOnboarding();
      await ref.read(profileRepositoryProvider).completeTutorial();
      saved = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장 중 오류가 발생했어요. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _saving = false);
    if (!saved) return;

    if (mounted) {
      context.go('/location_setup',
          extra: true);
    }
  }

  // ── 프로필 조립 ──────────────────────────────────────────────

  UserProfile _buildProfile() => UserProfile(
        nickname:        _nickname ?? '',
        birthYear:       _birthYear ?? 1990,
        gender:          _genderStr ?? '',
        rhinitis:        _hasRhinitis,
        asthma:          _hasAsthma,
        copd:            _hasCopd,
        allergy:         _hasAllergy,
        hypertension:    _hasHypertension,
        heartDisease:    _hasHeartDisease,
        stroke:          _hasStroke,
        smokingStatus:   _smokingStatusChoice ?? SmokingStatus.never,
        smokesCigarette: _smokesCigarette,
        smokesHeated:    _smokesHeated,
        smokesVaping:    _smokesVaping,
        activityTags:    const [],
        discomfortLevel: _discomfortLevel,
        homeStationName:  '',
        officeStationName: '',
      );

  // ── 빌드 ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = _pages; // getter 한 번만 호출

    return PopScope(
      canPop: false, // 항상 직접 처리 — Q1에서 뒤로가기 차단, Q2+에서는 이전 질문으로
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) _prevPage();
      },
      child: Scaffold(
      backgroundColor: AppColors.bgOnboarding,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 진행 표시 ─────────────────────────────────
            OnboardingProgressRow(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onBack: _prevPage,
              onSkip: _skipOnboarding,
              isRediag: widget.isRediag,
            ),

            // ── PageView ───────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),

            // ── 다음 버튼 ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.screenH, 8, AppTokens.screenH, 24),
              child: AppButton.primary(
                label: _currentPage == _totalPages - 1 ? '분석 시작하기  →' : '다음',
                onTap: (_saving ||
                        (_currentPage == 0 && !(_nickname?.trim().isNotEmpty ?? false)) ||
                        (_currentPage == 1 && !_birthYearEdited) ||
                        // Q3(성별): 반드시 선택
                        (_currentPage == 2 && (_genderStr == null || _genderStr!.isEmpty)) ||
                        // Q4(호흡기): 최소 1개 선택 또는 "없어요"
                        (_currentPage == 3 && !_hasRhinitis && !_hasAsthma && !_hasCopd && !_hasAllergy && !_hasNoneRespiratory) ||
                        // Q5(심혈관): 최소 1개 선택 또는 "없어요"
                        (_currentPage == 4 && !_hasHypertension && !_hasHeartDisease && !_hasStroke && !_hasNoneCardiovascular) ||
                        // Q6(흡연): 반드시 선택
                        (_currentPage == 5 && _smokingStatusChoice == null) ||
                        // Q6-1(흡연 종류): 현재 흡연 중인 경우 최소 1개 선택
                        (_currentPage == 6 && _includeSmokingType &&
                            !_smokesCigarette && !_smokesHeated && !_smokesVaping))
                    ? null
                    : _nextPage,
                isLoading: _saving,
              ),
            ),
          ],
        ),
      ),
    ),   // Scaffold
    );   // PopScope
  }
}

// ── 진행 표시 Row ─────────────────────────────────────────────
//
// 조건부 규칙:
//   뒤로 버튼  : page > 0
//   카운터     : page 0~2 → "Q1"/"Q2"/"Q3" 라벨, page >= 3 → "X/Y"
//   건너뛰기   : page >= 2  (Q3+, Q1·Q2 는 진단 핵심 정보)

class OnboardingProgressRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final bool isRediag;

  const OnboardingProgressRow({
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    required this.onSkip,
    this.isRediag = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (currentPage > 0) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalPages,
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            currentPage < 3
                ? 'Q${currentPage + 1}'
                : '${currentPage + 1} / $totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (currentPage >= 2 && !isRediag)
            GestureDetector(
              onTap: onSkip,
              child: const Text(
                '(선택 항목) 건너뛰기',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
