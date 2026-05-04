import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../data/models/notification_setting.dart';
import '../../../providers/profile_providers.dart';

/// §3.2 내 알림 요약 카드
///
/// 활성화된 알림 종류를 "·" 구분으로 한 줄 표시.
/// 전체 InkWell + "변경 →" 버튼 모두 /notifications push.
class NotificationSummaryCard extends ConsumerWidget {
  const NotificationSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    final summaryText = _buildSummary(setting);

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
              const SizedBox(height: 10),
              // 요약 카피
              Text(
                summaryText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
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

  /// §3.2 카피 룰:
  /// - 활성화된 알림 종류만 "·"로 구분 나열
  /// - morningAlert: "매일 오전 N시"
  /// - eveningForecast: "전날 예보"
  /// - eveningReturn: "귀가 후"
  /// - realtimeAlert: "실시간 경보"
  /// - 모두 꺼지면: "받고 있는 알림이 없어요"
  static String _buildSummary(NotificationSetting s) {
    final parts = <String>[];

    if (s.morningAlertEnabled) {
      final hour = s.morningAlertHour;
      final suffix = hour < 12 ? '오전' : '오후';
      final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      parts.add('매일 $suffix $display시');
    }
    if (s.eveningForecastEnabled) {
      parts.add('전날 예보');
    }
    if (s.eveningReturnEnabled) {
      parts.add('귀가 후');
    }
    if (s.realtimeAlertEnabled) {
      parts.add('실시간 경보');
    }

    if (parts.isEmpty) {
      return '받고 있는 알림이 없어요';
    }
    return parts.join(' · ');
  }
}
