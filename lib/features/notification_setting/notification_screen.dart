import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/background_service.dart';
import '../../core/services/notification_scheduler.dart';
import '../../core/services/notification_service.dart';
import '../../providers/providers.dart';

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
          _InfoBox(
            text: '알림은 설정 시간 ±30분 내에 발송돼요.\n'
                '앱을 설치한 기기에서 실시간 미세먼지 데이터를 가져와 개인 프로필 기준으로 안내해요.',
          ),
          const SizedBox(height: 20),

          _SectionLabel('매일 알림'),
          const SizedBox(height: 10),

          // 오전 알림
          _NotifCard(
            icon: Icons.wb_sunny_outlined,
            title: '외출 전 알림',
            subtitle: '매일 아침 오늘 미세먼지 상태 안내',
            example: '예) "오늘 PM2.5 나쁨. 마스크를 꼭 착용하세요."',
            enabled: setting.morningAlertEnabled,
            timeLabel: _timeLabel(
                setting.morningAlertHour, setting.morningAlertMinute),
            onToggle: (v) =>
                notifier.update(setting.copyWith(morningAlertEnabled: v)),
            onTimeTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: setting.morningAlertHour,
                    minute: setting.morningAlertMinute),
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
          _NotifCard(
            icon: Icons.nights_stay_outlined,
            title: '전날 예보 알림',
            subtitle: '내일 미세먼지 예보 안내',
            example: '예) "내일 예보: 나쁨. 출근 시 마스크를 챙겨두세요."',
            enabled: setting.eveningForecastEnabled,
            timeLabel: _timeLabel(
                setting.eveningForecastHour, setting.eveningForecastMinute),
            onToggle: (v) =>
                notifier.update(setting.copyWith(eveningForecastEnabled: v)),
            onTimeTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: setting.eveningForecastHour,
                    minute: setting.eveningForecastMinute),
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
          _NotifCard(
            icon: Icons.home_outlined,
            title: '귀가 후 알림',
            subtitle: '퇴근 시간 미세먼지 확인 안내',
            example: '예) "퇴근 시간 나쁨이에요. 마스크 챙기셨나요?"',
            enabled: setting.eveningReturnEnabled,
            timeLabel: _timeLabel(
                setting.eveningReturnHour, setting.eveningReturnMinute),
            onToggle: (v) =>
                notifier.update(setting.copyWith(eveningReturnEnabled: v)),
            onTimeTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: setting.eveningReturnHour,
                    minute: setting.eveningReturnMinute),
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

          _SectionLabel('실시간 경보'),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.dustBad, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '예) "⚠️ 미세먼지 경보. 지금 바로 마스크를 착용하세요."',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: setting.realtimeAlertEnabled,
                  onChanged: (v) =>
                      notifier.update(setting.copyWith(realtimeAlertEnabled: v)),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 알림 테스트
          _SectionLabel('알림 테스트'),
          const SizedBox(height: 10),
          _NotifTestCard(),
          const SizedBox(height: 24),

          // 백그라운드 테스트 (디버그 빌드에서만 표시)
          if (kDebugMode) ...[
            _SectionLabel('백그라운드 테스트 (개발용)'),
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

  String _timeLabel(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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
            '알림이 제대로 오는지 확인해보세요.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendTest,
              icon: _sending
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(_sending ? '발송 중...' : '테스트 알림 보내기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
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
        color: AppColors.primary.withOpacity(0.08),
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

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String example;
  final bool enabled;
  final String timeLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _NotifCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.example,
    required this.enabled,
    required this.timeLabel,
    required this.onToggle,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.primary.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon,
                  color: enabled ? AppColors.primary : AppColors.textHint,
                  size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
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
          if (enabled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text('알림 시간',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                GestureDetector(
                  onTap: onTimeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                example,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
