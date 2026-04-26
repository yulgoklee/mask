import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/utils/persona_generator.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/profile_providers.dart';

// ── 공유 스타일 헬퍼 ──────────────────────────────────────────

Color personaCardBgColor(PersonaType type) => switch (type) {
      PersonaType.compound           => DT.primaryLt,
      PersonaType.medicalCare        => DT.purpleLt,
      PersonaType.activeAndSensitive => DT.tealLt,
      PersonaType.activeOutdoor      => DT.safeLt,
      PersonaType.sensitiveFeel      => DT.pinkLt,
      PersonaType.general            => DT.grayLt,
    };

BoxDecoration personaCardDecoration(PersonaType type) => BoxDecoration(
      color: personaCardBgColor(type),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          offset: Offset(0, 4),
          blurRadius: 16,
          color: Color(0x0A000000),
        ),
      ],
    );

const EdgeInsets personaCardPadding = EdgeInsets.fromLTRB(20, 20, 20, 12);

// ── PersonaCardExpanded ───────────────────────────────────────

/// 페르소나 카드의 확장 콘텐츠 위젯 (구분선 + reasons 또는 균형 유지형 안내 문구).
/// PersonaCard 내부 AnimatedSize 와 DiagnosisResultScreen 카드에서 공용.
/// DiagnosisResultScreen 에서는 기준치 행을 외부에 배치하고 이 위젯을 이어 붙임.
class PersonaCardExpanded extends StatelessWidget {
  final Persona persona;
  final UserProfile profile;

  const PersonaCardExpanded({
    super.key,
    required this.persona,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final isGeneral =
        persona.type == PersonaType.general || persona.reasons.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1, color: DT.border),
        ),
        if (isGeneral)
          const Text(
            '지금 상태라면 공식 기준(35µg/m³)을\n그대로 적용해도 충분해요.',
            style: TextStyle(fontSize: 14, color: DT.gray, height: 1.6),
          )
        else ...[
          const Text(
            '왜 더 엄격한가요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: DT.text,
            ),
          ),
          const SizedBox(height: 12),
          ...persona.reasons.asMap().entries.map((entry) {
            final idx = entry.key;
            final reason = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: DT.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DT.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reason.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DT.gray,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ── PersonaCard ───────────────────────────────────────────────

class PersonaCard extends ConsumerStatefulWidget {
  const PersonaCard({super.key});

  @override
  ConsumerState<PersonaCard> createState() => _PersonaCardState();
}

class _PersonaCardState extends ConsumerState<PersonaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final persona = PersonaGenerator.generate(profile);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: personaCardDecoration(persona.type),
        padding: personaCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 이모지 + 이름 + 닉네임 ─────────────────────────
            Text(persona.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              persona.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DT.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profile.displayName,
              style: const TextStyle(fontSize: 13, color: DT.gray),
            ),
            const SizedBox(height: 16),

            // ── 기준치 비교 ────────────────────────────────────
            _ThresholdRow(
              label: '내 기준치',
              value: '${profile.tFinal.toInt()} µg/m³',
              highlight: true,
            ),
            const SizedBox(height: 4),
            const _ThresholdRow(
              label: '일반인 기준',
              value: '35 µg/m³',
              highlight: false,
            ),

            // ── 확장 영역 (AnimatedSize) ───────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? PersonaCardExpanded(persona: persona, profile: profile)
                  : const SizedBox.shrink(),
            ),

            // ── 토글 힌트 ──────────────────────────────────────
            _ToggleHint(expanded: _expanded),
          ],
        ),
      ),
    );
  }
}

// ── 토글 힌트 버튼 ────────────────────────────────────────────

class _ToggleHint extends StatelessWidget {
  final bool expanded;
  const _ToggleHint({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            expanded ? '접기' : '자세히 보기',
            style: const TextStyle(fontSize: 12, color: DT.gray),
          ),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more, size: 18, color: DT.gray),
          ),
        ],
      ),
    );
  }
}

// ── 기준치 비교 행 ────────────────────────────────────────────

class _ThresholdRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ThresholdRow({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: DT.gray)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: highlight ? DT.primary : DT.gray,
          ),
        ),
      ],
    );
  }
}
