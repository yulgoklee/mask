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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final setting = ref.watch(notificationSettingProvider);
    final name = (profile.name != null && profile.name!.isNotEmpty)
        ? '${profile.name}님'
        : '님';

    // 첫 번째로 켜진 알림 시간 표시
    String? firstAlertTime;
    if (setting.morningAlertEnabled) {
      firstAlertTime =
          '${setting.morningAlertHour.toString().padLeft(2, '0')}:${setting.morningAlertMinute.toString().padLeft(2, '0')}';
    } else if (setting.eveningForecastEnabled) {
      firstAlertTime =
          '${setting.eveningForecastHour.toString().padLeft(2, '0')}:${setting.eveningForecastMinute.toString().padLeft(2, '0')}';
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
                        '오늘 $firstAlertTime에\n마스크가 필요한지 먼저 알려드릴게요.',
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      )
                    else
                      const Text(
                        '미세먼지가 나빠지면\n바로 알려드릴게요.',
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
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/home'),
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
