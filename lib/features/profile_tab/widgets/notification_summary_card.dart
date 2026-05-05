import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../data/models/notification_setting.dart';
import '../../../providers/profile_providers.dart';

/// §3.2 내 알림 요약 카드 (리디자인)
///
/// 활성화된 알림 종류를 줄 단위로 분리해 표시.
/// 방해금지 활성 시 별도 줄 추가.
/// 전체 InkWell + "변경 →" 버튼 모두 /notifications push.
class NotificationSummaryCard extends ConsumerWidget {
  const NotificationSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    final rows = _buildRows(setting);

    return Material(
      color: DT.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/notifications'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DT.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카드 제목
              const Text(
                '🔔 내 알림',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 알림 항목 목록 (또는 fallback)
              if (rows.isEmpty)
                const Text(
                  '받고 있는 알림이 없어요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _NotifRow(label: rows[i].$1, value: rows[i].$2),
                    ],
                  ],
                ),

              const SizedBox(height: 14),
              // 구분선
              const Divider(height: 1, thickness: 1, color: DT.border),
              const SizedBox(height: 12),
              // "변경 →" 버튼 — 우측 정렬
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: const Text(
                    '변경 →',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 활성화된 알림 항목만 (label, value) 쌍으로 반환.
  /// 방해금지는 켜진 경우만 추가.
  static List<(String, String)> _buildRows(NotificationSetting s) {
    final rows = <(String, String)>[];

    if (s.morningAlertEnabled) {
      rows.add(('외출 전 알림', _timeLabel(s.morningAlertHour, s.morningAlertMinute)));
    }
    if (s.eveningForecastEnabled) {
      rows.add(('전날 예보 알림', _timeLabel(s.eveningForecastHour, s.eveningForecastMinute)));
    }
    if (s.eveningReturnEnabled) {
      rows.add(('귀가 후 알림', _timeLabel(s.eveningReturnHour, s.eveningReturnMinute)));
    }
    if (s.realtimeAlertEnabled) {
      rows.add(('실시간 경보', 'ON'));
    }
    if (s.quietHoursEnabled) {
      rows.add((
        '방해금지',
        '${_hourShort(s.quietHoursStartHour)} ~ ${_hourShort(s.quietHoursEndHour)}',
      ));
    }

    return rows;
  }

  static String _timeLabel(int hour, int minute) {
    final period = hour < 12 ? '오전' : '오후';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final min = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return '$period $display시$min';
  }

  static String _hourShort(int hour) {
    final h = hour.toString().padLeft(2, '0');
    return '$h:00';
  }
}

// ── 개별 알림 행 ──────────────────────────────────────────────

class _NotifRow extends StatelessWidget {
  final String label;
  final String value;

  const _NotifRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
