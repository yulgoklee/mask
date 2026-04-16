import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../providers/providers.dart';

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
    '프로필을 분석하고 있어요...',
    '민감도 계수를 계산 중이에요...',
    '맞춤형 알림 기준을 설정하고 있어요...',
    '거의 다 됐어요! ✨',
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
    // 메시지 단계 애니메이션 (0.55초 간격으로 3회 전환)
    for (int i = 1; i < _messages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      await _fadeCtrl.reverse();
      setState(() => _messageIndex = i);
      _fadeCtrl.forward();
    }

    // 마지막 메시지 유지 후 이동
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final s = SensitivityCalculator.compute(profile);
    final tFinal = SensitivityCalculator.threshold(s);
    final name = profile.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── 로고 아이콘 ─────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('😷', style: TextStyle(fontSize: 44)),
                  ),
                ),

                const SizedBox(height: 36),

                // ── 헤드라인 ────────────────────────────────────
                Text(
                  '$name만을 위한\n맞춤형 알고리즘을\n설계 중입니다',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Spinkit 로딩 ────────────────────────────────
                const SpinKitThreeBounce(
                  color: AppColors.primary,
                  size: 32,
                ),

                const SizedBox(height: 32),

                // ── 단계별 메시지 ────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    _messages[_messageIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 56),

                // ── 결과 미리보기 칩 ────────────────────────────
                _ResultChip(s: s, tFinal: tFinal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 분석 완료 예정 결과를 미리 보여주는 작은 카드
class _ResultChip extends StatelessWidget {
  final double s;
  final double tFinal;

  const _ResultChip({required this.s, required this.tFinal});

  @override
  Widget build(BuildContext context) {
    final label = SensitivityCalculator.label(s);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '민감도 $label',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.coral,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '알림 기준 ${tFinal.toStringAsFixed(1)} μg/m³',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
