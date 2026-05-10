import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_hero.dart';

/// 웰컴 화면 — 사이클 #12 PR1 PageView 3페이지 재설계
///
/// 페이지 1: 앱 소개 (Hero 56pt)
/// 페이지 2: 질문지 안내 (Hero 40pt)
/// 페이지 3: 흐름 설명 (Hero 40pt)
///
/// 이모지 제거 (😷 → Hero 승격)
/// OnboardingBackground (safe 그라디언트)
/// 하단 도트 인디케이터 + 다음/시작 버튼
/// 마지막 페이지 → completeTutorial() → /onboarding
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // 첫 진입 fade+slide 애니메이션
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 24.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _pageController = PageController();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _start() async {
    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.completeTutorial();
    } catch (_) {}
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FadeTransition(
              opacity: _fade,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: Column(
                  children: [
                    // ── PageView ────────────────────────────────
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (page) {
                          setState(() => _currentPage = page);
                        },
                        children: const [
                          _WelcomePage1(),
                          _WelcomePage2(),
                          _WelcomePage3(),
                        ],
                      ),
                    ),

                    // ── 도트 인디케이터 ──────────────────────────
                    _DotIndicator(currentPage: _currentPage, pageCount: 3),
                    const SizedBox(height: 20),

                    // ── CTA 버튼 ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _currentPage < 2
                            ? KeyedSubtree(
                                key: const ValueKey('next'),
                                child: AppButton.secondary(
                                  label: '다음 →',
                                  onTap: _nextPage,
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('start'),
                                child: AppButton.primary(
                                  label: '시작할게요',
                                  onTap: _start,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 페이지 1: 앱 소개 ─────────────────────────────────────────────

class _WelcomePage1 extends StatelessWidget {
  const _WelcomePage1();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 48),

          // Hero 56pt (이모지 대체)
          OnboardingHero(
            main: '내 몸에 맞는\n미세먼지 알림',
            heroSize: 56,
          ),
          SizedBox(height: 16),

          // sub: 별도 Text (line-height 1.6 지원)
          Text(
            '같은 공기도 사람마다 다르게 영향을 줘요.\n건강 정보를 바탕으로 당신만의 기준을 만들어드려요.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: DT.gray,
              height: 1.6,
            ),
          ),

          Spacer(),
        ],
      ),
    );
  }
}

// ── 페이지 2: 질문지 안내 ────────────────────────────────────────

class _WelcomePage2 extends StatelessWidget {
  const _WelcomePage2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // Hero 40pt
          const OnboardingHero(
            main: '이런 걸 여쭤볼게요',
            sub: '호흡기 상태에 맞춘 기준을 만들기 위해 몇 가지만 확인할게요.',
            heroSize: 40,
          ),
          const SizedBox(height: 36),

          // 질문 예시 3개
          const _QuestionPreviewRow(
            icon: Icons.air_outlined,
            label: '호흡기 · 심혈관 질환 여부',
          ),
          Divider(height: 1, color: DT.text.withValues(alpha: 0.06)),
          const _QuestionPreviewRow(
            icon: Icons.smoking_rooms_outlined,
            label: '흡연 이력',
          ),
          Divider(height: 1, color: DT.text.withValues(alpha: 0.06)),
          const _QuestionPreviewRow(
            icon: Icons.person_outline_rounded,
            label: '성별 · 연령',
            isLast: true,
          ),

          const SizedBox(height: 24),
          const Text(
            '질문은 총 5개예요. 2분이면 충분해요.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DT.gray2,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ── 페이지 3: 흐름 설명 ───────────────────────────────────────────

class _WelcomePage3 extends StatelessWidget {
  const _WelcomePage3();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // Hero 40pt
          const OnboardingHero(
            main: '이렇게 진행돼요',
            sub: '단계별로 알려드릴게요.',
            heroSize: 40,
          ),
          const SizedBox(height: 36),

          // 3단계
          const _StepRow(
            number: '01',
            label: '몇 가지 질문',
            description: '호흡기·심혈관·흡연 이력',
          ),
          Divider(height: 1, color: DT.text.withValues(alpha: 0.06)),
          const _StepRow(
            number: '02',
            label: '결과 확인',
            description: '내 기준치와 건강 페르소나',
          ),
          Divider(height: 1, color: DT.text.withValues(alpha: 0.06)),
          const _StepRow(
            number: '03',
            label: '알림 설정',
            description: '원하는 시간에 받기',
            isLast: true,
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ── 도트 인디케이터 ──────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _DotIndicator({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (i) {
        final isActive = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? DT.primary : DT.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── 질문 미리보기 행 ──────────────────────────────────────────────

class _QuestionPreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;

  const _QuestionPreviewRow({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: DT.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: DT.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 단계 행 ─────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final String number;
  final String label;
  final String description;
  final bool isLast;

  const _StepRow({
    required this.number,
    required this.label,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: DT.gray,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: DT.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: DT.gray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
