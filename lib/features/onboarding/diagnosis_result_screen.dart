import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/app_button.dart';
import '../profile/profile_persona.dart';
import '../profile/widgets/axis_list.dart';
import '../profile/widgets/profile_background.dart';
import '../profile/widgets/profile_hero.dart';
import '../profile/widgets/threshold_range.dart';

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
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
    final persona = PersonaData.fromProfile(profile);
    final level = ProfileBackground.levelFromSum(persona.sum);
    final accent = ProfileBackground.accentColor(level);

    return PopScope(
      canPop: widget.isRediag,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ProfileBackground(
          level: level,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => FadeTransition(
                opacity: _fade,
                child: Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero: 인사 + 숫자 + 페르소나 ─────────
                        ProfileHero(
                          tFinal: persona.tFinal,
                          greeting: persona.name.isNotEmpty
                              ? persona.name
                              : null,
                          sub: persona.labelDiscovery,
                        ),
                        const SizedBox(height: 44),

                        // ── ThresholdRange: 단일 트랙 두 마커 ────
                        ThresholdRange(
                          myThreshold: persona.tFinal,
                          general: persona.general,
                          accentColor: accent,
                        ),
                        const SizedBox(height: 28),

                        // ── 섹션 라벨 ─────────────────────────────
                        const _SectionLabel('내 호흡기 정보'),
                        const SizedBox(height: 8),

                        // ── 5축 분석 ──────────────────────────────
                        AxisList(
                          axes: persona.axes,
                          accentColor: accent,
                        ),
                        const SizedBox(height: 24),

                        // ── CTA ───────────────────────────────────
                        _CtaButton(
                          label: widget.isRediag ? '확인' : '위치 설정으로',
                          onTap: () => widget.isRediag
                              ? context.go('/profile')
                              : context.go('/location_setup', extra: true),
                        ),
                        const SizedBox(height: 10),

                        // ── 자료원 ────────────────────────────────
                        const _SourcesCompact(),
                      ],
                    ),
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

// ── _SectionLabel ──────────────────────────────────────────────
// 13pt w700 gray, letterSpacing 0.04em, uppercase 효과 (소문자 한국어)

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: DT.gray,
        letterSpacing: 0.52, // 0.04em × 13pt
      ),
    );
  }
}

// ── _CtaButton ─────────────────────────────────────────────────
// 높이 52, borderRadius 16, bg DT.text, label white 15pt w700
// app_button.dart: boxShadow 없음 → AppButton.primary 재사용
// 단, 전역 테마(primary=파랑)와 다르므로 로컬 Theme으로 색 재정의

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DT.text,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ),
      child: AppButton.primary(
        label: label,
        onTap: onTap,
        height: 52,
      ),
    );
  }
}

// ── _SourcesCompact ────────────────────────────────────────────
// 11pt w500 DT.gray (WCAG AA 통과), lineHeight 1.55

class _SourcesCompact extends StatelessWidget {
  const _SourcesCompact();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'WHO Air Quality Guidelines 2021 · 환경부 · ARIA · ATS · 대한천식알레르기학회 자료 참고\n'
      '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단을 대체하지 않습니다.',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: DT.gray,
        height: 1.55,
      ),
    );
  }
}
