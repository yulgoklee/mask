import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';

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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 24.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: Transform.translate(
              offset: Offset(0, _slide.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),

                    // ── 이모지 ──────────────────────────────────
                    const Text('😷', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 24),

                    // ── 메인 타이틀 ─────────────────────────────
                    const Text(
                      '내 몸에 맞는\n미세먼지 알림',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 서브 카피 ────────────────────────────────
                    Text(
                      '같은 공기도 사람마다 다르게 영향을 줘요.\n당신의 몸 상태를 알려주시면 그에 맞춘\n알림을 보내드릴게요.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary.withValues(alpha: 0.65),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── 구분선 ──────────────────────────────────
                    const Divider(height: 1, color: DT.border),
                    const SizedBox(height: 28),

                    // ── 진행 안내 제목 ──────────────────────────
                    const Text(
                      '어떻게 진행되나요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DT.gray,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 3단계 ────────────────────────────────────
                    const _StepRow(
                      number: '①',
                      label: '몇 가지 질문',
                      description: '호흡기 · 활동량 · 민감도',
                    ),
                    const SizedBox(height: 20),
                    const _StepRow(
                      number: '②',
                      label: '결과 확인',
                      description: '당신의 페르소나와 기준치',
                    ),
                    const SizedBox(height: 20),
                    const _StepRow(
                      number: '③',
                      label: '알림 설정',
                      description: '원하는 시간에 받기',
                    ),

                    const Spacer(),

                    // ── CTA ─────────────────────────────────────
                    AppButton.primary(
                      label: '시작할게요',
                      onTap: _start,
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

class _StepRow extends StatelessWidget {
  final String number;
  final String label;
  final String description;

  const _StepRow({
    required this.number,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: DT.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DT.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: DT.gray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
