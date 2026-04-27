import 'dart:io';
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
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  late final Future<bool> _notifGrantedFuture;

  @override
  void initState() {
    super.initState();
    _notifGrantedFuture =
        Permission.notification.status.then((s) => s.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final name = profile.displayName;

    return PopScope(
      canPop: false, // 권한 화면에서 뒤로가기로 notification_time 스택 없어 앱 종료 방지
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: _notifGrantedFuture,
            builder: (context, snapshot) {
              final notifGranted = snapshot.data ?? false;
              return _buildBody(context, name, notifGranted);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String name, bool notifGranted) {
    return Padding(
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
              color: notifGranted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              notifGranted
                  ? Icons.check_circle_outline
                  : Icons.notifications_active_outlined,
              color: notifGranted ? AppColors.success : AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 32),

          // 타이틀
          Text(
            notifGranted
                ? (name.isNotEmpty ? '$name, 한 가지 더 있어요' : '한 가지 더 있어요')
                : (name.isNotEmpty
                    ? '$name 하루를\n챙기려면 알림 권한이 필요해요'
                    : '하루를\n챙기려면 알림 권한이 필요해요'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // 알림 상태 카드
          if (notifGranted) ...[
            // 상태 B: 알림 권한 확인 카드 (성공 톤)
            AppCard(
              padding: const EdgeInsets.all(AppTokens.cardMd),
              child: const _ExampleRow(
                icon: Icons.notifications_active_outlined,
                text: '알림 권한이 허용되었어요',
                iconColor: AppColors.success,
              ),
            ),
          ] else ...[
            // 상태 A: 알림 예시 카드
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
          ],

          // 배터리 최적화 카드 (Android 전용)
          if (Platform.isAndroid) ...[
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(AppTokens.cardMd),
              child: const Column(
                children: [
                  _ExampleRow(
                    icon: Icons.battery_saver_outlined,
                    text: '배터리 최적화 예외로 설정하면 알림이 더 안정적이에요',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '삼성·샤오미 등 일부 기기는 배터리 최적화로 알림이 늦을 수 있어요.',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],

          const Spacer(),

          // 권한 허용 버튼
          AppButton.primary(
            label: notifGranted ? '배터리 최적화 받기' : '알림 받기',
            onTap: () => _handlePrimary(context, notifGranted),
          ),
          const SizedBox(height: 12),

          // 건너뛰기
          AppButton.text(
            label: '나중에 할게요',
            onTap: () => context.go('/onboarding_complete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handlePrimary(BuildContext context, bool notifGranted) async {
    if (!notifGranted) {
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ) ?? false;

        if (!proceed) return;
        if (!context.mounted) return;
      }
    }

    // 배터리 최적화 예외 요청 (Android 전용, 거부해도 계속 진행)
    if (Platform.isAndroid) {
      final batteryStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    if (!context.mounted) return;
    context.go('/onboarding_complete');
  }
}

class _ExampleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _ExampleRow({
    required this.icon,
    required this.text,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
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
