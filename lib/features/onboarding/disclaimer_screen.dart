import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// 의료 면책 확인 화면 — 온보딩 최초 진입 시 1회 표시
class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                '잠깐, 알려드릴게요',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),

              AppCard(
                padding: const EdgeInsets.all(AppTokens.cardLg),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DisclaimerItem(
                      icon: Icons.health_and_safety_outlined,
                      text: '위험도와 마스크 추천은 참고용이에요. 몸이 보내는 신호가 더 정확할 수 있어요.',
                    ),
                    SizedBox(height: 16),
                    _DisclaimerItem(
                      icon: Icons.medical_services_outlined,
                      text: '호흡기 질환·임신·항암 치료 중이시면 의료진의 안내를 우선해주세요.',
                    ),
                    SizedBox(height: 16),
                    _DisclaimerItem(
                      icon: Icons.air_outlined,
                      text: '미세먼지 수치는 개인 환경에 따라 체감과 다를 수 있어요.',
                    ),
                  ],
                ),
              ),

              const Spacer(),

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
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DisclaimerItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
