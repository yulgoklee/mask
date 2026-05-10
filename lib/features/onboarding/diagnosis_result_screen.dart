import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/app_button.dart';
import '../onboarding/widgets/onboarding_background.dart';
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

class _DiagnosisResultScreenState
    extends ConsumerState<DiagnosisResultScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final persona = PersonaData.fromProfile(profile);
    final level = ProfileBackground.levelFromSum(persona.sum);
    final accent = ProfileBackground.accentColor(level);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: widget.isRediag,
        child: OnboardingBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero: 인사 + 숫자 + 페르소나 ─────────
                        ProfileHero(
                          cap: '내 기준은',
                          greeting: profile.displayName.isNotEmpty
                              ? profile.displayName
                              : null,
                          tFinal: persona.tFinal,
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

                        // ── 섹션 라벨 ─────────────────────────────────────────────
                        const _SectionLabel('내 건강 분석'),
                        const SizedBox(height: 8),

                        // ── 4축 분석 ──────────────────────────────
                        AxisList(
                          axes: persona.axes,
                          accentColor: accent,
                        ),
                        const SizedBox(height: 24),

                        // ── 자료원 ────────────────────────────────
                        const _SourcesCompact(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── CTA 하단 고정 ──────────────────────────────
                _BottomCta(isRediag: widget.isRediag),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _SectionLabel ──────────────────────────────────────────────
// 15pt w700 gray

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: DT.gray,
      ),
    );
  }
}

// ── _BottomCta ─────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool isRediag;
  const _BottomCta({required this.isRediag});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRediag) ...[
            const Text(
              '내 동네 공기는 지금 어때요?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: DT.gray,
                letterSpacing: -0.06,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          _CtaButton(
            label: isRediag ? '확인' : '내 동네 공기 보러 가기',
            onTap: () => isRediag
                ? context.go('/profile')
                : context.go('/location_setup', extra: true),
          ),
        ],
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
