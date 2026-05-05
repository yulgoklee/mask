import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/sensitivity_widgets.dart';
import 'widgets/notification_summary_card.dart';
import 'widgets/persona_alert_card.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '프로필',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          // ── 카드 1: 페르소나 ───────────────────────────────
          ProfileStateHeader(profile: profile),
          const SizedBox(height: 16),
          ThresholdCompareCard(profile: profile),
          const SizedBox(height: 16),
          SensitivityBreakdown(profile: profile),
          const SizedBox(height: 12),
          PersonaAlertCard(profile: profile),
          const SizedBox(height: 12),
          SensitivityActionGuide(profile: profile),
          const SizedBox(height: 20),

          // ── 카드 2: 내 알림 요약 ───────────────────────────
          const NotificationSummaryCard(),
          const SizedBox(height: 12),

          // ── 한 줄 링크: 내 몸 정보 수정 ───────────────────
          const _BodyInfoLink(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── §3.3 내 몸 정보 수정 한 줄 링크 ──────────────────────────

class _BodyInfoLink extends StatelessWidget {
  const _BodyInfoLink();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/profile/edit'),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DT.border),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  '내 몸 정보 수정',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
