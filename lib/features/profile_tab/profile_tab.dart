import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/user_profile.dart';
import '../../core/services/app_logger.dart';
import '../../providers/providers.dart';
import '../../widgets/sensitivity_widgets.dart';

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

          // ── 보기 영역 ────────────────────────────────────────
          ProfileStateHeader(profile: profile),
          const SizedBox(height: 16),
          ThresholdCompareCard(profile: profile),
          const SizedBox(height: 16),
          SensitivityBreakdown(profile: profile),
          const SizedBox(height: 12),
          SensitivityActionGuide(profile: profile),
          const SizedBox(height: 20),

          // ── 프로필 수정 진입 ─────────────────────────────────
          _EditProfileButton(),
          const SizedBox(height: 28),

          const Divider(color: AppColors.divider),
          const SizedBox(height: 20),

          // ── 방해 금지 ────────────────────────────────────────
          const _SectionHeader(
            title: '방해 금지',
            badge: '알림 차단',
            tooltip: '설정한 시간대에는 미세먼지 알림을 보내지 않아요',
          ),
          const SizedBox(height: 10),
          const _QuietHoursSection(),
          const SizedBox(height: 24),

          // ── 법적 고지 ────────────────────────────────────────
          const Text(
            '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단이나 처방을 대체하지 않습니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── 프로필 수정 진입 버튼 ──────────────────────────────────

class _EditProfileButton extends StatefulWidget {
  @override
  State<_EditProfileButton> createState() => _EditProfileButtonState();
}

class _EditProfileButtonState extends State<_EditProfileButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        context.push('/profile/edit');
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프로필 수정하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '기본 정보 · 건강 상태 수정',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 섹션 헤더 ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String badge;
  final String? tooltip;

  const _SectionHeader({
    required this.title,
    required this.badge,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip!,
            child: const Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 방해 금지 시간 설정 ──────────────────────────────────

class _QuietHoursSection extends ConsumerWidget {
  const _QuietHoursSection();

  String _fmt(int hour) {
    final suffix = hour < 12 ? '오전' : '오후';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$suffix ${display}시';
  }

  Future<void> _pickHour(
    BuildContext context,
    WidgetRef ref,
    NotificationSetting setting,
    bool isStart,
  ) async {
    final initial = TimeOfDay(
        hour: isStart ? setting.quietHoursStartHour : setting.quietHoursEndHour,
        minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? '방해 금지 시작 시간' : '방해 금지 종료 시간',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    ref.read(notificationSettingProvider.notifier).update(
          isStart
              ? setting.copyWith(quietHoursStartHour: picked.hour)
              : setting.copyWith(quietHoursEndHour: picked.hour),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('방해 금지 시간이 저장됐어요'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    final enabled = setting.quietHoursEnabled;
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: const Text('🌙', style: TextStyle(fontSize: 22)),
            title: Text(
              '방해 금지 시간',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              '이 시간대에는 모든 알림을 차단해요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: Switch(
              value: enabled,
              onChanged: (v) {
                ref
                    .read(notificationSettingProvider.notifier)
                    .update(setting.copyWith(quietHoursEnabled: v));
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v ? '방해 금지가 켜졌어요' : '방해 금지가 꺼졌어요'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: '시작',
                      time: _fmt(setting.quietHoursStartHour),
                      onTap: () => _pickHour(context, ref, setting, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeChip(
                      label: '종료',
                      time: _fmt(setting.quietHoursEndHour),
                      onTap: () => _pickHour(context, ref, setting, false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeChip(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
