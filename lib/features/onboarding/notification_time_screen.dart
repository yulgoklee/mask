import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/services/app_logger.dart';
import '../../features/settings/widgets/s_dnd_child.dart';
import '../../features/settings/widgets/s_item.dart';
import '../../features/settings/widgets/s_switch.dart';
import '../../features/settings/widgets/settings_drill_header.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/time_picker_sheet.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_hero.dart';

/// 알림 시간 설정 화면
///
/// [isOnboarding] = true: 온보딩 플로우에서 진입. 하단 "설정 완료→" 버튼 표시.
/// [isOnboarding] = false(기본): 설정에서 push. 하단 버튼 없음.
class NotificationTimeScreen extends ConsumerWidget {
  final bool isOnboarding;

  const NotificationTimeScreen({super.key, this.isOnboarding = false});

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
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 ──────────────────────────────────────────────
              if (isOnboarding)
                _OnboardingTopBar(onBack: () => context.pop())
              else
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
                      // ── Hero 영역 ──────────────────────────────────
                      const SizedBox(height: 16),
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 40,
                        color: DT.primary,
                      ),
                      const SizedBox(height: 16),
                      const OnboardingHero(
                        main: '알림은 언제\n받을까요?',
                        sub: '내 일상에 맞게 시간을 골라요',
                        heroSize: 40,
                      ),
                      const SizedBox(height: 32),

                      // ── 스케줄 알림 섹션 라벨 ─────────────────────
                      const Text(
                        '스케줄 알림',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DT.gray2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── 스케줄 알림 3개 ───────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: DT.border, width: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _TimeRow(
                              icon: Icons.directions_walk,
                              label: '외출 전',
                              sub: '출근·등교 전 마스크 챙길지 알려줘요',
                              enabled: setting.morningAlertEnabled,
                              hour: setting.morningAlertHour,
                              minute: setting.morningAlertMinute,
                              onEnabledChanged: (v) => notifier.update(
                                setting.copyWith(morningAlertEnabled: v),
                              ),
                              onTimeTap: () async {
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
                            _TimeRow(
                              icon: Icons.nights_stay_outlined,
                              label: '전날 예보',
                              sub: '내일 공기 예보를 미리 보여줘요',
                              enabled: setting.eveningForecastEnabled,
                              hour: setting.eveningForecastHour,
                              minute: setting.eveningForecastMinute,
                              onEnabledChanged: (v) => notifier.update(
                                setting.copyWith(eveningForecastEnabled: v),
                              ),
                              onTimeTap: () async {
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
                            _TimeRow(
                              icon: Icons.home_outlined,
                              label: '귀가 후',
                              sub: '오늘 노출량을 정리해 보여줘요',
                              enabled: setting.eveningReturnEnabled,
                              hour: setting.eveningReturnHour,
                              minute: setting.eveningReturnMinute,
                              onEnabledChanged: (v) => notifier.update(
                                setting.copyWith(eveningReturnEnabled: v),
                              ),
                              onTimeTap: () async {
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 실시간 경보 ────────────────────────────────
                      const Text(
                        '실시간',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DT.gray2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: DT.border, width: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SItem(
                          label: '실시간 경보',
                          trailing: SSwitch(
                            value: setting.realtimeAlertEnabled,
                            onChange: (v) => notifier.update(
                              setting.copyWith(realtimeAlertEnabled: v),
                            ),
                          ),
                          last: true,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 방해 금지 ──────────────────────────────────
                      const Text(
                        '방해 금지',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DT.gray2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: DT.border, width: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            SItem(
                              label: '방해 금지 시간',
                              trailing: SSwitch(
                                value: setting.quietHoursEnabled,
                                onChange: (v) => notifier.update(
                                  setting.copyWith(quietHoursEnabled: v),
                                ),
                              ),
                              last: !setting.quietHoursEnabled,
                            ),
                            if (setting.quietHoursEnabled) ...[
                              SDndChild(
                                child: SItem(
                                  label: '시작 시간',
                                  value: _fmtHour(setting.quietHoursStartHour),
                                  onClick: () async {
                                    final picked =
                                        await showCupertinoTimePicker(
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
                                    final picked =
                                        await showCupertinoTimePicker(
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 알림 미리보기 ──────────────────────────────
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
                    label: '설정 완료',
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
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  온보딩 전용 상단 바
// ══════════════════════════════════════════════════════════════

class _OnboardingTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _OnboardingTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: DT.text,
            ),
            onPressed: onBack,
          ),
          const Spacer(),
          const Text(
            '거의 다 왔어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DT.gray,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  스케줄 알림 행 위젯 (끄기 스위치 + 시간 탭)
// ══════════════════════════════════════════════════════════════

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onTimeTap;
  final bool last;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onEnabledChanged,
    required this.onTimeTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: DT.border, width: 0.5),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: enabled ? DT.primary : DT.gray2),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: enabled ? DT.text : DT.gray2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DT.gray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled) ...[
              GestureDetector(
                onTap: onTimeTap,
                child: Text(
                  _formatTime(hour, minute),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DT.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            SSwitch(
              value: enabled,
              onChange: onEnabledChanged,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(int hour, int minute) {
  final period = hour < 12 ? '오전' : '오후';
  final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final m = minute.toString().padLeft(2, '0');
  return '$period $h:$m';
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
                  ? '알림이 전송됐어요'
                  : _loading
                      ? '전송 중...'
                      : '미리 보기',
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
          content: const Text('알림 권한이 필요해요. 다음 화면에서 허용할 수 있어요.'),
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
