import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// 알림 권한 요청 — 맥락 있는 설명 화면
class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final name = profile.displayName;

    return PopScope(
      canPop: false, // 권한 화면에서 뒤로가기로 notification_time 스택 없어 앱 종료 방지
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                '$name 하루를\n챙기려면 알림 권한이 필요해요',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // 알림 예시 카드
              AppCard(
                padding: const EdgeInsets.all(AppTokens.cardMd),
                child: const Column(
                  children: [
                    _ExampleRow(
                      icon: Icons.wb_sunny_outlined,
                      text: '외출 30분 전, 마스크 필요 여부를 알려드려요',
                    ),
                    Divider(height: 20),
                    _ExampleRow(
                      icon: Icons.warning_amber_rounded,
                      text: '미세먼지가 급등하면 즉시 알려드려요',
                    ),
                    Divider(height: 20),
                    _ExampleRow(
                      icon: Icons.nights_stay_outlined,
                      text: '내일 예보를 미리 알려드려요',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '알림은 언제든 끌 수 있어요.',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),

              const Spacer(),

              // 권한 허용 버튼
              AppButton.primary(
                label: '알림 허용하기',
                onTap: () async {
                  var status = await Permission.notification.status;
                  if (!status.isGranted) {
                    status = await Permission.notification.request();
                  }

                  if (!context.mounted) return;

                  if (status.isDenied || status.isPermanentlyDenied) {
                    final proceed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
                        title: const Text('알림 없이 계속할까요?',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        content: const Text(
                          '알림 권한이 없으면 미세먼지 경보를 받을 수 없어요.\n설정에서 언제든 다시 허용할 수 있어요.',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                        actions: [
                          if (status.isPermanentlyDenied)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                                openAppSettings();
                              },
                              child: const Text('설정 열기'),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('알림 없이 계속',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (!proceed) return;
                    if (!context.mounted) return;
                  }

                  context.go('/onboarding_complete');
                },
              ),
              const SizedBox(height: 12),

              // 건너뛰기
              AppButton.text(
                label: '나중에 설정할게요',
                onTap: () => context.go('/onboarding_complete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }
}

class _ExampleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ExampleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
