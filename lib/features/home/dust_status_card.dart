import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dust_calculator.dart';
import '../../providers/providers.dart';
import 'risk_detail_screen.dart';

/// 홈 화면 — 행동 카드
///
/// 레이아웃 우선순위: 이모지 → [이름]님 → 행동 결론(hero) → 마스크 타입 → 구분선 → 근거 → 맥락
class DustStatusCard extends ConsumerWidget {
  final DustCalculationResult result;

  const DustStatusCard({super.key, required this.result});

  Color get _bgColor {
    switch (result.riskLevel) {
      case RiskLevel.low:      return AppColors.dustGood;
      case RiskLevel.normal:   return AppColors.dustNormal;
      case RiskLevel.warning:  return AppColors.dustBad;
      case RiskLevel.danger:   return AppColors.dustBad;
      case RiskLevel.critical: return AppColors.dustVeryBad;
      case RiskLevel.unknown:  return AppColors.textSecondary;
    }
  }

  String get _emoji {
    switch (result.riskLevel) {
      case RiskLevel.low:      return '😊';
      case RiskLevel.normal:   return '🙂';
      case RiskLevel.warning:  return '😷';
      case RiskLevel.danger:   return '⚠️';
      case RiskLevel.critical: return '🚨';
      case RiskLevel.unknown:  return '❓';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiskDetailScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgColor, _bgColor.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _bgColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지
            Text(_emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),

            // [이름]님, (있을 때만)
            if (profile.name != null && profile.name!.isNotEmpty) ...[
              Text(
                '${profile.name}님,',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
            ],

            // 행동 결론 (hero text)
            Text(
              result.heroText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            // 마스크 타입 pill (마스크 필요할 때만)
            if (result.maskRequired) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.masks, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '마스크 착용 권고',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result.maskType != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.maskType!,
                        style: TextStyle(
                          color: _bgColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // 구분선
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.3), height: 1),
            const SizedBox(height: 12),

            // PM2.5 근거 (보조 정보)
            if (result.reason.isNotEmpty)
              Text(
                result.reason,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

            // 개인화 맥락 (기저질환·민감도 등)
            if (result.personalNote != null) ...[
              const SizedBox(height: 4),
              Text(
                result.personalNote!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],

            // 상세 보기
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('상세 보기',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, color: Colors.white70, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
