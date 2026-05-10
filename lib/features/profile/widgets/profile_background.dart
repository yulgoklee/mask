import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/gradient_background.dart';

/// 프로필·결과지 배경 그라디언트 (시안 profile-main 정확)
///
/// 6-stop (실제 3-stop), stops [0.0, 0.3, 1.0].
/// 트리거 = 건강 민감도 합산 (정적 — 재진단 시에만 바뀜).
/// CareBackground와 같은 패턴 — AnimatedContainer(400ms).
enum ProfileSensitivityLevel { safe, caution }

class ProfileBackground extends StatelessWidget {
  final ProfileSensitivityLevel level;
  final Widget child;

  const ProfileBackground({
    super.key,
    required this.level,
    required this.child,
  });

  /// 건강 가중치 합산 → ProfileSensitivityLevel
  ///
  /// 의뢰서 §4-3: 합 ≥ 0.20 → caution(노랑), 미만 → safe(민트).
  /// 계획서 §3: threshold = 0.20.
  static ProfileSensitivityLevel levelFromSum(double sum) {
    if (sum >= 0.20) return ProfileSensitivityLevel.caution;
    return ProfileSensitivityLevel.safe;
  }

  /// 레벨별 강조 색 (마커·버튼·delta 등에서 참조)
  static Color accentColor(ProfileSensitivityLevel level) {
    switch (level) {
      case ProfileSensitivityLevel.safe:
        return DT.safe;
      case ProfileSensitivityLevel.caution:
        return DT.caution;
    }
  }

  List<Color> get _colors {
    switch (level) {
      case ProfileSensitivityLevel.safe:
        return const [
          Color(0xFFE0F0E8),
          Color(0xFFE0F0E8),
          Color(0xFFF9FAFB),
        ];
      case ProfileSensitivityLevel.caution:
        return const [
          Color(0xFFFDEDC4),
          Color(0xFFFDEDC4),
          Color(0xFFF9FAFB),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: _colors,
      child: child,
    );
  }
}
