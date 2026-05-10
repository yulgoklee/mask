import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_logger.dart';
import '../../providers/providers.dart';

/// 스플래시 화면 — 사이클 #11 [A] 재설계
///
/// 배경색: DT.splashBg (#EBF3FF) — 브랜드 청색 10% 틴트
/// 아이콘: 😷 72pt 직접 (Container/boxShadow 없음)
/// 헤드라인: "같은 공기,\n다른 기준." 32pt Bold
/// 서브: "내 건강 상태에 맞게 알려드려요." 16pt w500 DT.gray
/// 노출 시간: 1800ms (이전 2200ms에서 단축)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _iconCtrl;
  late final AnimationController _textCtrl;

  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // 아이콘 애니메이션 (0 → 0.7초)
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconFade = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut);
    _iconScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOutBack),
    );

    // 텍스트 애니메이션 (0.35초 딜레이 후)
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
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
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
    _iconCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.splashBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── 앱 아이콘 (Container/boxShadow 없이 직접) ───────
              FadeTransition(
                opacity: _iconFade,
                child: ScaleTransition(
                  scale: _iconScale,
                  child: const Text('😷', style: TextStyle(fontSize: 72)),
                ),
              ),

              const SizedBox(height: 40),

              // ── 헤드라인 텍스트 ──────────────────────────────
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: const Column(
                    children: [
                      Text(
                        '같은 공기,\n다른 기준.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: DT.text,
                          height: 1.3,
                          letterSpacing: -0.64,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        '내 건강 상태에 맞게 알려드려요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: DT.gray,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
