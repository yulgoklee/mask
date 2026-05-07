import 'package:flutter/material.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../data/models/user_profile.dart';

/// 프로필 탭 전용 — 위험 상태 사용자를 위한 마스크 강조 섹션
///
/// general(균형 유지형) 판정 시 표시 ✕
/// 결과지의 PersonaConclusionCard 와 별개 위젯
class PersonaAlertCard extends StatelessWidget {
  final UserProfile profile;

  const PersonaAlertCard({super.key, required this.profile});

  /// null 반환 시 위젯 미표시 (균형 유지형)
  /// 5종: compound / respiratory / cardiovascular / sensitive / general(미표시)
  static _AlertSpec? _resolve(UserProfile p) {
    final hasResp   = p.hasRespiratoryCondition;
    final hasCardio = p.hasCardiovascularCondition;
    final isSmoking = p.smokingStatus == SmokingStatus.current;

    // compound: 호흡기 + 심혈관 동시 보유, 또는 호흡기/심혈관 + 흡연 → 가장 강조
    if ((hasResp && hasCardio) || (hasResp && isSmoking) || (hasCardio && isSmoking)) {
      return _AlertSpec(
        bg: DT.dangerLt,
        iconColor: DT.danger,
        body: '호흡기와 활동량 모두 위험 요소가 있어요. 외출 시 마스크는 단순 도움이 아닌 보호 도구입니다.',
      );
    }

    // respiratory 단독
    if (hasResp) {
      return _AlertSpec(
        bg: DT.dangerLt,
        iconColor: DT.danger,
        body: '호흡기가 민감해서 적은 농도에도 영향 받아요. 마스크가 보호선 역할을 해줍니다.',
      );
    }

    // cardiovascular 단독 (compound 아닌 경우) → 강조
    if (hasCardio) {
      return _AlertSpec(
        bg: DT.dangerLt,
        iconColor: DT.danger,
        body: '호흡기와 활동량 모두 위험 요소가 있어요. 외출 시 마스크는 단순 도움이 아닌 보호 도구입니다.',
      );
    }

    // sensitive: 취약 연령 or 흡연
    if (p.isVulnerableAge || isSmoking) {
      return _AlertSpec(
        bg: DT.cautionLt,
        iconColor: DT.caution,
        body: '공기 변화에 빨리 반응하는 체질이세요. 수치가 낮을 때도 마스크가 도움됩니다.',
      );
    }

    // general — 미표시
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final spec = _resolve(profile);
    if (spec == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTokens.cardLg),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 22,
            color: spec.iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '마스크는 당신의 보호선',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: spec.iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spec.body,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: DT.text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSpec {
  final Color bg;
  final Color iconColor;
  final String body;

  const _AlertSpec({
    required this.bg,
    required this.iconColor,
    required this.body,
  });
}
