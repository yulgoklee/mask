import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/services/app_logger.dart';
import '../../data/models/notification_setting.dart';
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
                    // ── 방해 금지 시간 ───────────────────────────
                    _OnboardingQuietHoursCard(
                      setting: setting,
                      notifier: ref.read(notificationSettingProvider.notifier),
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
                      context.go('/permission');
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
          content: const Text('알림 권한이 필요해요. 다음 화면에서 받을 수 있어요.'),
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

// ══════════════════════════════════════════════════════════════
//  온보딩용 방해 금지 시간 카드
// ══════════════════════════════════════════════════════════════

class _OnboardingQuietHoursCard extends ConsumerWidget {
  final NotificationSetting setting;
  final NotificationSettingNotifier notifier;

  const _OnboardingQuietHoursCard({
    required this.setting,
    required this.notifier,
  });

  String _hourLabel(int hour) {
    final period = hour < 12 ? '오전' : '오후';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $display시';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 방해 금지는 "차단" 의미 → 중립 회색 톤 사용
    const accentColor = DT.gray;
    const accentBg    = DT.grayLt;
    final enabled = setting.quietHoursEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: enabled ? accentBg : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? accentColor.withValues(alpha: 0.4)
              : AppColors.divider,
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더: 아이콘 + 텍스트 + 토글 ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: enabled
                        ? accentColor.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '방해 금지',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '이 시간엔 알림을 보내지 않아요',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: enabled,
                    onChanged: (v) =>
                        notifier.update(setting.copyWith(quietHoursEnabled: v)),
                    activeThumbColor: accentColor,
                    activeTrackColor: accentColor.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          // ── 시간 선택 (활성 시만) ────────────────────────────
          if (enabled) ...[
            Divider(
              height: 1,
              color: accentColor.withValues(alpha: 0.2),
              indent: 16,
              endIndent: 16,
            ),
            // 시작 시간
            GestureDetector(
              onTap: () async {
                final picked = await showCupertinoTimePicker(
                  context,
                  hour: setting.quietHoursStartHour,
                  minute: 0,
                  accentColor: accentColor,
                );
                if (picked != null) {
                  notifier.update(setting.copyWith(
                    quietHoursStartHour: picked.hour,
                  ));
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '시작',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _hourLabel(setting.quietHoursStartHour),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: accentColor.withValues(alpha: 0.15),
              indent: 16,
              endIndent: 16,
            ),
            // 종료 시간
            GestureDetector(
              onTap: () async {
                final picked = await showCupertinoTimePicker(
                  context,
                  hour: setting.quietHoursEndHour,
                  minute: 0,
                  accentColor: accentColor,
                );
                if (picked != null) {
                  notifier.update(setting.copyWith(
                    quietHoursEndHour: picked.hour,
                  ));
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '종료',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _hourLabel(setting.quietHoursEndHour),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: accentColor.withValues(alpha: 0.2),
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                '이 시간엔 알림을 보내지 않아요. 단, 매우 위험한 공기에선 예외예요.',
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
