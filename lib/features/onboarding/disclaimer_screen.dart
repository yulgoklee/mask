import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../widgets/app_button.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_hero.dart';

/// 의료 면책 확인 화면 — 사이클 #12 PR1 재설계
///
/// - 56×56 아이콘 컨테이너 제거 → OnboardingHero 48pt
/// - OnboardingBackground (safe 그라디언트)
/// - 이모지 없음
class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),

                // ── Hero ──────────────────────────────────────────
                const OnboardingHero(
                  main: '잠깐,\n알려드릴게요',
                  sub: '더 정확한 정보를 위해 읽어주세요',
                  heroSize: 48,
                ),
                const SizedBox(height: 32),

                // ── 항목 1 ────────────────────────────────────────
                const _DisclaimerItem(
                  icon: Icons.health_and_safety_outlined,
                  label: '참고 정보',
                  text: '위험도와 마스크 추천은 참고용이에요. 몸이 보내는 신호가 더 정확할 수 있어요.',
                ),
                Divider(
                  height: 1,
                  color: DT.text.withValues(alpha: 0.06),
                ),

                // ── 항목 2 ────────────────────────────────────────
                const _DisclaimerItem(
                  icon: Icons.medical_services_outlined,
                  label: '의료진 우선',
                  text: '호흡기 질환·임신·항암 치료 중이시면 의료진의 안내를 우선해주세요.',
                ),
                Divider(
                  height: 1,
                  color: DT.text.withValues(alpha: 0.06),
                ),

                // ── 항목 3 ────────────────────────────────────────
                const _DisclaimerItem(
                  icon: Icons.air_outlined,
                  label: '측정 한계',
                  text: '미세먼지 수치는 개인 환경에 따라 체감과 다를 수 있어요.',
                  isLast: true,
                ),

                const Spacer(),

                // ── CTA ───────────────────────────────────────────
                AppButton.primary(
                  label: '확인했습니다',
                  onTap: () async {
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setString(
                      AppConstants.prefDisclaimerAgreedAt,
                      DateTime.now().toIso8601String(),
                    );
                    if (!context.mounted) return;
                    context.go('/welcome');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final bool isLast;

  const _DisclaimerItem({
    required this.icon,
    required this.label,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DT.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DT.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DT.gray,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
