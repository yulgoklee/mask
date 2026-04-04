import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

class StepNotification extends ConsumerWidget {
  const StepNotification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '알림 설정',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '원하는 알림만 켜두세요. 나중에 언제든 변경할 수 있어요.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              children: [
                _NotifTile(
                  icon: Icons.wb_sunny_outlined,
                  title: '오전 알림',
                  subtitle: '매일 아침 미세먼지 상태 안내',
                  enabled: setting.morningAlertEnabled,
                  hour: setting.morningAlertHour,
                  minute: setting.morningAlertMinute,
                  onToggle: (v) {
                    ref.read(notificationSettingProvider.notifier).update(
                          setting.copyWith(morningAlertEnabled: v),
                        );
                  },
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
                  subtitle: '내일 미세먼지 예보 안내',
                  enabled: setting.eveningForecastEnabled,
                  hour: setting.eveningForecastHour,
                  minute: setting.eveningForecastMinute,
                  onToggle: (v) {
                    ref.read(notificationSettingProvider.notifier).update(
                          setting.copyWith(eveningForecastEnabled: v),
                        );
                  },
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
                  title: '저녁 귀가 알림',
                  subtitle: '퇴근 시간대 미세먼지 안내',
                  enabled: setting.eveningReturnEnabled,
                  hour: setting.eveningReturnHour,
                  minute: setting.eveningReturnMinute,
                  onToggle: (v) {
                    ref.read(notificationSettingProvider.notifier).update(
                          setting.copyWith(eveningReturnEnabled: v),
                        );
                  },
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.dustBad, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '실시간 경보',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '미세먼지 급등 시 즉시 알림',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: setting.realtimeAlertEnabled,
                        onChanged: (v) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(
                                setting.copyWith(realtimeAlertEnabled: v),
                              );
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
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
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
