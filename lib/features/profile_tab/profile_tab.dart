import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/profile_providers.dart';
import '../profile/profile_persona.dart';
import '../profile/widgets/axis_list.dart';
import '../profile/widgets/profile_background.dart';
import '../profile/widgets/profile_hero.dart';
import '../profile/widgets/threshold_range.dart';
import 'widgets/profile_footer.dart';

/// 프로필 탭 — /profile (시안 profile-main ProfileScreen 재작성)
///
/// 구조 (리포트 탭 패턴 동일):
///   LayoutBuilder + SingleChildScrollView + SizedBox(viewport.maxHeight) + Spacer
/// Padding: EdgeInsets.fromLTRB(24, 24, 24, 16)
/// 여백: Hero~ThresholdRange 44, ThresholdRange~Section 32, Section~Footer Spacer
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final persona = PersonaData.fromProfile(profile);
    final level   = ProfileBackground.levelFromSum(persona.sum);
    final accent  = ProfileBackground.accentColor(level);

    return Scaffold(
      body: ProfileBackground(
        level: level,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: viewport.maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero ───────────────────────────────────────
                        ProfileHero(
                          tFinal: persona.tFinal,
                          sub: persona.label,
                          cap: '내 기준은',
                        ),

                        const SizedBox(height: 44),

                        // ── ThresholdRange ─────────────────────────────
                        ThresholdRange(
                          myThreshold: persona.tFinal,
                          general: persona.general,
                          accentColor: accent,
                        ),

                        const SizedBox(height: 32),

                        // ── 섹션 라벨 ──────────────────────────────────
                        const Text(
                          '내 호흡기 정보',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DT.gray,
                            letterSpacing: 0.52,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── 5축 리스트 (variant D) ──────────────────────
                        AxisList(
                          axes: persona.axes,
                          accentColor: accent,
                        ),

                        // ── Spacer → Footer 하단 고정 ──────────────────
                        const Spacer(),

                        // ── Footer ─────────────────────────────────────
                        ProfileFooter(
                          onMoreDetails: () => context.push('/profile/details'),
                          onSettings: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
