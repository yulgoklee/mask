import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../features/profile/widgets/profile_background.dart';
import '../../../features/profile/profile_persona.dart';
import '../../../features/profile_tab/widgets/waterfall.dart';
import '../../../providers/profile_providers.dart';
import '../widgets/settings_drill_header.dart';
import '../widgets/s_label.dart';

/// 투명성 — 계산 방식 (T_final이란?)
///
/// ConsumerWidget — profileProvider에서 실제 사용자 데이터 읽어 Waterfall 표시.
class CalculationScreen extends ConsumerWidget {
  const CalculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final persona = PersonaData.fromProfile(profile);
    final level = ProfileBackground.levelFromSum(persona.sum);
    final accent = ProfileBackground.accentColor(level);
    final pm10Final = (persona.tFinal * 80 / 35).roundToDouble();

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsDrillHeader(
              title: '계산 방식',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 제목 + 설명 ─────────────────────────
                    const Text(
                      'T_final이란?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: DT.text,
                        letterSpacing: -0.44,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '내 기준치를 구하는 공식이에요.\n'
                      '일반 기준에서 건강 상태에 따라 조금씩 낮아져요.\n'
                      '낮을수록 더 일찍 알림을 받아요.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: DT.gray,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section 1: Waterfall ─────────────────
                    const SLabel('임계치 산정 흐름'),
                    const SizedBox(height: 8),
                    Waterfall(
                      general: persona.general,
                      tFinal: persona.tFinal,
                      axes: persona.axes,
                      accent: accent,
                    ),
                    const SizedBox(height: 28),

                    // ── Section 2: PM10 환산 ─────────────────
                    const SLabel('PM10 환산'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'PM10 기준치',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DT.text,
                              letterSpacing: -0.14,
                            ),
                          ),
                        ),
                        Text(
                          '${pm10Final.toStringAsFixed(0)} ㎍/㎥',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: -0.32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PM10은 같은 비율로 환산해요. (T_final × 80 ÷ 35)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: DT.gray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Section 3: 최저 기준 ─────────────────
                    const SLabel('최저 기준'),
                    const SizedBox(height: 8),
                    const Text(
                      'WHO 2021 기준 15㎍/㎥ 이하로 내려가지 않아요.\n'
                      '건강 민감도가 매우 높더라도 알림 기준은 15㎍/㎥가 최저예요.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: DT.gray,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
