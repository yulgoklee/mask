import 'package:flutter/material.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  Q1 — 닉네임
// ══════════════════════════════════════════════════════════════

class DiagQ1Nickname extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final int questionNumber;

  const DiagQ1Nickname({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.questionNumber = 1,
  });

  @override
  State<DiagQ1Nickname> createState() => _DiagQ1NicknameState();
}

class _DiagQ1NicknameState extends State<DiagQ1Nickname> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q${widget.questionNumber} · 이름'),
          const SizedBox(height: 14),
          qTitle(context, '어떻게 불러드릴까요?'),
          const SizedBox(height: 8),
          qSubtitle(context, '알림 메시지에 이름이 표시돼요. "지수님, 지금 마스크를 쓰세요!"처럼요.'),
          const SizedBox(height: 36),
          fieldLabel('이름'),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            decoration: inputDecoration('예: 지수'),
            onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
          ),
          const SizedBox(height: 32),
          insightBox('이름을 입력하면 "지수님, 오늘 미세먼지가 높아요" 처럼 알림이 개인화돼요.'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
