import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 주차 캡션: "5월 1주차 · 5/4 ~ 5/10"
class WeekCaption extends StatelessWidget {
  final String text;

  const WeekCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize:   11,
        fontWeight: FontWeight.w500,
        color:      DT.gray,
      ),
    );
  }
}
