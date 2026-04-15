import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import 'step_name.dart';
import 'step_gender.dart';
import 'step_age.dart';
import 'step_condition.dart';
import 'step_severity.dart';
import 'step_lifestyle.dart';
import 'step_sensitivity.dart';

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
  String? _name;
  Gender? _gender;           // Step 2 — 성별 (선택)
  AgeGroup _ageGroup = AgeGroup.thirties;
  bool _hasCondition = false;
  ConditionType _conditionType = ConditionType.none;
  Severity _severity = Severity.mild;
  bool _isDiagnosed = false;
  ActivityLevel _activityLevel = ActivityLevel.normal;
  SensitivityLevel _sensitivity = SensitivityLevel.normal;

  // 이름(1) + 성별(1) + 나이(1) + 질환(1) + [수준(1)] + 활동(1) + 민감도(1)
  int get _totalPages => _hasCondition ? 7 : 6;

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
        if (_currentPage == 3) {
          _analytics.logEvent(name: 'onboarding_step_4');
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
      name: _name,
      gender: _gender,
      ageGroup: _ageGroup,
      hasCondition: _hasCondition,
      conditionType: _conditionType,
      severity: _severity,
      isDiagnosed: _isDiagnosed,
      activityLevel: _activityLevel,
      sensitivity: _sensitivity,
    );

    try {
      await ref.read(profileProvider.notifier).saveProfile(profile);
      await ref.read(profileRepositoryProvider).completeOnboarding();
    } catch (_) {
      // 저장 실패해도 홈으로 진행 (다음 실행 시 재시도 가능)
    }

    await _analytics.logEvent(name: 'onboarding_completed');

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/onboarding_result');
    }
  }

  Future<void> _skipOnboarding() async {
    await _analytics.logEvent(name: 'onboarding_skipped');

    try {
      await ref.read(profileRepositoryProvider).completeOnboarding();
    } catch (_) {
      // 저장 실패해도 홈으로 진행
    }

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
      // 1. 이름
      StepName(
        initialName: _name,
        onChanged: (v) => setState(() => _name = v),
      ),
      // 2. 성별 (선택) — 임신 옵션 노출 여부 결정
      StepGender(
        selected: _gender,
        onChanged: (v) => setState(() {
          _gender = v;
          // 남성/기타로 변경 시 임신 선택 초기화
          if (v != Gender.female &&
              _conditionType == ConditionType.pregnancy) {
            _conditionType = ConditionType.none;
            _hasCondition = false;
          }
        }),
      ),
      // 3. 나이
      StepAge(
        selected: _ageGroup,
        onChanged: (v) => setState(() => _ageGroup = v),
      ),
      // 4. 기저질환 여부 — 성별 전달하여 임신 분기 적용
      StepCondition(
        hasCondition: _hasCondition,
        conditionType: _conditionType,
        gender: _gender,
        onConditionChanged: (v) => setState(() {
          _hasCondition = v;
          if (!v) _conditionType = ConditionType.none;
        }),
        onTypeChanged: (v) => setState(() => _conditionType = v),
      ),
    ];

    // 5. 질환 수준 (기저질환이 있을 경우만)
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

    // 6. 야외 활동 빈도
    pages.add(
      StepLifestyle(
        activityLevel: _activityLevel,
        onChanged: (v) => setState(() => _activityLevel = v),
      ),
    );

    // 7. 알림 민감도
    pages.add(
      StepSensitivity(
        sensitivity: _sensitivity,
        onChanged: (v) => setState(() => _sensitivity = v),
      ),
    );

    return pages;
  }
}
