import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/providers.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_hero.dart';

/// 온보딩 완료 후 분석 로딩 화면
///
/// flutter_spinkit 로딩 애니메이션 + 단계별 메시지 전환
/// 2.5초 후 onboarding_result 로 자동 이동
class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState
    extends ConsumerState<AnalysisLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  int _messageIndex = 0;

  static const _messages = [
    '건강 정보를 읽고 있어요',
    '내 기준값을 계산하고 있어요',
    '알림 시간을 맞추고 있어요',
    '거의 다 됐어요!',
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    // 메시지 단계 애니메이션 (0.9초 간격으로 3회 전환 — 사용자가 읽을 수 있도록)
    for (int i = 1; i < _messages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await _fadeCtrl.reverse();
      setState(() => _messageIndex = i);
      _fadeCtrl.forward();
    }

    // 마지막 메시지 유지 후 이동
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    context.go('/diagnosis_result');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final name = profile.displayName;

    // cap: name 있을 때 "$name만을 위한" / 없을 때 null
    final cap = name.isNotEmpty ? '$name만을 위한' : null;
    const heroMain = '내 알림 기준이\n만들어지고 있어요';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero ──────────────────────────────────────
                  OnboardingHero(
                    cap: cap,
                    main: heroMain,
                    heroSize: 48,
                  ),

                  const SizedBox(height: 52),

                  // ── Spinkit 로딩 ──────────────────────────────
                  const Center(
                    child: SpinKitThreeBounce(
                      color: DT.primary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 4단계 도트 ────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final isCurrent = i == _messageIndex;
                        final isPast = i <= _messageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrent ? 10 : 8,
                          height: isCurrent ? 10 : 8,
                          decoration: BoxDecoration(
                            color: isPast ? DT.primary : DT.border,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 단계별 메시지 ─────────────────────────────
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        _messages[_messageIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: DT.gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
