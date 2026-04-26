import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/utils/persona_generator.dart';
import '../../features/profile_tab/widgets/persona_card.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/app_button.dart';

class DiagnosisResultScreen extends ConsumerStatefulWidget {
  const DiagnosisResultScreen({super.key});

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
    final persona = PersonaGenerator.generate(profile);

    return PopScope(
      canPop: false,
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

                      // ── 인사 ────────────────────────────────
                      Text(
                        profile.displayName.isNotEmpty
                            ? '${profile.displayName},\n이렇게 알려드릴게요.'
                            : '이렇게 알려드릴게요.',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 페르소나 카드 (항상 펼친 상태) ──────
                      Container(
                        decoration: personaCardDecoration(persona.type),
                        padding: personaCardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이모지 + 이름 + 서브타이틀
                            Text(
                              persona.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              persona.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: DT.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              persona.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: DT.gray,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 기준치 비교
                            _ResultThresholdRow(
                              label: '내 기준치',
                              value: '${profile.tFinal.toInt()} µg/m³',
                              highlight: true,
                            ),
                            const SizedBox(height: 4),
                            const _ResultThresholdRow(
                              label: '일반인 기준',
                              value: '35 µg/m³',
                              highlight: false,
                            ),

                            // 구분선 + reasons (PersonaCardExpanded 재사용)
                            PersonaCardExpanded(
                              persona: persona,
                              profile: profile,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 안심 메시지 ─────────────────────────
                      Text(
                        '공기가 나빠지기 전에\n먼저 알려드릴게요.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── CTA ─────────────────────────────────
                      AppButton.primary(
                        label: '위치 설정으로 →',
                        onTap: () =>
                            context.go('/location_setup', extra: true),
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

// 기준치 비교 행 — PersonaCard 의 _ThresholdRow 와 동일 스타일
class _ResultThresholdRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ResultThresholdRow({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: DT.gray)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: highlight ? DT.primary : DT.gray,
          ),
        ),
      ],
    );
  }
}
