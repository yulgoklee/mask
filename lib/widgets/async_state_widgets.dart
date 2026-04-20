import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'app_button.dart';

// ── 스켈레톤 공통 ──────────────────────────────────────────

/// 회색 직사각형 shimmer 블록
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.textHint.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// 홈 스크린 초기 로딩용 스켈레톤
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 위치 + 시간 행
          Row(
            children: [
              const _SkeletonBox(width: 16, height: 16, radius: 4),
              const SizedBox(width: 6),
              const _SkeletonBox(width: 100, height: 14),
              const Spacer(),
              const _SkeletonBox(width: 80, height: 12),
            ],
          ),
          const SizedBox(height: 20),
          // 위험도 카드
          const _SkeletonBox(
              width: double.infinity, height: 130, radius: 16),
          const SizedBox(height: 20),
          // 게이지 2열
          const Row(
            children: [
              Expanded(
                  child: _SkeletonBox(
                      width: double.infinity, height: 120, radius: 16)),
              SizedBox(width: 12),
              Expanded(
                  child: _SkeletonBox(
                      width: double.infinity, height: 120, radius: 16)),
            ],
          ),
          const SizedBox(height: 20),
          // 시간별 현황 카드
          const _SkeletonBox(
              width: double.infinity, height: 220, radius: 16),
        ],
      ),
    );
  }
}

/// 네트워크/데이터 오류 상태 위젯
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message = '데이터를 불러올 수 없어요.',
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: '다시 시도',
                onTap: onRetry,
                fullWidth: false,
                leading: const Icon(Icons.refresh, size: 18, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 데이터가 없는 빈 상태 위젯
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('새로고침'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 로딩 상태 위젯 (일관된 스타일)
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
