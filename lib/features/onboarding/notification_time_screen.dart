import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/notification_setting.dart';
import '../../providers/providers.dart';

/// 위치 설정 이후 — 알림 시간 + 톤 설정 화면
class NotificationTimeScreen extends ConsumerWidget {
  const NotificationTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '언제 알림을 드릴까요?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '원하는 알림만 켜두세요. 나중에 언제든 변경할 수 있어요.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _NotifTile(
                    icon: Icons.wb_sunny_outlined,
                    title: '외출 전 알림',
                    subtitle: '매일 아침 마스크 필요 여부 안내',
                    enabled: setting.morningAlertEnabled,
                    hour: setting.morningAlertHour,
                    minute: setting.morningAlertMinute,
                    onToggle: (v) => ref
                        .read(notificationSettingProvider.notifier)
                        .update(setting.copyWith(morningAlertEnabled: v)),
                    onTimeTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: setting.morningAlertHour,
                          minute: setting.morningAlertMinute,
                        ),
                      );
                      if (picked != null) {
                        ref.read(notificationSettingProvider.notifier).update(
                              setting.copyWith(
                                morningAlertHour: picked.hour,
                                morningAlertMinute: picked.minute,
                              ),
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _NotifTile(
                    icon: Icons.nights_stay_outlined,
                    title: '전날 예보 알림',
                    subtitle: '내일 미세먼지 예보 미리 안내',
                    enabled: setting.eveningForecastEnabled,
                    hour: setting.eveningForecastHour,
                    minute: setting.eveningForecastMinute,
                    onToggle: (v) => ref
                        .read(notificationSettingProvider.notifier)
                        .update(setting.copyWith(eveningForecastEnabled: v)),
                    onTimeTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: setting.eveningForecastHour,
                          minute: setting.eveningForecastMinute,
                        ),
                      );
                      if (picked != null) {
                        ref.read(notificationSettingProvider.notifier).update(
                              setting.copyWith(
                                eveningForecastHour: picked.hour,
                                eveningForecastMinute: picked.minute,
                              ),
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _NotifTile(
                    icon: Icons.home_outlined,
                    title: '귀가 후 알림',
                    subtitle: '퇴근 시간대 미세먼지 확인 안내',
                    enabled: setting.eveningReturnEnabled,
                    hour: setting.eveningReturnHour,
                    minute: setting.eveningReturnMinute,
                    onToggle: (v) => ref
                        .read(notificationSettingProvider.notifier)
                        .update(setting.copyWith(eveningReturnEnabled: v)),
                    onTimeTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: setting.eveningReturnHour,
                          minute: setting.eveningReturnMinute,
                        ),
                      );
                      if (picked != null) {
                        ref.read(notificationSettingProvider.notifier).update(
                              setting.copyWith(
                                eveningReturnHour: picked.hour,
                                eveningReturnMinute: picked.minute,
                              ),
                            );
                      }
                    },
                  ),
                ],
              ),
            ),

            // 알림 톤 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _VoiceCard(setting: setting, ref: ref),
            ),
            const SizedBox(height: 12),

            // 시뮬레이션 + 다음 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  _SimulationButton(setting: setting),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 시뮬레이션을 건너뛴 경우에도 여기서 onboarding 완료 처리
                        try {
                          await ref
                              .read(profileRepositoryProvider)
                              .completeOnboarding();
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushReplacementNamed('/permission');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '다음',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                if (enabled) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:'
                      '${minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── 알림 톤 선택 카드 ─────────────────────────────────────

class _VoiceCard extends StatelessWidget {
  final NotificationSetting setting;
  final WidgetRef ref;
  const _VoiceCard({required this.setting, required this.ref});

  @override
  Widget build(BuildContext context) {
    final voices = [
      NotificationVoice.friendlyVoice,
      NotificationVoice.analyticalVoice,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '알림 톤 선택',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '마음에 드는 알림 문체를 골라보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: voices.map((v) {
              final selected = setting.notificationVoice == v;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(notificationSettingProvider.notifier)
                        .update(setting.copyWith(notificationVoice: v));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(
                      right: v == NotificationVoice.friendlyVoice ? 6 : 0,
                      left: v == NotificationVoice.analyticalVoice ? 6 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surfaceVariant,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: selected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(v.emoji,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          v.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 알림 시뮬레이션 버튼 ──────────────────────────────────

class _SimulationButton extends ConsumerStatefulWidget {
  final NotificationSetting setting;
  const _SimulationButton({required this.setting});

  @override
  ConsumerState<_SimulationButton> createState() => _SimulationButtonState();
}

class _SimulationButtonState extends ConsumerState<_SimulationButton> {
  bool _loading = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (_loading || _sent) ? null : _simulate,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : Icon(
                _sent ? Icons.check_circle_outline : Icons.notifications_outlined,
                size: 18,
              ),
        label: Text(
          _sent
              ? '알림을 보냈어요!'
              : _loading
                  ? '전송 중...'
                  : '알림 미리 받아보기',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              _sent ? AppColors.success : AppColors.primary,
          side: BorderSide(
            color: _sent
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _simulate() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    try {
      await NotificationService().showSimulationNotification(
        voice: widget.setting.notificationVoice.value,
      );
      // 시뮬레이션 완료 = 온보딩 설정 최종 확정 시점
      await ref.read(profileRepositoryProvider).completeOnboarding();
    } catch (_) {}
    if (mounted) setState(() { _loading = false; _sent = true; });
  }
}
