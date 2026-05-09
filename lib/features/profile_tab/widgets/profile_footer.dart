import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// 프로필 표면 하단 Footer (시안 profile-screens PFooter)
///
/// Row(spaceBetween):
///   좌: "호흡기 정보를 수정하면\n기준이 다시 계산돼요" (11pt w500 DT.gray2)
///   우: Row(gap: 14)
///     - "더 자세히 보기 →" GestureDetector (14pt w600 DT.text)
///     - 설정 아이콘 GestureDetector (32×32 circle, DT.gray)
class ProfileFooter extends StatelessWidget {
  final VoidCallback onMoreDetails;
  final VoidCallback onSettings;

  const ProfileFooter({
    super.key,
    required this.onMoreDetails,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── 좌: 안내 문구 ────────────────────────────────────
        const Flexible(
          child: Text(
            '호흡기 정보를 수정하면\n기준이 다시 계산돼요',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: DT.gray2,
              letterSpacing: -0.055,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── 우: 더 자세히 + 설정 ─────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 더 자세히 보기 →
            GestureDetector(
              onTap: onMoreDetails,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '더 자세히 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DT.text,
                        letterSpacing: -0.14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: DT.text,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 설정 아이콘 (32×32 원형 터치 영역)
            GestureDetector(
              onTap: onSettings,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: DT.gray,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
