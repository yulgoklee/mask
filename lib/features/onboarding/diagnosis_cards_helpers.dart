import 'package:flutter/material.dart';
import '../../core/constants/design_tokens.dart';

/// Q배지 (예: "Q4 · 호흡기")
Widget qBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: DT.primaryLt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: DT.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );

/// 질문 타이틀
Widget qTitle(BuildContext context, String title) =>
    Text(
      title,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: DT.text,
        height: 1.3,
      ),
    );

/// 서브타이틀
Widget qSubtitle(BuildContext context, String subtitle) =>
    Text(
      subtitle,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: DT.gray,
        height: 1.5,
      ),
    );

/// 인사이트 박스
Widget insightBox(String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DT.primaryLt.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DT.primaryLt),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: DT.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DT.gray,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );

/// 텍스트 필드용 레이블
Widget fieldLabel(String text) => Text(
      text,
      style: const TextStyle(
        color: DT.text,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

/// 텍스트 필드 데코레이션
InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: DT.gray2),
      filled: true,
      fillColor: DT.grayLt,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DT.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
