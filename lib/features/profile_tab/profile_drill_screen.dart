import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/profile_providers.dart';
import '../profile/profile_persona.dart';
import '../profile/widgets/axis_list.dart';
import '../profile/widgets/profile_background.dart';
import 'widgets/waterfall.dart';

/// 프로필 Drill-down — /profile/details (시안 profile-main ProfileDrillScreen)
///
/// slideRight 진입 (app_router.dart _slidePage)
/// 케어 드릴 구조 동일 — 배경만 ProfileBackground로 교체
///
/// 4 섹션:
///   1. 임계치 산정 흐름 (Waterfall)
///   2. 5축 가중치 (AxisList variant F)
///   3. "{persona.label}"이란 (페르소나 설명문)
///   4. 자료원 (_Sources)
class ProfileDrillScreen extends ConsumerWidget {
  const ProfileDrillScreen({super.key});

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
          child: Column(
            children: [
              // ── Sticky 헤더: back + 타이틀 ─────────────────
              _DrillHeader(onBack: () => context.pop()),

              // ── 본문 (스크롤) ────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1 — 임계치 산정 흐름
                      const _SectionHeader(title: '임계치 산정 흐름'),
                      Waterfall(
                        general: persona.general,
                        tFinal: persona.tFinal,
                        axes: persona.axes,
                        accent: accent,
                      ),
                      const SizedBox(height: 36),

                      // Section 2 — 5축 가중치
                      const _SectionHeader(title: '5축 가중치'),
                      AxisList(
                        axes: persona.axes,
                        accentColor: accent,
                        variant: AxisListVariant.f,
                      ),
                      const SizedBox(height: 36),

                      // Section 3 — 페르소나 설명
                      _SectionHeader(title: '"${persona.label}"이란'),
                      _PersonaDescription(persona: persona),
                      const SizedBox(height: 36),

                      // Section 4 — 자료원
                      const _SectionHeader(title: '자료원'),
                      const _Sources(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sticky 헤더 52h ──────────────────────────────────────────────

class _DrillHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DrillHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(color: DT.text.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // 뒤로 버튼
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 52,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: DT.text,
                ),
              ),
            ),
          ),
          // 타이틀
          const Expanded(
            child: Text(
              '내 기준 자세히',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DT.text,
                letterSpacing: -0.32,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DT.gray,
          letterSpacing: 0.52,
        ),
      ),
    );
  }
}

// ── 페르소나 설명문 ────────────────────────────────────────────────

class _PersonaDescription extends StatelessWidget {
  final PersonaData persona;

  const _PersonaDescription({required this.persona});

  @override
  Widget build(BuildContext context) {
    final String body;
    if (persona.sum >= 0.30) {
      body = '천식·알레르기성 비염·만성 기관지염 등 호흡기 민감 이력이 있는 분들의 그룹입니다. '
          '미세먼지 자극에 더 일찍 반응할 수 있어, 일반 기준보다 낮은 임계치를 사용해요.';
    } else if (persona.sum > 0) {
      body = '일부 건강 요인이 있는 분들의 그룹입니다. '
          'WHO·환경부 권고 기준보다 약간 낮은 임계치를 적용해 더 일찍 알림을 드려요.';
    } else {
      body = '특별한 호흡기·심혈관 이력이 없는 분들의 그룹입니다. '
          'WHO·환경부 권고 기준에 가까운 임계치를 사용해요.';
    }

    return Text(
      body,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: DT.text,
        height: 1.6,
        letterSpacing: -0.07,
      ),
    );
  }
}

// ── 자료원 (D-5: Drill 내부 private) ─────────────────────────────

class _Sources extends StatelessWidget {
  const _Sources();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SourceRow(
          title: 'WHO Air Quality Guidelines 2021',
          onTap: null,
        ),
        _SourceRow(
          title: '환경부 미세먼지 기준',
          onTap: null,
        ),
        _SourceRow(
          title: 'ARIA · ATS · 대한천식알레르기학회',
          onTap: null,
        ),
        SizedBox(height: 12),
        Text(
          '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단을 대체하지 않습니다.',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: DT.gray2,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SourceRow({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DT.text,
          letterSpacing: -0.14,
        ),
      ),
    );
  }
}
