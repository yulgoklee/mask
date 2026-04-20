import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

/// 온보딩 완료 화면 — "준비됐어요, [이름]님"
class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  ConsumerState<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState
    extends ConsumerState<OnboardingCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 24h 시간 → "오전/오후 H:MM" 형식
  static String _formatTime(int hour, int minute) {
    final period = hour < 12 ? '오전' : '오후';
    final h = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$period $h:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final setting = ref.watch(notificationSettingProvider);
    // notification_time에서 시작된 dustData 패치를 홈 도달까지 살려둠
    ref.watch(dustDataProvider);
    final name = profile.displayName;

    // 첫 번째로 켜진 알림 시간 표시 (우선순위: 외출 전 → 전날 예보 → 귀가 후)
    String? firstAlertTime;
    String? firstAlertLabel;
    if (setting.morningAlertEnabled) {
      firstAlertTime = _formatTime(setting.morningAlertHour, setting.morningAlertMinute);
      firstAlertLabel = '외출 전';
    } else if (setting.eveningForecastEnabled) {
      firstAlertTime = _formatTime(setting.eveningForecastHour, setting.eveningForecastMinute);
      firstAlertLabel = '전날 예보';
    } else if (setting.eveningReturnEnabled) {
      firstAlertTime = _formatTime(setting.eveningReturnHour, setting.eveningReturnMinute);
      firstAlertLabel = '귀가 후';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fadeIn,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),

                    // 완료 아이콘
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      '준비됐어요, $name 🎉',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (firstAlertTime != null)
                      Text(
                        '$firstAlertLabel 알림을 $firstAlertTime에\n보내드릴게요.',
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      )
                    else
                      const Text(
                        '알림을 모두 끄셨어요.\n앱을 열면 언제든 오늘의\n미세먼지를 확인할 수 있어요.',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                    const Spacer(flex: 3),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 만약 패치가 아직 안 됐으면 강제 재시작
                          if (ref.read(dustDataProvider).hasValue == false) {
                            ref.invalidate(dustDataProvider);
                          }
                          context.go('/care');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '시작하기',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
