import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/utils/persona_generator.dart';
import '../../../providers/profile_providers.dart';

class PersonaCard extends ConsumerStatefulWidget {
  const PersonaCard({super.key});

  @override
  ConsumerState<PersonaCard> createState() => _PersonaCardState();
}

class _PersonaCardState extends ConsumerState<PersonaCard> {
  bool _expanded = false;

  Color _bgColor(PersonaType type) => switch (type) {
        PersonaType.compound           => DT.primaryLt,
        PersonaType.medicalCare        => DT.purpleLt,
        PersonaType.activeAndSensitive => DT.tealLt,
        PersonaType.activeOutdoor      => DT.safeLt,
        PersonaType.sensitiveFeel      => DT.pinkLt,
        PersonaType.general            => DT.grayLt,
      };

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final persona = PersonaGenerator.generate(profile);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor(persona.type),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 16,
              color: Color(0x0A000000),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                  ? _ExpandedSection(persona: persona)
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

// ── 확장 섹션 ─────────────────────────────────────────────

class _ExpandedSection extends StatelessWidget {
  final Persona persona;
  const _ExpandedSection({required this.persona});

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

// ── 토글 힌트 버튼 ────────────────────────────────────────

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

// ── 기준치 비교 행 ────────────────────────────────────────

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
