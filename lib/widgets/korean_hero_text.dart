import 'package:flutter/material.dart';

/// 한국어 단어 단위 줄바꿈 Hero 텍스트.
///
/// Flutter `Text` 위젯의 default break이 한국어에서 **글자 단위**라
/// "내 기준을" 같은 단어가 "내 기" / "준을" 식으로 잘린다.
/// 본 위젯은 `LayoutBuilder` + `TextPainter`로 부모 폭에 맞춰
/// **공백(단어 경계)에서만** `\n`을 삽입한다.
class KoreanHeroText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const KoreanHeroText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wrapped = _wrapAtWordBoundary(text, style, constraints.maxWidth);
        return Text(wrapped, style: style);
      },
    );
  }

  static String _wrapAtWordBoundary(
      String text, TextStyle style, double maxWidth) {
    // 입력 `\n`은 의미적 강제 break — 각 라인을 별도로 wrap한 뒤 다시 join.
    return text
        .split('\n')
        .map((line) => _wrapSingleLine(line, style, maxWidth))
        .join('\n');
  }

  static String _wrapSingleLine(
      String text, TextStyle style, double maxWidth) {
    if (text.isEmpty) return text;
    final words = text.split(' ');
    if (words.length <= 1) return text;

    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      final candidate = currentLine.isEmpty ? word : '$currentLine $word';
      final tp = TextPainter(
        text: TextSpan(text: candidate, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      if (tp.width <= maxWidth) {
        currentLine = candidate;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          // 단어 자체가 폭 초과 — 어쩔 수 없이 그대로 한 줄에
          lines.add(word);
          currentLine = '';
        }
      }
    }

    if (currentLine.isNotEmpty) lines.add(currentLine);
    return lines.join('\n');
  }
}
