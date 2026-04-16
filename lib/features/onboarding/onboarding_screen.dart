import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import 'step_basic_info.dart';
import 'step_body_sensitivity.dart';
import 'step_special_state.dart';
import 'step_lifestyle.dart';

final _analytics = FirebaseAnalytics.instance;

/// Phase 1 온보딩 — 4단계 흐름 (v2 UserProfile 기반)
///
///  1. 기본 정보    (이름 · 출생연도 · 성별)
///  2. 신체 민감도  (호흡기 상태 + 체감 민감도)
///  3. 특별 상태    (임신 · 피부 시술)
///  4. 생활 환경    (야외 활동량 + 마스크 불편 정도)
///
///  완료 → analysis_loading_screen → onboarding_result
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  // ── 1단계: 기본 정보 ────────────────────────────────────────
  String? _name;
  int? _birthYear;
  // gender는 String 으로 관리 ('male'|'female'|'other'|null)
  String? _genderStr;

  // ── 2단계: 신체 민감도 ──────────────────────────────────────
  int _respiratoryStatus = 0;  // 0=건강 1=비염 2=천식등
  int _sensitivityLevel  = 1;  // 0=무던 1=보통 2=예민

  // ── 3단계: 특별 상태 ────────────────────────────────────────
  bool _isPregnant         = false;
  bool _recentSkinTreatment = false;

  // ── 4단계: 생활 환경 ────────────────────────────────────────
  int  _outdoorMinutes   = 1;  // 0=1h미만 1=1~3h 2=3h이상
  int  _discomfortLevel  = 1;  // 0=안느낌 1=보통 2=많이불편

  // ── 네비게이션 ───────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _analytics.logEvent(name: 'onboarding_start');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      _analytics.logEvent(
          name: 'onboarding_step_${_currentPage + 1}');
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
    final profile = _buildProfile();

    try {
      await ref.read(profileProvider.notifier).saveProfile(profile);
      await ref.read(profileRepositoryProvider).completeOnboarding();
    } catch (_) {
      // 저장 실패해도 분석 화면으로 진행
    }

    await _analytics.logEvent(name: 'onboarding_completed');

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/analysis_loading');
    }
  }

  Future<void> _skipOnboarding() async {
    await _analytics.logEvent(name: 'onboarding_skipped');

    try {
      await ref.read(profileRepositoryProvider).completeOnboarding();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/location_setup');
    }
  }

  // ── 프로필 조립 ──────────────────────────────────────────────

  UserProfile _buildProfile() {
    return UserProfile(
      nickname:            _name ?? '',
      birthYear:           _birthYear ?? 1990,
      gender:              _genderStr ?? 'male',
      respiratoryStatus:   _respiratoryStatus,
      sensitivityLevel:    _sensitivityLevel,
      isPregnant:          _isPregnant,
      recentSkinTreatment: _recentSkinTreatment,
      outdoorMinutes:      _outdoorMinutes,
      activityTags:        const [],
      discomfortLevel:     _discomfortLevel,
    );
  }

  // ── 빌드 ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 진행 바 ───────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      '나중에',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── 페이지 콘텐츠 ──────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildPages(),
              ),
            ),

            // ── 하단 버튼 ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side:
                              const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentPage == _totalPages - 1
                              ? '분석 시작하기 →'
                              : '다음',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() => [
        // 1단계 — 기본 정보
        StepBasicInfo(
          initialName: _name,
          initialBirthYear: _birthYear,
          initialGenderStr: _genderStr,
          onNameChanged: (v) => setState(() => _name = v),
          onBirthYearChanged: (v) => setState(() => _birthYear = v),
          onGenderStrChanged: (v) => setState(() {
            _genderStr = v;
            // 성별 변경 시 임신 초기화 (여성 아닌 경우)
            if (v != 'female') _isPregnant = false;
          }),
        ),

        // 2단계 — 신체 민감도
        StepBodySensitivity(
          respiratoryStatus: _respiratoryStatus,
          sensitivityLevel: _sensitivityLevel,
          onRespiratoryChanged: (v) => setState(() => _respiratoryStatus = v),
          onSensitivityChanged: (v) => setState(() => _sensitivityLevel = v),
        ),

        // 3단계 — 특별 상태
        StepSpecialState(
          isPregnant: _isPregnant,
          recentSkinTreatment: _recentSkinTreatment,
          genderStr: _genderStr,
          onPregnantChanged: (v) => setState(() => _isPregnant = v),
          onSkinTreatmentChanged: (v) =>
              setState(() => _recentSkinTreatment = v),
        ),

        // 4단계 — 생활 환경
        StepLifestyle(
          outdoorMinutes: _outdoorMinutes,
          discomfortLevel: _discomfortLevel,
          onOutdoorChanged: (v) => setState(() => _outdoorMinutes = v),
          onDiscomfortChanged: (v) => setState(() => _discomfortLevel = v),
        ),
      ];
}
