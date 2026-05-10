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

/// 의료 면책 확인 화면 — 사이클 #15 그룹1 개선
///
/// - 항목 아이콘/폰트/패딩 강화
/// - 3번 항목 라벨 "수치가 달라요" + amber-700 색상
/// - SingleChildScrollView 래핑 (작은 화면 대응)
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 52),

                          // ── Hero ──────────────────────────────────────────
                          const OnboardingHero(
                            main: '잠깐,\n읽어주세요',
                            sub: '더 정확한 정보를 위해 읽어주세요',
                            heroSize: 48,
                          ),
                          const SizedBox(height: 32),

                          // ── 항목 1 ────────────────────────────────────────
                          const _DisclaimerItem(
                            icon: Icons.info_outline,
                            iconColor: DT.gray,
                            label: '참고 정보',
                            text: '위험도와 마스크 추천은 참고용이에요. 몸이 보내는 신호가 더 정확할 수 있어요.',
                          ),
                          Divider(
                            height: 1,
                            color: DT.text.withValues(alpha: 0.06),
                          ),

                          // ── 항목 2 ────────────────────────────────────────
                          const _DisclaimerItem(
                            icon: Icons.local_hospital_outlined,
                            iconColor: DT.danger,
                            label: '의료진 우선',
                            text: '호흡기 질환·임신·항암 치료 중이시면 의료진의 안내를 우선해주세요.',
                          ),
                          Divider(
                            height: 1,
                            color: DT.text.withValues(alpha: 0.06),
                          ),

                          // ── 항목 3 ────────────────────────────────────────
                          const _DisclaimerItem(
                            icon: Icons.warning_amber_outlined,
                            iconColor: Color(0xFFB45309),
                            label: '수치가 달라요',
                            text: '미세먼지 수치는 개인 환경에 따라 체감과 다를 수 있어요.',
                          ),

                          const SizedBox(height: 32),

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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String text;

  const _DisclaimerItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DT.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
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
