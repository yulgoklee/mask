import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 온보딩 시작 전 로드맵 소개 화면
///
/// [진단] → [분석] → [세팅] 3단계를 시각적으로 안내하고
/// 유저가 전체 흐름을 이해한 뒤 온보딩을 시작하게 함.
class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // ── 타이틀 ───────────────────────────────────
                  const Text(
                    '딱 3분이면 돼요.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '내 기관지에 맞는 기준을 만들어드릴게요.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // ── 스텝 카드들 ──────────────────────────────
                  _StepCard(
                    step: 1,
                    emoji: '📋',
                    title: '건강 진단',
                    description: '10가지 질문으로\n나만의 민감도를 파악해요',
                    isActive: true,
                  ),
                  const _StepConnector(),
                  _StepCard(
                    step: 2,
                    emoji: '📊',
                    title: '민감도 분석',
                    description: 'T_final 기준선 계산 —\n나에게 꼭 맞는 알림 수치',
                    isActive: false,
                  ),
                  const _StepConnector(),
                  _StepCard(
                    step: 3,
                    emoji: '🔔',
                    title: '알림 세팅',
                    description: '시간·톤 설정 후\n실제 알림을 미리 받아보세요',
                    isActive: false,
                  ),

                  const Spacer(),

                  // ── 시작 버튼 ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed('/onboarding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '진단 시작하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
    );
  }
}

// ── 스텝 카드 ─────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int step;
  final String emoji;
  final String title;
  final String description;
  final bool isActive;

  const _StepCard({
    required this.step,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.divider,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // 이모지 + 스텝 번호
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryLight
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              if (isActive)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '지금 여기',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Step $step  ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textHint,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive
                        ? AppColors.textSecondary
                        : AppColors.textHint,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 스텝 연결선 ───────────────────────────────────────────

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 2, bottom: 2),
      child: Container(
        width: 2,
        height: 20,
        color: AppColors.divider,
      ),
    );
  }
}
