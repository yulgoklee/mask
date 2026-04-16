import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Phase 1-2: 로드맵 선언 화면
///
/// 사용자에게 [진단 → 분석 → 세팅] 3단계 여정을 미리 보여주어
/// 온보딩 중도 이탈을 방지합니다.
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
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // 인트로 문구
                  const Text(
                    '안녕하세요 😊',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '당신만을 위한\n공기 안전 기준을\n만들어 드릴게요.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '단 3단계로 나만의 가디언을 설정합니다.\n약 2분이면 충분해요.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 3단계 스테퍼 카드
                  _StepperCard(),

                  const Spacer(flex: 3),

                  // 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/onboarding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.splashBackground,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '진단 시작하기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 3단계 스테퍼 카드 ────────────────────────────────────

class _StepperCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
      ),
      child: const Column(
        children: [
          _StepItem(
            number: '1',
            title: '진단',
            subtitle: '나의 호흡기 예민도 파악',
            isActive: true,
            isLast: false,
          ),
          _StepItem(
            number: '2',
            title: '분석',
            subtitle: '나만의 안전 기준선 수립',
            isActive: false,
            isLast: false,
          ),
          _StepItem(
            number: '3',
            title: '세팅',
            subtitle: '알림 스타일 커스텀',
            isActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isLast;

  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 번호 + 연결선
        Column(
          children: [
            // 원형 번호 뱃지
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.splashBackground
                        : Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // 연결선
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: Colors.white.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // 텍스트 (연결선 영역만큼 패딩)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningCoral,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '지금 여기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
