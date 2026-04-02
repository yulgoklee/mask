import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import 'step_age.dart';
import 'step_condition.dart';
import 'step_severity.dart';
import 'step_lifestyle.dart';
import 'step_notification.dart';

final _analytics = FirebaseAnalytics.instance;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 온보딩 중 수집하는 임시 프로필 데이터
  AgeGroup _ageGroup = AgeGroup.thirties;
  bool _hasCondition = false;
  ConditionType _conditionType = ConditionType.none;
  Severity _severity = Severity.mild;
  bool _isDiagnosed = false;
  ActivityLevel _activityLevel = ActivityLevel.normal;

  int get _totalPages => _hasCondition ? 5 : 4;

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

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
        if (_currentPage == 2) {
          _analytics.logEvent(name: 'onboarding_step_3');
        }
      });
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
    final profile = UserProfile(
      ageGroup: _ageGroup,
      hasCondition: _hasCondition,
      conditionType: _conditionType,
      severity: _severity,
      isDiagnosed: _isDiagnosed,
      activityLevel: _activityLevel,
    );

    await ref.read(profileProvider.notifier).saveProfile(profile);
    await ref.read(profileRepositoryProvider).completeOnboarding();
    await _analytics.logEvent(name: 'onboarding_completed');

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/location_setup');
    }
  }

  Future<void> _skipOnboarding() async {
    await _analytics.logEvent(name: 'onboarding_skipped');
    await ref.read(profileRepositoryProvider).completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/location_setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 진행 바 + 건너뛰기
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: AppColors.divider,
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      '나중에',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // 페이지
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('이전'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1 ? '시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  List<Widget> _buildPages() {
    final pages = <Widget>[
      // 1. 나이
      StepAge(
        selected: _ageGroup,
        onChanged: (v) => setState(() => _ageGroup = v),
      ),
      // 2. 기저질환 여부
      StepCondition(
        hasCondition: _hasCondition,
        conditionType: _conditionType,
        onConditionChanged: (v) => setState(() {
          _hasCondition = v;
          if (!v) _conditionType = ConditionType.none;
        }),
        onTypeChanged: (v) => setState(() => _conditionType = v),
      ),
    ];

    // 3. 질환 수준 (기저질환이 있을 경우만)
    if (_hasCondition) {
      pages.add(
        StepSeverity(
          severity: _severity,
          isDiagnosed: _isDiagnosed,
          onSeverityChanged: (v) => setState(() => _severity = v),
          onDiagnosedChanged: (v) => setState(() => _isDiagnosed = v),
        ),
      );
    }

    // 4. 야외 활동 빈도
    pages.add(
      StepLifestyle(
        activityLevel: _activityLevel,
        onChanged: (v) => setState(() => _activityLevel = v),
      ),
    );

    // 5. 알림 설정
    pages.add(const StepNotification());

    return pages;
  }
}
