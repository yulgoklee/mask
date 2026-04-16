import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/notification_setting.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';

final _analytics = FirebaseAnalytics.instance;

/// Phase 4: 알림 커스텀 & 가상 시뮬레이션 화면
///
/// 알림 시간 + 페르소나(Voice) 선택 후
/// [설정 완료 및 테스트 알림 받기] 버튼으로 실제 로컬 푸시 발송.
/// 이 화면에서 UserProfile + NotificationSetting을 단 1회 저장합니다.
class NotificationCustomScreen extends ConsumerStatefulWidget {
  const NotificationCustomScreen({super.key});

  @override
  ConsumerState<NotificationCustomScreen> createState() =>
      _NotificationCustomScreenState();
}

class _NotificationCustomScreenState
    extends ConsumerState<NotificationCustomScreen> {
  // 알림 시간 (기본: 오전 8시)
  int _alertHour   = 8;
  int _alertMinute = 0;

  // 알림 페르소나
  String _voice = NotificationVoice.friendly;

  // 시뮬레이션 상태
  bool _isSending  = false;
  bool _simDone    = false;

  @override
  Widget build(BuildContext context) {
    final profile =
        ModalRoute.of(context)?.settings.arguments as UserProfile? ??
            UserProfile.defaultProfile();

    final timeStr =
        '${_alertHour.toString().padLeft(2, '0')}:${_alertMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 스테퍼 (3단계 활성)
              const _MiniStepper(activeStep: 2),
              const SizedBox(height: 20),

              // 타이틀
              Text(
                '${profile.displayName},\n알림을 설계해 드릴게요.',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '직접 설계한 알림으로 공기 케어를 받아보세요.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // ─ 알림 시간 설정 ─
              _SectionTitle(
                  icon: Icons.access_time_rounded, title: '알림 시간'),
              const SizedBox(height: 12),
              _TimePickerCard(
                hour: _alertHour,
                minute: _alertMinute,
                onTap: () => _pickTime(context),
              ),
              const SizedBox(height: 24),

              // ─ 알림 페르소나 선택 ─
              _SectionTitle(
                  icon: Icons.record_voice_over_rounded, title: '알림 목소리'),
              const SizedBox(height: 12),
              _VoiceCard(
                voice: NotificationVoice.friendly,
                isSelected: _voice == NotificationVoice.friendly,
                onTap: () =>
                    setState(() => _voice = NotificationVoice.friendly),
              ),
              const SizedBox(height: 10),
              _VoiceCard(
                voice: NotificationVoice.analytical,
                isSelected: _voice == NotificationVoice.analytical,
                onTap: () =>
                    setState(() => _voice = NotificationVoice.analytical),
              ),
              const SizedBox(height: 32),

              // ─ 시뮬레이션 버튼 ─
              _SimulationButton(
                profile: profile,
                voice: _voice,
                alertHour: _alertHour,
                alertMinute: _alertMinute,
                isSending: _isSending,
                simDone: _simDone,
                onTap: () => _startSimulation(profile),
              ),

              if (_simDone) ...[
                const SizedBox(height: 20),
                _SimDoneCard(
                  profile: profile,
                  timeStr: timeStr,
                  onGoHome: () => _saveAndGoHome(profile),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 시간 피커 ──────────────────────────────────────────────

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _alertHour, minute: _alertMinute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.splashBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _alertHour   = picked.hour;
        _alertMinute = picked.minute;
        _simDone     = false; // 시간 변경 시 시뮬 초기화
      });
    }
  }

  // ── 가상 시뮬레이션 ────────────────────────────────────────

  Future<void> _startSimulation(UserProfile profile) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    _analytics.logEvent(name: 'simulation_started');

    // 3초 후 실제 로컬 푸시 발송
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    try {
      final setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: _alertHour,
        morningAlertMinute: _alertMinute,
        notificationVoice: _voice,
      );

      final notifService = NotificationService();
      await notifService.initialize();
      await notifService.requestPermission();
      await notifService.showImmediateNotification(
        id: NotificationService.simulationAlertId,
        title: '${profile.displayName} 가디언 세팅 완료! 🎉',
        body: NotificationService.simulationMessage(
          profile: profile,
          setting: setting,
        ),
      );

      _analytics.logEvent(name: 'simulation_completed');
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSending = false;
        _simDone   = true;
      });
    }
  }

  // ── 저장 후 홈으로 ─────────────────────────────────────────

  Future<void> _saveAndGoHome(UserProfile profile) async {
    // Phase 4 완료 시점에 단 1회 저장
    try {
      final setting = NotificationSetting(
        morningAlertEnabled: true,
        morningAlertHour: _alertHour,
        morningAlertMinute: _alertMinute,
        notificationVoice: _voice,
      );

      // UserProfile 저장
      await ref.read(profileProvider.notifier).saveProfile(profile);

      // NotificationSetting 저장
      await ref
          .read(notificationSettingProvider.notifier)
          .update(setting);

      // 온보딩 완료 플래그 저장
      await ref.read(profileRepositoryProvider).completeOnboarding();

      _analytics.logEvent(name: 'onboarding_setup_complete');
    } catch (_) {
      // 저장 실패해도 홈으로 진행
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/location_setup');
    }
  }
}

