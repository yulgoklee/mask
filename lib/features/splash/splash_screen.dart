import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_logger.dart';
import '../../features/onboarding/widgets/onboarding_background.dart';
import '../../features/onboarding/widgets/onboarding_hero.dart';
import '../../providers/providers.dart';

/// 스플래시 화면 — 사이클 #12 PR1 재설계
///
/// 배경: OnboardingBackground (safe 그라디언트)
/// Hero: 64pt 좌측 정렬 (케어 탭 일관성)
/// 슬로건: "같은 공기,\n다른 기준." / 서브: "내 건강 상태에 맞게 알려드려요."
/// 노출 시간: 1800ms
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // 텍스트 애니메이션
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _startAnimations();
    _navigate();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _textCtrl.forward();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      final repo = ref.read(profileRepositoryProvider);
      final tutorialSeen = await repo.isTutorialSeen();
      final onboardingDone = await repo.isOnboardingCompleted();
      if (!mounted) return;

      if (!tutorialSeen || !onboardingDone) {
        final prefs = ref.read(sharedPreferencesProvider);
        final disclaimerAgreed = prefs.getString(AppConstants.prefDisclaimerAgreedAt);
        context.go(disclaimerAgreed == null ? '/disclaimer' : '/welcome');
      } else {
        final prefs = ref.read(sharedPreferencesProvider);
        final savedStation = prefs.getString(AppConstants.prefStationName);
        if (savedStation == null || savedStation.isEmpty) {
          context.go('/location_setup', extra: true);
        } else {
          context.go('/care');
        }
      }
    } catch (e, st) {
      AppLogger.error(e, st, reason: 'splash_navigate');
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Hero + 서브 ──────────────────────────────────
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const OnboardingHero(
                      main: '같은 공기,\n다른 기준.',
                      sub: '내 건강 상태에 맞게 알려드려요.',
                      heroSize: 64,
                    ),
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
