import 'package:flutter/material.dart';

class AppColors {
  // 브랜드 색상 — Sky Blue + Coral 테마
  static const Color primary      = Color(0xFF42A5F5);  // Sky Blue (버튼·포인트용)
  static const Color primaryLight = Color(0xFFA2D2FF);  // Sky Blue Light (틴트 배경)
  static const Color secondary    = Color(0xFFFF865E);  // Coral (강조·배지)
  static const Color coral        = Color(0xFFFF865E);  // Coral (별칭)

  // 미세먼지 등급별 색상
  static const Color dustGood = Color(0xFF10B981);     // 초록
  static const Color dustNormal = Color(0xFFF59E0B);   // 노랑
  static const Color dustBad = Color(0xFFEF4444);      // 빨강
  static const Color dustVeryBad = Color(0xFF7C3AED);  // 보라

  // 배경
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // 텍스트
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFCBD5E1);

  // 기타
  static const Color divider = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // 알림 타입별 accent 색상 (NotificationTimeScreen / CompleteScreen 공용)
  static const Color notifMorning = Color(0xFFF59E0B);  // 외출 전   — amber
  static const Color notifEvening = Color(0xFF8B5CF6);   // 전날 예보 — purple
  static const Color notifReturn  = Color(0xFF10B981);   // 귀가 후   — green

  static Color dustGradeColor(String grade) {
    switch (grade) {
      case '좋음':    return dustGood;
      case '보통':    return dustNormal;
      case '나쁨':    return dustBad;
      case '매우나쁨': return dustVeryBad;
      default:       return textSecondary;
    }
  }
}
