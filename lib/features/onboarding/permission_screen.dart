import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_hero.dart';

/// 알림 권한 요청 — 맥락 있는 설명 화면
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  // null = 조회 전, true/false = 실제 상태
  bool? _notifGranted;
  bool? _batteryGranted;
  // 배터리 다이얼로그를 1회 시도했는지 (거부 fallback UI 표시용)
  bool _batteryRequestAttempted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notifStatus = await Permission.notification.status;
    bool? batteryStatus;
    if (Platform.isAndroid) {
      final s = await Permission.ignoreBatteryOptimizations.status;
      batteryStatus = s.isGranted;
    }
    if (mounted) {
      setState(() {
        _notifGranted = notifStatus.isGranted;
        _batteryGranted = batteryStatus;
      });
    }
  }

  /// 알림 권한 요청 핸들러
  Future<void> _handleNotificationPermission(BuildContext context) async {
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
                  style: TextStyle(color: DT.gray)),
            ),
          ],
        ),
      ) ?? false;

      if (!proceed) return;
      if (!context.mounted) return;
      // 거부 선택 → 온보딩 완료로 넘어감
      context.go('/onboarding_complete');
      return;
    }

    // 알림 허용 성공 → 배터리 상태 재조회
    bool? batteryStatus;
    if (Platform.isAndroid) {
      final s = await Permission.ignoreBatteryOptimizations.status;
      batteryStatus = s.isGranted;
    }
    if (mounted) {
      setState(() {
        _notifGranted = true;
        _batteryGranted = batteryStatus;
      });
    }
  }

  /// 배터리 최적화 예외 요청 핸들러
  Future<void> _handleBatteryPermission(BuildContext context) async {
    final result = await Permission.ignoreBatteryOptimizations.request();
    if (mounted) {
      setState(() {
        _batteryGranted = result.isGranted;
        _batteryRequestAttempted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final displayName = profile.displayName;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: OnboardingBackground(
          child: SafeArea(
            child: _buildBody(context, displayName),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String displayName) {
    // 케이스 A: 초기 조회 중 → 케이스 B와 동일 헤드라인 + isLoading CTA
    if (_notifGranted == null) {
      return _buildNotifPendingState(context, displayName, loading: true);
    }

    // 케이스 B: 알림 권한 미허용
    if (_notifGranted == false) {
      return _buildNotifPendingState(context, displayName, loading: false);
    }

    // 알림 허용됨 → 배터리 분기
    // iOS: 배터리 단계 없으므로 곧바로 케이스 F
    if (!Platform.isAndroid) {
      return _buildAllGrantedState(context, displayName);
    }

    // 케이스 C: 배터리 상태 조회 중 → 케이스 D와 동일 헤드라인 + isLoading CTA
    if (_batteryGranted == null) {
      return _buildBatteryPendingState(context, displayName, loading: true);
    }

    // 케이스 D: 배터리 미허용 + 미시도
    if (_batteryGranted == false && !_batteryRequestAttempted) {
      return _buildBatteryPendingState(context, displayName, loading: false);
    }

    // 케이스 E: 배터리 미허용 + 시도 후 거부
    if (_batteryGranted == false && _batteryRequestAttempted) {
      return _buildBatteryRefusedState(context, displayName);
    }

    // 케이스 F: 모두 허용
    return _buildAllGrantedState(context, displayName);
  }

  // ── 케이스 A+B: 알림 권한 대기/미허용 (통합) ─────────────────────
  Widget _buildNotifPendingState(
      BuildContext context, String displayName, {required bool loading}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.notifications_active_outlined,
            size: 40,
            color: DT.primary,
          ),
          const SizedBox(height: 16),
          const OnboardingHero(
            main: '알림 권한이\n필요해요',
            heroSize: 40,
          ),
          const SizedBox(height: 24),
          const _ExampleRow(
            icon: Icons.wb_sunny_outlined,
            text: '외출 30분 전, 마스크 필요 여부를 알 수 있어요',
          ),
          const Divider(color: DT.border),
          const _ExampleRow(
            icon: Icons.warning_amber_rounded,
            text: '미세먼지가 급등하면 즉시 알 수 있어요',
          ),
          const Divider(color: DT.border),
          const _ExampleRow(
            icon: Icons.nights_stay_outlined,
            text: '내일 예보를 미리 확인할 수 있어요',
          ),
          const SizedBox(height: 16),
          const Text(
            '알림은 언제든 끌 수 있어요.',
            style: TextStyle(fontSize: 13, color: DT.gray2),
          ),
          const Spacer(),
          AppButton.primary(
            label: loading ? '확인 중...' : '알림 받기',
            onTap: loading ? null : () => _handleNotificationPermission(context),
            isLoading: loading,
          ),
          const SizedBox(height: 12),
          AppButton.text(
            label: '나중에 할게요',
            onTap: loading ? null : () => context.go('/onboarding_complete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── 케이스 C+D: 배터리 대기/미허용 (통합) ──────────────────────────
  Widget _buildBatteryPendingState(
      BuildContext context, String displayName, {required bool loading}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.battery_saver_outlined,
            size: 40,
            color: DT.caution,
          ),
          const SizedBox(height: 16),
          const OnboardingHero(
            main: '배터리 최적화\n예외를 허용해요',
            heroSize: 40,
          ),
          const SizedBox(height: 24),
          const _ExampleRow(
            icon: Icons.notifications_active_outlined,
            text: '알림 권한이 허용되었어요',
            iconColor: DT.safe,
          ),
          const Divider(color: DT.border),
          const _ExampleRow(
            icon: Icons.battery_saver_outlined,
            text: '배터리 최적화 예외를 허용하면 알림이 더 안정적이에요',
          ),
          const SizedBox(height: 8),
          const Text(
            '삼성·샤오미 등 일부 기기는 배터리 최적화로 알림이 늦을 수 있어요.',
            style: TextStyle(fontSize: 13, color: DT.gray2),
          ),
          const Spacer(),
          AppButton.primary(
            label: loading ? '확인 중...' : '배터리 최적화 받기',
            onTap: loading ? null : () => _handleBatteryPermission(context),
            isLoading: loading,
          ),
          const SizedBox(height: 12),
          AppButton.text(
            label: '나중에 할게요',
            onTap: loading ? null : () => context.go('/onboarding_complete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── 케이스 E: 배터리 거부 후 fallback ───────────────────────────────
  Widget _buildBatteryRefusedState(BuildContext context, String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.battery_alert_outlined,
            size: 40,
            color: DT.caution,
          ),
          const SizedBox(height: 16),
          const OnboardingHero(
            main: '배터리 최적화가\n허용되지 않았어요',
            heroSize: 40,
          ),
          const SizedBox(height: 24),
          const _ExampleRow(
            icon: Icons.notifications_active_outlined,
            text: '알림 권한이 허용되었어요',
            iconColor: DT.safe,
          ),
          const Divider(color: DT.border),
          const _ExampleRow(
            icon: Icons.battery_alert_outlined,
            text: '배터리 최적화 예외가 허용되지 않았어요',
            iconColor: DT.caution,
          ),
          const SizedBox(height: 8),
          const Text(
            '설정에서 직접 허용할 수 있어요. 허용하지 않아도 앱은 정상 사용할 수 있지만 일부 기기에서 알림이 늦을 수 있어요.',
            style: TextStyle(fontSize: 13, color: DT.gray2, height: 1.5),
          ),
          const Spacer(),
          AppButton.primary(
            label: '설정 열기',
            onTap: () => openAppSettings(),
          ),
          const SizedBox(height: 12),
          AppButton.text(
            label: '건너뛰기',
            onTap: () => context.go('/onboarding_complete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── 케이스 F: 모두 허용 ─────────────────────────────────────────────
  Widget _buildAllGrantedState(BuildContext context, String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: DT.safe,
          ),
          const SizedBox(height: 16),
          OnboardingHero(
            main: displayName.isNotEmpty
                ? '$displayName,\n모두 준비됐어요!'
                : '모두 준비됐어요!',
            heroSize: 40,
          ),
          const SizedBox(height: 24),
          const _ExampleRow(
            icon: Icons.notifications_active_outlined,
            text: '알림 권한이 허용되었어요',
            iconColor: DT.safe,
          ),
          if (Platform.isAndroid) ...[
            const Divider(color: DT.border),
            const _ExampleRow(
              icon: Icons.battery_saver_outlined,
              text: '배터리 최적화 예외가 허용되었어요',
              iconColor: DT.safe,
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: DT.safe.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: DT.safe.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: DT.safe, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '모든 권한이 허용되었어요',
                    style: TextStyle(
                      fontSize: 14,
                      color: DT.safe,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          AppButton.primary(
            label: '다음',
            onTap: () => context.go('/onboarding_complete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _ExampleRow({
    required this.icon,
    required this.text,
    this.iconColor = DT.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: DT.gray,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