// ── 섹션 타이틀 ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.splashBackground),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── 알림 시간 카드 ────────────────────────────────────────────

class _TimePickerCard extends StatelessWidget {
  final int hour;
  final int minute;
  final VoidCallback onTap;

  const _TimePickerCard({
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.splashBackground.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_sunny_outlined,
                  color: AppColors.splashBackground, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '외출 전 알림',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.splashBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_outlined,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 알림 페르소나 카드 ────────────────────────────────────────

class _VoiceCard extends StatelessWidget {
  final String voice;
  final bool isSelected;
  final VoidCallback onTap;

  const _VoiceCard({
    required this.voice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = voice == NotificationVoice.friendly ? '😊' : '🔬';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.splashBackground.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.splashBackground
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NotificationVoice.label(voice),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.splashBackground
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NotificationVoice.description(voice),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.splashBackground,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ── 시뮬레이션 버튼 ──────────────────────────────────────────

class _SimulationButton extends StatelessWidget {
  final UserProfile profile;
  final String voice;
  final int alertHour;
  final int alertMinute;
  final bool isSending;
  final bool simDone;
  final VoidCallback onTap;

  const _SimulationButton({
    required this.profile,
    required this.voice,
    required this.alertHour,
    required this.alertMinute,
    required this.isSending,
    required this.simDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: simDone || isSending ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: simDone
              ? AppColors.success.withOpacity(0.1)
              : isSending
                  ? AppColors.splashBackground.withOpacity(0.5)
                  : AppColors.splashBackground,
          borderRadius: BorderRadius.circular(20),
          border: simDone
              ? Border.all(color: AppColors.success, width: 2)
              : null,
        ),
        child: Center(
          child: isSending
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '3초 후 테스트 알림 발송 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  simDone ? '✅ 테스트 알림 발송 완료!' : '설정 완료 및 테스트 알림 받기 🔔',
                  style: TextStyle(
                    color: simDone ? AppColors.success : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── 시뮬레이션 완료 카드 ──────────────────────────────────────

class _SimDoneCard extends StatelessWidget {
  final UserProfile profile;
  final String timeStr;
  final VoidCallback onGoHome;

  const _SimDoneCard({
    required this.profile,
    required this.timeStr,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '내일 아침 $timeStr,\n첫 보고서를 들고 올게요!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.displayName}의 기준선 '
            '${profile.tFinal.toStringAsFixed(0)}μg/m³을 기준으로\n'
            '맞춤 알림을 보내드릴게요.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGoHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '가디언 시작하기 →',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 미니 스테퍼 ───────────────────────────────────────────────

class _MiniStepper extends StatelessWidget {
  final int activeStep;
  const _MiniStepper({required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['진단', '분석', '세팅'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 1.5,
              color: i ~/ 2 < activeStep
                  ? AppColors.splashBackground
                  : AppColors.divider,
            ),
          );
        }
        final idx = i ~/ 2;
        final isActive = idx == activeStep;
        final isDone = idx < activeStep;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive || isDone
                ? AppColors.splashBackground
                : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
