import 'package:flutter/material.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../data/models/user_profile.dart';

/// 결과지 전용 — 사용자 상태별 마스크 필요성 결론 카드
///
/// 위치: ThresholdCompareCard 와 SensitivityBreakdown 사이 (diagnosis_result_screen)
/// 프로필 탭에서는 사용 ✕ — 프로필 탭은 PersonaAlertCard 사용
class PersonaConclusionCard extends StatelessWidget {
  final UserProfile profile;

  const PersonaConclusionCard({super.key, required this.profile});

  /// 페르소나 분류 → (제목, 본문)
  /// 5종: compound / respiratory / cardiovascular / sensitive / general
  static (String, String) _resolve(UserProfile p) {
    final hasResp  = p.hasRespiratoryCondition;
    final hasCardio = p.hasCardiovascularCondition;
    final isSmoking = p.smokingStatus == SmokingStatus.current;

    // compound: 호흡기 + 심혈관 동시 보유, 또는 호흡기/심혈관 + 흡연
    if ((hasResp && hasCardio) || (hasResp && isSmoking) || (hasCardio && isSmoking)) {
      return (
        '당신에게 마스크는',
        '호흡기 상태와 활동량 모두 신경 쓰시는 분이에요. 마스크가 노출 시간을 줄이는 보호선이에요.',
      );
    }

    // respiratory: 호흡기 질환 보유
    if (hasResp) {
      return (
        '당신에게 마스크는',
        '호흡기가 민감하시잖아요. 적은 농도에도 영향 받기 때문에 마스크가 보호선이 됩니다.',
      );
    }

    // cardiovascular 단독 (compound 아닌 경우)
    if (hasCardio) {
      return (
        '당신에게 마스크는',
        '호흡기 상태와 활동량 모두 신경 쓰시는 분이에요. 마스크가 노출 시간을 줄이는 보호선이에요.',
      );
    }

    // sensitive: 취약 연령 or 흡연
    if (p.isVulnerableAge || isSmoking) {
      return (
        '당신에게 마스크는',
        '공기 변화를 빨리 알아채는 체질이에요. 수치가 낮은 날에도 마스크가 도움됩니다.',
      );
    }

    // general: 균형 유지형
    return (
      '당신에게 마스크는',
      '지금은 특별히 위험한 상태는 아니에요. 다만 황사나 고농도 미세먼지가 있는 날엔 마스크가 도움됩니다.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, body) = _resolve(profile);

    return Container(
      padding: const EdgeInsets.all(AppTokens.cardLg),
      decoration: BoxDecoration(
        color: DT.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: AppTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DT.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: DT.text,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
