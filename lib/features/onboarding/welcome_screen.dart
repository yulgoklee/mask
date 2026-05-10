import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_hero.dart';

/// 웰컴 화면 — 사이클 #15 그룹1 PageView 2페이지 재설계
///
/// 페이지 1: "사람마다 호흡이 달라요" + 비교 막대 그래픽
/// 페이지 2: "이렇게 진행돼요" + StepRow 3단계 (아이콘 강화)
///
/// P3("이런 걸 여쭤볼게요") 폐기 — 2페이지 구조
/// AnimationController 제거 — OnboardingHero 내부 animate + sub/CTA fadeIn
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
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
                  ],
                ),
              ),

              // ── 도트 인디케이터 ──────────────────────────
              _DotIndicator(currentPage: _currentPage, pageCount: 2),
              const SizedBox(height: 20),

              // ── CTA 버튼 ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _currentPage < 1
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
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 페이지 1: "사람마다 호흡이 달라요" + 비교 막대 ─────────────────

class _WelcomePage1 extends StatelessWidget {
  const _WelcomePage1();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // Hero 56pt
          const OnboardingHero(
            main: '사람마다\n호흡이 달라요',
            sub: '내 건강 정보로 미세먼지 기준이 달라져요.',
            heroSize: 56,
          ),

          // 비교 막대 그래픽
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('일반', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: DT.gray)),
                    Text('35 µg/㎥', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DT.gray, fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(DT.primary),
                    backgroundColor: DT.border,
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('예: 호흡기가 약하다면', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: DT.danger)),
                    Text('23 µg/㎥', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DT.danger, fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.657, // 23/35
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(DT.danger),
                    backgroundColor: DT.border,
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
}

// ── 페이지 2: "이렇게 진행돼요" + StepRow ─────────────────────────

class _WelcomePage2 extends StatelessWidget {
  const _WelcomePage2();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // Hero 40pt
          const OnboardingHero(
            main: '이렇게 진행돼요',
            sub: '약 2분이면 충분해요.',
            heroSize: 40,
          ),
          const SizedBox(height: 36),

          // 3단계
          const _StepRow(
            number: '01',
            icon: Icons.help_outline,
            label: '질문',
            description: '5개 질문 · 약 2분',
          ),
          Divider(height: 1, color: DT.text.withValues(alpha: 0.06)),
          const _StepRow(
            number: '02',
            icon: Icons.insights_outlined,
            label: '결과',
            description: '내 기준치 · 즉시',
          ),
          Divider(height: 1, color: DT.text.withValues(alpha: 0.06)),
          const _StepRow(
            number: '03',
            icon: Icons.notifications_outlined,
            label: '알림',
            description: '외출 전 · 전날 · 귀가',
          ),

          const SizedBox(height: 32),
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

// ── 단계 행 ─────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final String number;
  final IconData icon;
  final String label;
  final String description;

  const _StepRow({
    required this.number,
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DT.primary, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DT.gray2,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DT.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: DT.gray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
