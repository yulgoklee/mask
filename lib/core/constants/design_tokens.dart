import 'package:flutter/material.dart';

/// 대시보드 재설계 디자인 토큰
/// dashboard_redesign_spec v1.0 기준 색상 팔레트
class DT {
  // ── Primary ────────────────────────────────────────────────
  static const Color primary    = Color(0xFF2563EB);
  static const Color primaryLt  = Color(0xFFDBEAFE);

  // ── Safe ──────────────────────────────────────────────────
  static const Color safe       = Color(0xFF16A34A);
  static const Color safeLt     = Color(0xFFDCFCE7);
  static const Color safeBg     = Color(0xFFF0FDF4);

  // ── Caution ───────────────────────────────────────────────
  static const Color caution    = Color(0xFFD97706);
  static const Color cautionLt  = Color(0xFFFEF3C7);
  static const Color cautionBg  = Color(0xFFFFFBEB);

  // ── Danger ────────────────────────────────────────────────
  static const Color danger     = Color(0xFFDC2626);
  static const Color dangerLt   = Color(0xFFFEE2E2);
  static const Color dangerBg   = Color(0xFFFFF1F2);

  // ── Teal ──────────────────────────────────────────────────
  static const Color teal       = Color(0xFF0D9488);
  static const Color tealLt     = Color(0xFFCCFBF1);

  // ── Purple ────────────────────────────────────────────────
  static const Color purple     = Color(0xFF7C3AED);
  static const Color purpleLt   = Color(0xFFEDE9FE);

  // ── Pink ──────────────────────────────────────────────────
  static const Color pinkLt     = Color(0xFFFCE7F3); // 페르소나 - 예민한 감지형

  // ── Neutral ───────────────────────────────────────────────
  static const Color text       = Color(0xFF111827);
  static const Color gray       = Color(0xFF6B7280);
  static const Color grayLt     = Color(0xFFF3F4F6);
  static const Color border     = Color(0xFFE5E7EB);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9FAFB);

  // ── Grade color helpers ───────────────────────────────────
  static Color gradeText(String grade) => switch (grade) {
    '좋음'    => safe,
    '보통'    => text,
    '나쁨'    => caution,
    '매우나쁨' => danger,
    _         => gray,
  };

  static Color gradeBadgeBg(String grade) => switch (grade) {
    '좋음'    => safeLt,
    '보통'    => grayLt,
    '나쁨'    => cautionLt,
    '매우나쁨' => dangerLt,
    _         => grayLt,
  };

  static Color gradeCardBg(String grade) => switch (grade) {
    '좋음'    => safeBg,
    '보통'    => white,
    '나쁨'    => cautionBg,
    '매우나쁨' => dangerBg,
    _         => white,
  };
}
