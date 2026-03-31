import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dust_calculator.dart';
import 'risk_detail_screen.dart';

/// 홈 화면 - 나의 위험도 카드
class DustStatusCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiskDetailScreen()),
      ),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _bgColor,
            _bgColor.withOpacity(0.7),
          ],
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
          Row(
            children: [
              const Text(
                '나의 위험도',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.riskLevel.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (result.maskRequired) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.masks, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '마스크 착용 권고',
                        style: const TextStyle(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text('상세 보기',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right, color: Colors.white70, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
