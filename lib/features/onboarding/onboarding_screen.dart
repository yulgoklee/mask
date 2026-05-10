import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/constants/feature_flags.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import 'diagnosis_cards.dart';
import 'widgets/onboarding_background.dart';

final _analytics = FirebaseAnalytics.instance;

/// 온보딩 — 기본정보 + Q4~Q6 카드 PageView
///
/// index 0: 기본정보 (이름·출생연도·성별 통합)
/// index 1: Q4 호흡기
/// index 2: Q5 심혈관
/// (조건부) Q5.5 잠재 신호 자가 점검 — Flag ON 시
/// (필수)   Q6 흡연
/// (조건부) Q6-1 흡연 종류 — 현재 흡연 중인 경우만
///
/// 총: 4단계(Flag·종류 모두 OFF) ~ 6단계(둘 다 ON)
/// 완료 → analysis_loading_screen → diagnosis_result
class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isRediag;
  const OnboardingScreen({super.key, this.isRediag = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── 기본정보 (index 0) ───────────────────────────────────────
  String? _nickname;
  int? _birthYear;
  String? _genderStr; // 'male'|'female'|null

  // ── Q4: 호흡기 ──────────────────────────────────────────────
  bool _hasRhinitis         = false;
  bool _hasAsthma           = false;
  bool _hasCopd             = false;
  bool _hasAllergy          = false;
  bool _hasNoneRespiratory  = true; // 초기값: "없어요" 선택

  // ── Q5: 심혈관 ──────────────────────────────────────────────
  bool _hasHypertension       = false;
  bool _hasHeartDisease       = false;
  bool _hasStroke             = false;
  bool _hasNoneCardiovascular = true; // 초기값: "없어요" 선택

  // ── Q5.5: 잠재 신호 자가 점검 (Flag ON 시만, 선택) ──────────
  Map<String, bool> _signalAnswers = const {};

  // ── Q6: 흡연 ────────────────────────────────────────────────
  SmokingStatus? _smokingStatusChoice; // null = 아직 미선택

  // ── Q6-1: 흡연 종류 (현재 흡연 중인 경우만) ─────────────────
  bool _smokesCigarette = false;
  bool _smokesHeated    = false;
  bool _smokesVaping    = false;

  // ── 저장 중 상태 (중복 탭 방지) ─────────────────────────────
  bool _saving = false;

  // ── 동적 페이지 조건 ─────────────────────────────────────────

  /// Q5.5(신호 자가 점검) 포함 여부 — Feature Flag ON 시
  bool get _includeSignalSelfCheck => FeatureFlags.kEnableSignalSelfCheck;

  /// Q6-1(흡연 종류) 포함 여부 — 현재 흡연 중인 경우만
  bool get _includeSmokingType =>
      _smokingStatusChoice == SmokingStatus.current;

  /// 전체 페이지 수 (조건부 페이지 반영)
  /// 기본정보(1) + Q4(1) + Q5(1) + [Q5.5] + Q6(1) + [Q6-1]
  int get _totalPages {
    int n = 4; // 기본정보·Q4·Q5·Q6 고정
    if (_includeSignalSelfCheck) n++;
    if (_includeSmokingType) n++;
    return n;
  }

  /// Q6(흡연) 페이지 인덱스
  int get _smokingPageIndex => _includeSignalSelfCheck ? 4 : 3;

  /// 단계명 목록 (OnboardingProgressRow 표시용)
  List<String> get _stageNames {
    final names = ['기본정보', '호흡기', '심혈관'];
    if (_includeSignalSelfCheck) names.add('자가점검');
    names.add('흡연');
    if (_includeSmokingType) names.add('흡연 종류');
    return names;
  }

  /// 실제 렌더할 페이지 위젯 목록
  List<Widget> get _pages => [
        // ── index 0: 기본정보 (Q1·Q2·Q3 통합) ─────────────────
        DiagBasicInfo(
          nickname:          _nickname,
          birthYear:         _birthYear,
          gender:            _genderStr,
          onNicknameChanged: (v) => setState(() => _nickname = v),
          onBirthYearChanged:(v) => setState(() => _birthYear = v),
          onGenderChanged:   (v) => setState(() => _genderStr = v),
        ),

        // ── index 1: Q4 호흡기 ──────────────────────────────────
        DiagQ4Respiratory(
          questionNumber: 4,
          rhinitis:     _hasRhinitis,
          asthma:       _hasAsthma,
          copd:         _hasCopd,
          allergy:      _hasAllergy,
          noneSelected: _hasNoneRespiratory,
          onChanged: (r, a, c, al, none) => setState(() {
            _hasRhinitis        = r;
            _hasAsthma          = a;
            _hasCopd            = c;
            _hasAllergy         = al;
            _hasNoneRespiratory = none;
          }),
        ),

        // ── index 2: Q5 심혈관 ──────────────────────────────────
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

        // ── (조건부) Q5.5 자가 점검 ─────────────────────────────
        if (_includeSignalSelfCheck)
          DiagSignalSelfCheck(
            questionNumber: 6,
            answers: _signalAnswers,
            onChanged: (m) => setState(() => _signalAnswers = m),
          ),

        // ── Q6: 흡연 이력 ────────────────────────────────────────
        DiagQ6Smoking(
          questionNumber: _includeSignalSelfCheck ? 7 : 6,
          value: _smokingStatusChoice,
          onChanged: (v) => setState(() {
            _smokingStatusChoice = v;
            if (v != SmokingStatus.current) {
              _smokesCigarette = false;
              _smokesHeated    = false;
              _smokesVaping    = false;
            }
          }),
        ),

        // ── (조건부) Q6-1 흡연 종류 ─────────────────────────────
        if (_includeSmokingType)
          DiagQ6p1SmokingType(
            questionNumber: _includeSignalSelfCheck ? 8 : 7,
            cigarette: _smokesCigarette,
            heated:    _smokesHeated,
            vaping:    _smokesVaping,
            onChanged: (c, h, v) => setState(() {
              _smokesCigarette = c;
              _smokesHeated    = h;
              _smokesVaping    = v;
            }),
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
          _signalAnswers = FeatureFlags.kEnableSignalSelfCheck
              ? Map<String, bool>.from(profile.signalAnswers)
              : const {};
          // 재진단: 기본정보부터 시작 (편집 가능하게)
          _currentPage = 0;
        });
        _pageController.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── 다음 버튼 활성화 여부 ────────────────────────────────────

  bool get _isNextDisabled {
    if (_saving) return true;
    switch (_currentPage) {
      case 0:
        // 기본정보: 이름·출생연도·성별 모두 필수
        return !(_nickname != null && _nickname!.trim().isNotEmpty) ||
            _birthYear == null ||
            _genderStr == null;
      case 1:
        // Q4 호흡기: 최소 1개 선택 또는 "없어요"
        return !_hasRhinitis &&
            !_hasAsthma &&
            !_hasCopd &&
            !_hasAllergy &&
            !_hasNoneRespiratory;
      case 2:
        // Q5 심혈관: 최소 1개 선택 또는 "없어요"
        return !_hasHypertension &&
            !_hasHeartDisease &&
            !_hasStroke &&
            !_hasNoneCardiovascular;
      default:
        // Q5.5(자가 점검): 항상 통과
        if (_includeSignalSelfCheck && _currentPage == 3) return false;
        // Q6(흡연): 반드시 선택
        if (_currentPage == _smokingPageIndex) {
          return _smokingStatusChoice == null;
        }
        // Q6-1(흡연 종류): 1개 이상 선택
        if (_currentPage == _smokingPageIndex + 1 && _includeSmokingType) {
          return !_smokesCigarette && !_smokesHeated && !_smokesVaping;
        }
        return false;
    }
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
    // 재진단 모드에서 기본정보(index 0) 이하로는 뒤로 이동 불가
    if (widget.isRediag && _currentPage <= 0) return;
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _cancelRediag() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
        title: const Text('재진단을 취소하시겠어요?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          '입력한 내용은 저장되지 않아요.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 진행',
                style: TextStyle(color: DT.gray)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DT.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.go('/profile');
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
    if (!saved) return;

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
                style: TextStyle(color: DT.gray)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DT.danger,
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
      context.go('/location_setup', extra: true);
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
        homeStationName:   '',
        officeStationName: '',
        signalAnswers: FeatureFlags.kEnableSignalSelfCheck
            ? Map<String, bool>.unmodifiable(_signalAnswers)
            : const {},
      );

  // ── 빌드 ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = _pages; // getter 한 번만 호출

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // 재진단 모드에서 기본정보(index 0)에서 시스템 뒤로가기 차단
        if (widget.isRediag && _currentPage <= 0) return;
        if (_currentPage > 0) _prevPage();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: OnboardingBackground(
          child: SafeArea(
            child: Column(
              children: [
                // ── 상단 진행 표시 ───────────────────────────────
                OnboardingProgressRow(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  stageName: _stageNames.length > _currentPage
                      ? _stageNames[_currentPage]
                      : '',
                  onBack: _prevPage,
                  onSkip: _skipOnboarding,
                  isRediag: widget.isRediag,
                  onCancel: widget.isRediag ? _cancelRediag : null,
                ),

                // ── PageView ─────────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: pages,
                  ),
                ),

                // ── 다음 버튼 ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenH, 8, AppTokens.screenH, 24),
                  child: AppButton.primary(
                    label: _currentPage == _totalPages - 1
                        ? '분석 시작하기  →'
                        : '다음',
                    onTap: _isNextDisabled ? null : _nextPage,
                    isLoading: _saving,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 진행 표시 Row ─────────────────────────────────────────────
//
// 조건부 규칙:
//   뒤로 버튼  : page > 0
//   진행 바    : LinearProgressIndicator (value = (page+1)/total)
//   단계명     : _stageNames[currentPage] (예: "기본정보", "호흡기" 등)
//   건너뛰기   : page >= 1 (기본정보 다음부터)

class OnboardingProgressRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String stageName;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final bool isRediag;
  final VoidCallback? onCancel;

  const OnboardingProgressRow({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.stageName,
    required this.onBack,
    required this.onSkip,
    this.isRediag = false,
    this.onCancel,
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
                  color: DT.grayLt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 15,
                  color: DT.gray,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalPages,
                backgroundColor: DT.border,
                color: DT.primary,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            stageName,
            style: const TextStyle(
              fontSize: 12,
              color: DT.gray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (isRediag)
            GestureDetector(
              onTap: onCancel,
              child: const Text(
                '취소',
                style: TextStyle(fontSize: 13, color: DT.gray),
              ),
            )
          else if (currentPage >= 1)
            GestureDetector(
              onTap: onSkip,
              child: const Text(
                '(선택 항목) 건너뛰기',
                style: TextStyle(fontSize: 13, color: DT.gray),
              ),
            ),
        ],
      ),
    );
  }
}
