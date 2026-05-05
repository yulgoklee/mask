import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/services/background_service.dart';
import '../../core/services/notification_scheduler.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/notification_setting.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/notif_card.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with WidgetsBindingObserver {
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (kIsWeb) return;
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _permissionGranted = status.isGranted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(notificationSettingProvider);
    final notifier = ref.read(notificationSettingProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '알림 설정',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 권한 거부 배너
          if (!_permissionGranted) ...[
            _PermissionBanner(onTap: () async {
              await openAppSettings();
            }),
            const SizedBox(height: 16),
          ],

          // 알림 작동 방식 안내
          const _InfoBox(
            text: '알림은 설정 시간 ±15분 내에 발송돼요.\n'
                '앱을 설치한 기기에서 실시간 미세먼지 데이터를 가져와 개인 프로필 기준으로 안내해요.',
          ),
          const SizedBox(height: 20),

          const _SectionLabel('매일 알림'),
          const SizedBox(height: 10),

          // 외출 전 알림
          NotifCard(
            emoji: '🌅',
            title: '외출 전 알림',
            subtitle: '매일 아침 오늘 미세먼지 상태 안내',
            accentColor: AppColors.notifMorning,
            enabled: setting.morningAlertEnabled,
            hour: setting.morningAlertHour,
            minute: setting.morningAlertMinute,
            exampleText: '예) "현재 PM2.5 32µg/m³로 내 기준을 넘어요. 외출 시 KF80 이상 권장이에요."',
            onToggle: (v) =>
                notifier.update(setting.copyWith(morningAlertEnabled: v)),
            onTimeTap: () async {
              final picked = await showCupertinoTimePicker(
                context,
                hour: setting.morningAlertHour,
                minute: setting.morningAlertMinute,
                accentColor: AppColors.notifMorning,
              );
              if (picked != null) {
                notifier.update(setting.copyWith(
                  morningAlertHour: picked.hour,
                  morningAlertMinute: picked.minute,
                ));
              }
            },
          ),
          const SizedBox(height: 12),

          // 전날 예보
          NotifCard(
            emoji: '🌙',
            title: '전날 예보 알림',
            subtitle: '내일 미세먼지 예보 안내',
            accentColor: AppColors.notifEvening,
            enabled: setting.eveningForecastEnabled,
            hour: setting.eveningForecastHour,
            minute: setting.eveningForecastMinute,
            exampleText: '예) "내일 예보: 나쁨. 출근 시 마스크를 챙겨두세요."',
            onToggle: (v) =>
                notifier.update(setting.copyWith(eveningForecastEnabled: v)),
            onTimeTap: () async {
              final picked = await showCupertinoTimePicker(
                context,
                hour: setting.eveningForecastHour,
                minute: setting.eveningForecastMinute,
                accentColor: AppColors.notifEvening,
              );
              if (picked != null) {
                notifier.update(setting.copyWith(
                  eveningForecastHour: picked.hour,
                  eveningForecastMinute: picked.minute,
                ));
              }
            },
          ),
          const SizedBox(height: 12),

          // 귀가 알림
          NotifCard(
            emoji: '🏠',
            title: '귀가 후 알림',
            subtitle: '퇴근 시간 미세먼지 확인 안내',
            accentColor: AppColors.notifReturn,
            enabled: setting.eveningReturnEnabled,
            hour: setting.eveningReturnHour,
            minute: setting.eveningReturnMinute,
            exampleText: '예) "퇴근 시간 나쁨이에요. 마스크 챙기셨나요?"',
            onToggle: (v) =>
                notifier.update(setting.copyWith(eveningReturnEnabled: v)),
            onTimeTap: () async {
              final picked = await showCupertinoTimePicker(
                context,
                hour: setting.eveningReturnHour,
                minute: setting.eveningReturnMinute,
                accentColor: AppColors.notifReturn,
              );
              if (picked != null) {
                notifier.update(setting.copyWith(
                  eveningReturnHour: picked.hour,
                  eveningReturnMinute: picked.minute,
                ));
              }
            },
          ),
          const SizedBox(height: 24),

          const _SectionLabel('실시간 경보'),
          const SizedBox(height: 10),

          // 실시간 경보 (시간 선택 없음)
          NotifCard(
            emoji: '⚠️',
            title: '실시간 경보',
            subtitle: '미세먼지 급등 시 즉시 알림',
            accentColor: AppColors.dustBad,
            enabled: setting.realtimeAlertEnabled,
            hour: 0,
            minute: 0,
            exampleText: '예) "⚠️ 미세먼지가 급격히 나빠졌어요. 외출 시 KF94 이상 권장이에요."',
            onToggle: (v) =>
                notifier.update(setting.copyWith(realtimeAlertEnabled: v)),
          ),

          const SizedBox(height: 24),

          const _SectionLabel('방해 금지 시간'),
          const SizedBox(height: 10),
          _QuietHoursCard(setting: setting, notifier: notifier),
          const SizedBox(height: 24),

          // 알림 미리 받아보기
          const _SectionLabel('알림 미리 받아보기'),
          const SizedBox(height: 10),
          _NotifTestCard(),
          const SizedBox(height: 24),

          // 백그라운드 테스트 (디버그 빌드에서만 표시)
          if (kDebugMode) ...[
            const _SectionLabel('백그라운드 테스트 (개발용)'),
            const SizedBox(height: 10),
            _BgTestCard(),
            const SizedBox(height: 24),
          ],

          const Text(
            '* 알림은 참고용 정보이며 의료적 진단이나 처방을 대체하지 않습니다.\n'
            '* 배터리 절약 모드나 기기 설정에 따라 알림이 지연될 수 있어요.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _NotifTestCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotifTestCard> createState() => _NotifTestCardState();
}

class _NotifTestCardState extends ConsumerState<_NotifTestCard> {
  bool _sending = false;
  String? _result;

  Future<void> _sendTest() async {
    setState(() { _sending = true; _result = null; });

    try {
      final notifService = ref.read(notificationServiceProvider);
      final dustAsync = ref.read(dustDataProvider);
      final calcResult = ref.read(dustCalculationProvider);
      final dust = dustAsync.value;

      final pm25 = dust?.pm25Value ?? 35;
      final gradeName = dust?.pm25Grade ?? '보통';
      final profile = ref.read(profileProvider);
      final maskType = calcResult?.maskType;

      final content = NotificationService.morningContent(
        profile: profile,
        pm25: pm25,
        gradeName: gradeName,
        maskRequired: calcResult?.maskRequired ?? false,
        maskType: maskType,
      );

      await notifService.showImmediateNotification(
        id: 99,
        title: content.title,
        body: content.body,
      );
      setState(() { _result = '✓ 알림 발송 완료! 상단 알림을 확인하세요.'; });
    } catch (e) {
      setState(() { _result = '✗ 발송 실패: $e'; });
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내가 받을 알림이 어떻게 보이는지 확인해보세요.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            label: _sending ? '발송 중...' : '지금 한 번 받아보기',
            onTap: _sending ? null : _sendTest,
            isLoading: _sending,
            leading: _sending
                ? null
                : const Icon(Icons.notifications_active_outlined,
                    size: 18, color: Colors.white),
          ),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(
              _result!,
              style: TextStyle(
                fontSize: 13,
                color: _result!.startsWith('✓')
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 백그라운드 스케줄러 직접 실행 카드 (kDebugMode 에서만 표시)
class _BgTestCard extends StatefulWidget {
  @override
  State<_BgTestCard> createState() => _BgTestCardState();
}

class _BgTestCardState extends State<_BgTestCard> {
  bool _running = false;
  String? _result;

  /// 방법 1: Workmanager oneOff 태스크 → 실제 백그라운드 isolate 실행
  Future<void> _runViaWorkmanager() async {
    setState(() { _running = true; _result = null; });
    try {
      await BackgroundService.runOnce();
      setState(() {
        _result = '✓ Workmanager 태스크 등록 완료.\n'
            '앱을 백그라운드로 내리면 곧 실행돼요.\n'
            'Android 에뮬레이터: adb logcat 으로 확인 가능';
      });
    } catch (e) {
      setState(() { _result = '✗ 오류: $e'; });
    } finally {
      setState(() => _running = false);
    }
  }

  /// 방법 2: 스케줄러 로직 직접 호출 → 시간 윈도우 체크 포함, 즉시 실행
  Future<void> _runSchedulerDirect() async {
    setState(() { _running = true; _result = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await NotificationScheduler().runCheck(prefs);
      setState(() {
        _result = '✓ 스케줄러 실행 완료.\n'
            '알림 시간 윈도우 내에 있으면 알림이 발송됐어요.\n'
            '(오늘 이미 발송된 알림은 중복 방지로 건너뜀)';
      });
    } catch (e) {
      setState(() { _result = '✗ 오류: $e'; });
    } finally {
      setState(() => _running = false);
    }
  }

  /// 중복 방지 플래그 초기화 → 오늘 날짜 기준 발송 기록 삭제
  Future<void> _resetSentFlags() async {
    setState(() { _running = true; _result = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final hourKey = '$dateKey${now.hour.toString().padLeft(2, '0')}';
      for (final type in ['morning', 'forecast', 'return']) {
        await prefs.remove('notif_sent_${type}_$dateKey');
      }
      await prefs.remove('notif_sent_realtime_$hourKey');
      setState(() { _result = '✓ 중복 방지 초기화 완료. 이제 스케줄러를 다시 실행해보세요.'; });
    } catch (e) {
      setState(() { _result = '✗ 오류: $e'; });
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bug_report_outlined, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 6),
            Text('개발용 — 릴리즈 빌드에서는 숨겨짐',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _running ? null : _runSchedulerDirect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('스케줄러 실행', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _running ? null : _resetSentFlags,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('중복방지 초기화', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _running ? null : _runViaWorkmanager,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Workmanager', style: TextStyle(fontSize: 13)),
              ),
            ),
          ]),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(_result!,
                style: TextStyle(
                  fontSize: 12,
                  color: _result!.startsWith('✓')
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  height: 1.4,
                )),
          ],
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined,
                color: Colors.red.shade400, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '알림 권한이 꺼져있어요. 탭하여 설정에서 허용해주세요.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.red.shade400),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  방해 금지 시간 카드
// ══════════════════════════════════════════════════════════════

class _QuietHoursCard extends StatelessWidget {
  final NotificationSetting setting;
  final NotificationSettingNotifier notifier;

  const _QuietHoursCard({required this.setting, required this.notifier});

  String _hourLabel(int hour) {
    final period = hour < 12 ? '오전' : '오후';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $display시';
  }

  @override
  Widget build(BuildContext context) {
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
