import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTokens {

  // ── 반경 (Border Radius) ─────────────────────────────────
  static const double radiusSm  = 10.0;
  static const double radiusMd  = 14.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusFull = 999.0;

  // ── 화면 여백 (Screen Padding) ───────────────────────────
  static const double screenH   = 20.0;
  static const double screenTop = 24.0;

  // ── 카드 내부 여백 (Card Padding) ────────────────────────
  static const double cardSm = 14.0;
  static const double cardMd = 16.0;
  static const double cardLg = 20.0;

  // ── 컴포넌트 간격 (Gap) ──────────────────────────────────
  static const double gapXs  = 4.0;
  static const double gapSm  = 8.0;
  static const double gapMd  = 12.0;
  static const double gapLg  = 16.0;
  static const double gapXl  = 20.0;
  static const double gapXxl = 24.0;

  // ── 버튼 높이 ────────────────────────────────────────────
  static const double btnHeightPrimary = 54.0;
  static const double btnHeightSecondary = 48.0;

  // ── 그림자 (Shadow) ──────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowColored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ── 타이포그래피 (Typography) ────────────────────────────

  static const TextStyle headingXl = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.3,
  );
  static const TextStyle headingLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
  static const TextStyle headingMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLg = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const TextStyle captionHint = TextStyle(
    fontSize: 11,
    color: AppColors.textHint,
  );

  static const TextStyle btnPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const TextStyle btnSecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const TextStyle btnText = TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
  );
}
