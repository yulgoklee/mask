import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

/// 알림 권한 요청 — 맥락 있는 설명 화면
class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final name = (profile.name != null && profile.name!.isNotEmpty)
        ? '${profile.name}님'
        : '님';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _ExampleRow(
                      icon: Icons.wb_sunny_outlined,
                      text: '외출 30분 전, 마스크 필요 여부를 알려드려요',
                    ),
                    const Divider(height: 20),
                    _ExampleRow(
                      icon: Icons.warning_amber_rounded,
                      text: '미세먼지가 급등하면 즉시 알려드려요',
                    ),
                    const Divider(height: 20),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Permission.notification.request();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushReplacementNamed('/onboarding_complete');
                    }
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
                    '알림 허용하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 건너뛰기
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed('/onboarding_complete'),
                  child: const Text(
                    '나중에 설정할게요',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
