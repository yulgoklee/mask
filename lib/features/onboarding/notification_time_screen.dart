import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/services/app_logger.dart';
import '../../features/settings/widgets/s_dnd_child.dart';
import '../../features/settings/widgets/s_item.dart';
import '../../features/settings/widgets/s_label.dart';
import '../../features/settings/widgets/s_switch.dart';
import '../../features/settings/widgets/settings_drill_header.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/time_picker_sheet.dart';

/// 알림 시간 설정 화면
///
/// [isOnboarding] = true: 온보딩 플로우에서 진입. 하단 "설정 완료→" 버튼 표시.
/// [isOnboarding] = false(기본): 설정에서 push. 하단 버튼 없음.
class NotificationTimeScreen extends ConsumerWidget {
  final bool isOnboarding;

  const NotificationTimeScreen({super.key, this.isOnboarding = false});

  String _fmtTime(int h, int m) {
    final period = h < 12 ? '오전' : '오후';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final dm = m == 0 ? '00분' : '$m분';
    return '$period $dh시 $dm';
  }

  String _fmtHour(int h) {
    final period = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display시';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    final notifier = ref.read(notificationSettingProvider.notifier);
    // 홈 화면 로딩 단축: 알림 설정 중 백그라운드에서 미세먼지 데이터 선제 패치
    ref.watch(dustDataProvider);

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────────
            SettingsDrillHeader(
              title: '알림 시간',
              onBack: () => context.pop(),
            ),

            // ── 본문 (스크롤) ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 스케줄 알림 ────────────────────────────────
                    const SLabel('스케줄 알림'),
                    SItem(
                      label: '외출 전',
                      value: setting.morningAlertEnabled
                          ? _fmtTime(setting.morningAlertHour,
                              setting.morningAlertMinute)
                          : '꺼짐',
                      onClick: () async {
                        final picked = await showCupertinoTimePicker(
                          context,
                          hour: setting.morningAlertHour,
                          minute: setting.morningAlertMinute,
                          accentColor: DT.primary,
                        );
                        if (picked != null) {
                          notifier.update(setting.copyWith(
                            morningAlertEnabled: true,
                            morningAlertHour: picked.hour,
                            morningAlertMinute: picked.minute,
                          ));
                        }
                      },
                    ),
                    SItem(
                      label: '전날 예보',
                      value: setting.eveningForecastEnabled
                          ? _fmtTime(setting.eveningForecastHour,
                              setting.eveningForecastMinute)
                          : '꺼짐',
                      onClick: () async {
                        final picked = await showCupertinoTimePicker(
                          context,
                          hour: setting.eveningForecastHour,
                          minute: setting.eveningForecastMinute,
                          accentColor: DT.primary,
                        );
                        if (picked != null) {
                          notifier.update(setting.copyWith(
                            eveningForecastEnabled: true,
                            eveningForecastHour: picked.hour,
                            eveningForecastMinute: picked.minute,
                          ));
                        }
                      },
                    ),
                    SItem(
                      label: '귀가 후',
                      value: setting.eveningReturnEnabled
                          ? _fmtTime(setting.eveningReturnHour,
                              setting.eveningReturnMinute)
                          : '꺼짐',
                      onClick: () async {
                        final picked = await showCupertinoTimePicker(
                          context,
                          hour: setting.eveningReturnHour,
                          minute: setting.eveningReturnMinute,
                          accentColor: DT.primary,
                        );
                        if (picked != null) {
                          notifier.update(setting.copyWith(
                            eveningReturnEnabled: true,
                            eveningReturnHour: picked.hour,
                            eveningReturnMinute: picked.minute,
                          ));
                        }
                      },
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 실시간 ─────────────────────────────────────
                    const SLabel('실시간'),
                    SItem(
                      label: '실시간 경보',
                      trailing: SSwitch(
                        value: setting.realtimeAlertEnabled,
                        onChange: (v) => notifier.update(
                          setting.copyWith(realtimeAlertEnabled: v),
                        ),
                      ),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 방해 금지 ──────────────────────────────────
                    const SLabel('방해 금지'),
                    SItem(
                      label: '방해 금지 시간',
                      trailing: SSwitch(
                        value: setting.quietHoursEnabled,
                        onChange: (v) => notifier.update(
                          setting.copyWith(quietHoursEnabled: v),
                        ),
                      ),
                    ),
                    if (setting.quietHoursEnabled) ...[
                      SDndChild(
                        child: SItem(
                          label: '시작 시간',
                          value: _fmtHour(setting.quietHoursStartHour),
                          onClick: () async {
                            final picked = await showCupertinoTimePicker(
                              context,
                              hour: setting.quietHoursStartHour,
                              minute: 0,
                              accentColor: DT.gray,
                            );
                            if (picked != null) {
                              notifier.update(setting.copyWith(
                                quietHoursStartHour: picked.hour,
                              ));
                            }
                          },
                        ),
                      ),
                      SDndChild(
                        child: SItem(
                          label: '종료 시간',
                          value: _fmtHour(setting.quietHoursEndHour),
                          onClick: () async {
                            final picked = await showCupertinoTimePicker(
                              context,
                              hour: setting.quietHoursEndHour,
                              minute: 0,
                              accentColor: DT.gray,
                            );
                            if (picked != null) {
                              notifier.update(setting.copyWith(
                                quietHoursEndHour: picked.hour,
                              ));
                            }
                          },
                          last: true,
                        ),
                      ),
                    ],
                    const Divider(height: 1, color: DT.border),

                    // ── 알림 미리보기 ──────────────────────────────
                    const SLabel('알림 미리보기'),
                    const _SimulationButton(),
                  ],
                ),
              ),
            ),

            // ── 온보딩 전용 하단 버튼 ──────────────────────────────
            if (isOnboarding)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: AppButton.primary(
                  label: '설정 완료  →',
                  onTap: () async {
                    try {
                      await ref
                          .read(profileRepositoryProvider)
                          .completeOnboarding();
                    } catch (e, st) {
                      AppLogger.error(e, st,
                          reason: 'onboarding_complete_save');
                    }
                    if (!context.mounted) return;
                    context.go('/permission');
                  },
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
          foregroundColor: _sent ? DT.safe : DT.primary,
          side: BorderSide(
            color: _sent
                ? DT.safe
                : DT.primary.withValues(alpha: 0.5),
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
                    strokeWidth: 2, color: DT.primary),
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
