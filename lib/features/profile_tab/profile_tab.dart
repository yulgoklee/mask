import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import 'widgets/persona_card.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    '프로필',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DT.text),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings, color: DT.text),
                    onPressed: () => context.push('/settings'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const PersonaCard().animate().fadeIn(duration: 350.ms, curve: Curves.easeOutCubic).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
              const MyBodyInfoButton().animate(delay: 50.ms).fadeIn(duration: 300.ms, curve: Curves.easeOutCubic).slideY(begin: 0.06, end: 0),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MyBodyInfoButton ──────────────────────────────────────

class MyBodyInfoButton extends ConsumerWidget {
  const MyBodyInfoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _NavButton(
      icon: Icons.person_outline,
      title: '내 몸 정보',
      subtitle: '기본 정보, 건강 상태 등',
      onTap: () => context.push('/my-body-info'),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: DT.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DT.border),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0F000000)),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 24, color: DT.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: DT.text)),
                    Text(widget.subtitle,
                        style: const TextStyle(fontSize: 12, color: DT.gray),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: DT.gray),
            ],
          ),
        ),
      ),
    );
  }
}
