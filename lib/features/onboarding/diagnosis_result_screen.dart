import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sensitivity_widgets.dart';
import 'widgets/persona_conclusion_card.dart';

class DiagnosisResultScreen extends ConsumerStatefulWidget {
  final bool isRediag;
  const DiagnosisResultScreen({super.key, this.isRediag = false});

  @override
  ConsumerState<DiagnosisResultScreen> createState() =>
      _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends ConsumerState<DiagnosisResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 32.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return PopScope(
      canPop: widget.isRediag,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FadeTransition(
              opacity: _fade,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // ── 헤더: 이름 + 그룹 뱃지 ──────────────────
                      ProfileStateHeader(profile: profile),
                      const SizedBox(height: 20),

                      // ── 메인 카드: 일반 vs 내 기준 ──────────────
                      ThresholdCompareCard(
                        profile: profile,
                        showSubtitle: true,
                      ),
                      const SizedBox(height: 16),

                      // ── 결론 카드: 마스크 필요성 (결과지 전용) ───
                      PersonaConclusionCard(profile: profile),
                      const SizedBox(height: 16),

                      // ── 상태 분석: 5개 막대 ──────────────────────
                      SensitivityBreakdown(profile: profile),
                      const SizedBox(height: 16),

                      // ── CTA ─────────────────────────────────────
                      AppButton.primary(
                        label: widget.isRediag ? '확인' : '위치 설정으로 →',
                        onTap: () => widget.isRediag
                            ? context.go('/profile')
                            : context.go('/location_setup', extra: true),
                      ),
                      const SizedBox(height: 20),

                      // ── 근거 자료 푸터 ───────────────────────────
                      Text(
                        '※ 본 진단은 ARIA · ATS · WHO Air Quality Guidelines 2021 ·\n   대한천식알레르기학회 자료를 참고했습니다.\n   의료 진단을 대체하지 않습니다.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
