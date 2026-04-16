import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

/// 스플래시 화면 — Phase 1 리디자인
///
/// 배경색: #A2D2FF (AppColors.primaryLight)
/// 헤드라인: "당신의 기관지는 남들과 다릅니다."
/// 서브: "당신만을 위한 마스크 타이밍."
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
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final repo = ref.read(profileRepositoryProvider);
    final tutorialSeen = await repo.isTutorialSeen();
    final onboardingDone = await repo.isOnboardingCompleted();
    if (!mounted) return;

    if (!onboardingDone) {
      // 온보딩 미완료 → 로드맵 소개 화면부터 시작
      Navigator.of(context).pushReplacementNamed('/roadmap');
    } else if (!tutorialSeen) {
      // 기존 유저 온보딩 완료 but 튜토리얼 미확인 → 튜토리얼
      Navigator.of(context).pushReplacementNamed('/tutorial');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
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
      backgroundColor: AppColors.primaryLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── 앱 아이콘 ────────────────────────────────────
              FadeTransition(
                opacity: _iconFade,
                child: ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('😷', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── 헤드라인 텍스트 ──────────────────────────────
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      const Text(
                        '당신의 기관지는\n남들과 다릅니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.35,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '당신만을 위한 마스크 타이밍.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
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
