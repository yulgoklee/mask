import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import 'diagnosis_cards.dart';

final _analytics = FirebaseAnalytics.instance;

/// Phase 2 온보딩 — Q1~Q10 카드 PageView
///
///  Q1  닉네임          Q6  임신 여부 (female/미선택만, male 완전 제외)
///  Q2  출생연도         Q7  피부 시술
///  Q3  성별             Q8  야외 활동량
///  Q4  호흡기 상태      Q9  활동 태그
///  Q5  체감 민감도      Q10 마스크 불편도
///
///  완료 → analysis_loading_screen → dashboard
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

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

  // ── Q3: 성별 ─────────────────────────────────────────────────
  String? _genderStr; // 'male'|'female'|null

  // ── Q4: 호흡기 ───────────────────────────────────────────────
  int _respiratoryStatus = 0;

  // ── Q5: 민감도 ───────────────────────────────────────────────
  int _sensitivityLevel = 1;

  // ── Q6: 임신 (female/미선택만 유효, male이면 페이지 자체 제외) ──
  bool _isPregnant = false;

  // ── Q7: 피부 시술 ────────────────────────────────────────────
  bool _recentSkinTreatment = false;

  // ── Q8: 야외 활동량 ──────────────────────────────────────────
  int _outdoorMinutes = 1;

  // ── Q9: 활동 태그 ────────────────────────────────────────────
  List<String> _activityTags = const [];

  // ── Q10: 마스크 불편도 ───────────────────────────────────────
  int _discomfortLevel = 1;

  // ── 동적 페이지 목록 ─────────────────────────────────────────
  //  Q6는 female 또는 성별 미선택 시만 포함
  //  male 선택 시 Q6 완전 제거 → 9페이지
  //  gender 변경 시 _currentPage <= 2 이므로 인덱스 안전

  /// Q6 포함 여부 — male이면 완전 제외
  bool get _includeQ6 => _genderStr != 'male';

  /// 실제 렌더할 페이지 위젯 목록
  List<Widget> get _pages => [
        DiagQ1Nickname(
          initialValue: _nickname,
          onChanged: (v) => setState(() => _nickname = v),
        ),
        DiagQ2BirthYear(
          initialValue: _birthYear,
          onChanged: (v) => setState(() => _birthYear = v),
        ),
        DiagQ3Gender(
          value: _genderStr,
          onChanged: (v) => setState(() {
            _genderStr = v;
            // 남성 선택 시 임신 상태 해제
            if (v == 'male') _isPregnant = false;
          }),
        ),
        DiagQ4Respiratory(
          value: _respiratoryStatus,
          onChanged: (v) => setState(() => _respiratoryStatus = v),
        ),
        DiagQ5Sensitivity(
          value: _sensitivityLevel,
          onChanged: (v) => setState(() => _sensitivityLevel = v),
        ),
        // Q6: male이 아닐 때만 포함 (남성 선택 시 페이지 자체가 사라짐)
        if (_includeQ6)
          DiagQ6Pregnancy(
            value: _isPregnant,
            genderStr: _genderStr,
            onChanged: (v) => setState(() => _isPregnant = v),
          ),
        DiagQ7SkinTreatment(
          value: _recentSkinTreatment,
          onChanged: (v) => setState(() => _recentSkinTreatment = v),
        ),
        DiagQ8Outdoor(
          value: _outdoorMinutes,
          onChanged: (v) => setState(() => _outdoorMinutes = v),
        ),
        DiagQ9ActivityTags(
          value: _activityTags,
          onChanged: (v) => setState(() => _activityTags = v),
        ),
        DiagQ10Discomfort(
          value: _discomfortLevel,
          onChanged: (v) => setState(() => _discomfortLevel = v),
        ),
      ];

  /// 전체 페이지 수 (male: 9, 그 외: 10)
  int get _totalPages => _pages.length;

  // ── 라이프사이클 ─────────────────────────────────────────────

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
    final profile = _buildProfile();

    try {
      // 프로필만 저장 — completeOnboarding()은 notification_time_screen에서 호출
      await ref.read(profileProvider.notifier).saveProfile(profile);
    } catch (_) {
      // 저장 실패해도 다음 화면으로 진행
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

  UserProfile _buildProfile() => UserProfile(
        nickname:            _nickname ?? '',
        birthYear:           _birthYear ?? 1990,
        gender:              _genderStr ?? 'male',
        respiratoryStatus:   _respiratoryStatus,
        sensitivityLevel:    _sensitivityLevel,
        isPregnant:          _isPregnant,
        recentSkinTreatment: _recentSkinTreatment,
        outdoorMinutes:      _outdoorMinutes,
        activityTags:        _activityTags,
        discomfortLevel:     _discomfortLevel,
      );

  // ── 빌드 ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = _pages; // getter 한 번만 호출

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 진행 표시 ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 뒤로 버튼 (첫 페이지 제외)
                  if (_currentPage > 0) ...[
                    GestureDetector(
                      onTap: _prevPage,
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
                  // 진행 바
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 페이지 카운터
                  Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 나중에
                  GestureDetector(
                    onTap: _skipOnboarding,
                    child: const Text(
                      '나중에',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? '분석 시작하기  →'
                        : '다음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
