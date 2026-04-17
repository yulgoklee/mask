import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _TutorialPage(
      emoji: '😷',
      color: Color(0xFF3B82F6),
      title: '매일 아침,\n마스크가 필요한지 알려드려요',
      description: '미세먼지 수치를 확인하는 앱이 아니에요.\n"오늘 마스크 챙겨야겠다!" 라고\n행동하게 만드는 앱이에요.',
    ),
    _TutorialPage(
      emoji: '🏥',
      color: Color(0xFF10B981),
      title: '내 건강 상태에 맞게,\n오늘 할 행동을 알려드려요',
      description: '나이, 기저질환, 활동량에 따라\n나에게 딱 맞는 기준으로\n마스크 착용 여부를 판단해드려요.',
    ),
  ];

  Future<void> _done() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.completeTutorial();
    if (!mounted) return;
    final onboardingDone = await repo.isOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      onboardingDone ? '/home' : '/roadmap', // 신규 유저 → 로드맵 → 온보딩
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: TextButton(
                  onPressed: _done,
                  child: const Text('건너뛰기',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),

            // 페이지
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _TutorialPageView(page: _pages[i]),
              ),
            ),

            // 인디케이터 + 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // 점 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _pages[i].color
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 다음 / 시작하기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _done();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? '다음' : '시작하기',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage {
  final String emoji;
  final Color color;
  final String title;
  final String description;
  const _TutorialPage({
    required this.emoji,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _TutorialPageView extends StatelessWidget {
  final _TutorialPage page;
  const _TutorialPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 원
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(page.emoji,
                  style: const TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
