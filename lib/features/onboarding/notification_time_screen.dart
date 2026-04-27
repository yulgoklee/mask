import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/services/app_logger.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/notif_card.dart';

/// 위치 설정 이후 — 알림 시간 + 톤 설정 화면 (리디자인 v2)
class NotificationTimeScreen extends ConsumerWidget {
  const NotificationTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    // 홈 화면 로딩 단축: 알림 설정 중 백그라운드에서 미세먼지 데이터 선제 패치
    ref.watch(dustDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.screenH, 36, AppTokens.screenH, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🔔', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '알림을 설정해드릴게요',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '원하는 알림만 켜두세요. 언제든 변경할 수 있어요.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── 알림 카드 목록 ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    NotifCard(
                      emoji: '🌅',
                      title: '외출 전 알림',
                      subtitle: '아침에 마스크 필요 여부를 알려드려요',
                      accentColor: AppColors.notifMorning,
                      enabled: setting.morningAlertEnabled,
                      hour: setting.morningAlertHour,
                      minute: setting.morningAlertMinute,
                      onToggle: (v) => ref
                          .read(notificationSettingProvider.notifier)
                          .update(setting.copyWith(morningAlertEnabled: v)),
                      onTimeTap: () async {
                        final picked = await showCupertinoTimePicker(
                          context,
                          hour: setting.morningAlertHour,
                          minute: setting.morningAlertMinute,
                          accentColor: AppColors.notifMorning,
                        );
                        if (picked != null) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(setting.copyWith(
                                morningAlertHour: picked.hour,
                                morningAlertMinute: picked.minute,
                              ));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    NotifCard(
                      emoji: '🌙',
                      title: '전날 예보 알림',
                      subtitle: '내일 미세먼지를 미리 알려드려요',
                      accentColor: AppColors.notifEvening,
                      enabled: setting.eveningForecastEnabled,
                      hour: setting.eveningForecastHour,
                      minute: setting.eveningForecastMinute,
                      onToggle: (v) => ref
                          .read(notificationSettingProvider.notifier)
                          .update(setting.copyWith(eveningForecastEnabled: v)),
                      onTimeTap: () async {
                        final picked = await showCupertinoTimePicker(
                          context,
                          hour: setting.eveningForecastHour,
                          minute: setting.eveningForecastMinute,
                          accentColor: AppColors.notifEvening,
                        );
                        if (picked != null) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(setting.copyWith(
                                eveningForecastHour: picked.hour,
                                eveningForecastMinute: picked.minute,
                              ));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    NotifCard(
                      emoji: '🏠',
                      title: '귀가 후 알림',
                      subtitle: '퇴근 시간대 미세먼지를 확인해드려요',
                      accentColor: AppColors.notifReturn,
                      enabled: setting.eveningReturnEnabled,
                      hour: setting.eveningReturnHour,
                      minute: setting.eveningReturnMinute,
                      onToggle: (v) => ref
                          .read(notificationSettingProvider.notifier)
                          .update(setting.copyWith(eveningReturnEnabled: v)),
                      onTimeTap: () async {
                        final picked = await showCupertinoTimePicker(
                          context,
                          hour: setting.eveningReturnHour,
                          minute: setting.eveningReturnMinute,
                          accentColor: AppColors.notifReturn,
                        );
                        if (picked != null) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(setting.copyWith(
                                eveningReturnHour: picked.hour,
                                eveningReturnMinute: picked.minute,
                              ));
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── 하단 버튼 영역 ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.6),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  const _SimulationButton(),
                  const SizedBox(height: 10),
                  AppButton.primary(
                    label: '설정 완료  →',
                    onTap: () async {
                      try {
                        await ref
                            .read(profileRepositoryProvider)
                            .completeOnboarding();
                      } catch (e, st) {
                        AppLogger.error(e, st, reason: 'onboarding_complete_save');
                      }
                      if (!context.mounted) return;
                      final permStatus =
                          await Permission.notification.status;
                      if (!context.mounted) return;
                      context.go(permStatus.isGranted
                          ? '/onboarding_complete'
                          : '/permission');
                    },
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

// ══════════════════════════════════════════════════════════════
//  알림 시뮬레이션 버튼
// ══════════════════════════════════════════════════════════════

class _SimulationButton extends ConsumerStatefulWidget {
  const _SimulationButton();

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
      height: 50,
      child: OutlinedButton(
        onPressed: (_loading || _sent) ? null : _simulate,
        style: OutlinedButton.styleFrom(
          foregroundColor: _sent ? AppColors.success : AppColors.primary,
          side: BorderSide(
            color: _sent
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              Icon(
                _sent
                    ? Icons.check_circle_outline
                    : Icons.notifications_active_outlined,
                size: 18,
              ),
            const SizedBox(width: 8),
            Text(
              _sent
                  ? '알림을 보냈어요!'
                  : _loading
                      ? '전송 중...'
                      : '알림 미리 받아보기',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulate() async {
    setState(() => _loading = true);

    // 알림 권한 요청 (온보딩 중 신규 사용자는 아직 권한이 없음)
    final permStatus = await Permission.notification.request();

    if (!mounted) return;

    // 권한 거부 시 — 안내 스낵바 표시 후 종료
    if (permStatus.isDenied || permStatus.isPermanentlyDenied) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('알림 권한이 필요해요. 설정 앱에서 허용해주세요.'),
          action: permStatus.isPermanentlyDenied
              ? const SnackBarAction(
                  label: '설정 열기',
                  onPressed: openAppSettings,
                )
              : null,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      final nickname = ref.read(profileProvider).nickname;
      await service.showSimulationNotification(nickname: nickname);
    } catch (e, st) {
      AppLogger.error(e, st, reason: 'simulation_notif_send');
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _sent = true;
      });
    }
  }
}
