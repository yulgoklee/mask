import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 설정 서브 화면 Sticky 헤더
///
/// ProfileDrill _DrillHeader와 동일 구조 (52h, back, 17pt w700 타이틀).
/// 배경 = DT.background 단색 (ProfileDrillHeader의 반투명 white와 다름).
class SettingsDrillHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const SettingsDrillHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: DT.background,
        border: Border(
          bottom: BorderSide(color: DT.text.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 52,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: DT.text,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: DT.text,
                letterSpacing: -0.34,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
