import 'package:animated_digit/animated_digit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../core/constants/design_tokens.dart';
import '../../data/models/notification_setting.dart';
import '../../providers/profile_providers.dart';
import 'models/quick_state.dart';
import 'providers/quick_state_provider.dart';

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
              const Text(
                '프로필',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DT.text),
              ),
              const SizedBox(height: 20),
              const PersonaCard().animate().fadeIn(duration: 350.ms, curve: Curves.easeOutCubic).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
              const QuickStateToggleCard().animate(delay: 50.ms).fadeIn(duration: 300.ms, curve: Curves.easeOutCubic).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
              const ProfileEditButton().animate(delay: 100.ms).fadeIn(duration: 300.ms, curve: Curves.easeOutCubic).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 8),
              const NotificationSettingButton().animate(delay: 150.ms).fadeIn(duration: 300.ms, curve: Curves.easeOutCubic).slideY(begin: 0.06, end: 0),
              const Spacer(),
              const _AppVersionFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 1. PersonaCard ────────────────────────────────────────

class PersonaCard extends ConsumerWidget {
  const PersonaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Stack(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DT.primaryLt, DT.purpleLt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(0.785),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        GlassmorphicContainer(
          width: double.infinity,
          height: 120,
          borderRadius: 20,
          blur: 12,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderGradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.1)],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                _PersonaIcon(persona: profile.personaLabel),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.personaLabel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DT.text),
                      ),
                      Text(
                        '${profile.displayName}',
                        style: const TextStyle(fontSize: 13, color: DT.gray),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedDigitWidget(
                      value: profile.tFinal.toInt(),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: DT.primary,
                      ),
                    ),
                    const Text('내 기준치', style: TextStyle(fontSize: 10, color: DT.gray)),
                    const Text('µg/m³', style: TextStyle(fontSize: 10, color: DT.gray)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonaIcon extends StatelessWidget {
  final String persona;
  const _PersonaIcon({required this.persona});

  String get _emoji => switch (persona) {
    '복합 고위험군' => '🚨',
    '호흡기 취약형' => '🫁',
    '임산부 보호형' => '🤰',
    '민감형 관리자' => '🎯',
    '활동형 아웃도어' => '🏃',
    _              => '🛡️',
  };

  Color get _bg => switch (persona) {
    '복합 고위험군' => DT.dangerLt,
    '호흡기 취약형' => DT.cautionLt,
    '임산부 보호형' => DT.purpleLt,
    '민감형 관리자' => DT.primaryLt,
    '활동형 아웃도어' => DT.tealLt,
    _              => DT.grayLt,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(_emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}

// ── 2. QuickStateToggleCard ───────────────────────────────

class QuickStateToggleCard extends ConsumerWidget {
  const QuickStateToggleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qs = ref.watch(quickStateProvider);
    final notifier = ref.read(quickStateProvider.notifier);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0F000000)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _ToggleItem(
            emoji: '🤧', label: '감기 중', type: QuickStateType.cold,
            isOn: qs.isCold, onColor: DT.cautionLt,
            onTap: () => notifier.toggle(QuickStateType.cold),
          )),
          const SizedBox(width: 8),
          Expanded(child: _ToggleItem(
            emoji: '💉', label: '피부 시술', type: QuickStateType.skinTreatment,
            isOn: qs.hasSkinTreatment, onColor: DT.purpleLt,
            onTap: () => notifier.toggle(QuickStateType.skinTreatment),
          )),
          const SizedBox(width: 8),
          Expanded(child: _ToggleItem(
            emoji: '🏃', label: '야외 활동', type: QuickStateType.outdoorActive,
            isOn: qs.isOutdoorActive, onColor: DT.tealLt,
            onTap: () => notifier.toggle(QuickStateType.outdoorActive),
          )),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String emoji;
  final String label;
  final QuickStateType type;
  final bool isOn;
  final Color onColor;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.emoji,
    required this.label,
    required this.type,
    required this.isOn,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: isOn ? onColor : DT.grayLt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20))
                .animate(target: isOn ? 1.0 : 0.0)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), curve: Curves.elasticOut, duration: 200.ms),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isOn ? DT.text : DT.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. ProfileEditButton ──────────────────────────────────

class ProfileEditButton extends ConsumerWidget {
  const ProfileEditButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final summary = _buildSummary(profile.respiratoryLabel, profile.sensitivityLevel, profile.outdoorMinutes);

    return _NavButton(
      icon: Icons.health_and_safety_outlined,
      title: '건강 프로필 수정',
      subtitle: summary,
      onTap: () => context.push('/profile/edit'),
    );
  }

  String _buildSummary(String resp, int sensitivity, int outdoor) {
    final parts = [
      resp,
      switch (sensitivity) { 2 => '매우 예민', 1 => '보통', _ => '무던함' },
      switch (outdoor) { 2 => '야외 3h+', 1 => '야외 1~3h', _ => '야외 1h미만' },
    ];
    return parts.join(' · ');
  }
}

// ── 4. NotificationSettingButton ──────────────────────────

class NotificationSettingButton extends ConsumerWidget {
  const NotificationSettingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);
    final summary = _buildSummary(setting);
    final isEnabled = setting.morningAlertEnabled || setting.eveningReturnEnabled || setting.eveningForecastEnabled;

    return _NavButton(
      icon: Icons.notifications_outlined,
      title: '알림 설정',
      subtitle: summary,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isEnabled ? DT.safeLt : DT.dangerLt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          isEnabled ? '켜짐' : '꺼짐',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isEnabled ? DT.safe : DT.danger,
          ),
        ),
      ),
      onTap: () => context.push('/notifications'),
    );
  }

  String _buildSummary(NotificationSetting s) {
    if (!s.morningAlertEnabled && !s.eveningReturnEnabled && !s.eveningForecastEnabled) {
      return '알림 꺼짐';
    }
    final parts = <String>[];
    if (s.morningAlertEnabled) {
      parts.add('외출 전 ${s.morningAlertHour.toString().padLeft(2, '0')}:${s.morningAlertMinute.toString().padLeft(2, '0')}');
    }
    if (s.eveningReturnEnabled) {
      parts.add('귀가 후 ${s.eveningReturnHour.toString().padLeft(2, '0')}:${s.eveningReturnMinute.toString().padLeft(2, '0')}');
    }
    return parts.isEmpty ? '알림 설정 없음' : parts.join(' · ');
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
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
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, size: 20, color: DT.gray),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('마스크 알림 v1.0.4', style: TextStyle(fontSize: 12, color: DT.gray)),
    );
  }
}
