import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/design_tokens.dart';
import 'care_background.dart';

/// 케어 탭 Hero — 인사 + 큰 타이포 답 (시안 v3 정확)
///
/// 자연 줄바꿈 (강제 \n X). wordBreak: keep-all.
class CareHero extends StatelessWidget {
  final CareRiskLevel level;
  final String nickname;
  final double heroSize;
  final bool showSub;

  const CareHero({
    super.key,
    required this.level,
    this.nickname = '',
    this.heroSize = 64,
    this.showSub = true,
  });

  /// 위험도별 답 텍스트 (시안 그대로)
  String get _title {
    switch (level) {
      case CareRiskLevel.safe:    return '오늘은 마스크 안 써도 돼요';
      case CareRiskLevel.caution: return '마스크 챙기시면 좋아요';
      case CareRiskLevel.danger:  return '오늘은 마스크 필요해요';
    }
  }

  /// 보조 한 줄 (시안 그대로)
  String get _sub {
    switch (level) {
      case CareRiskLevel.safe:    return '바깥 공기가 평소처럼 깨끗해요';
      case CareRiskLevel.caution: return '내 기준에 가까워지고 있어요';
      case CareRiskLevel.danger:  return '내 기준을 넘어선 시간대예요';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 인사 ────────────────────────────────────────
        if (nickname.isNotEmpty)
          Text(
            '$nickname님,',
            style: const TextStyle(
              fontSize:      16,
              fontWeight:    FontWeight.w500,
              color:         DT.gray,
              letterSpacing: -0.16,
            ),
          ),
        const SizedBox(height: 8),

        // ── Hero 답 (자연 줄바꿈, wordBreak: keep-all) ─
        Text(
          _title,
          style: TextStyle(
            fontSize:      heroSize,
            fontWeight:    FontWeight.w700,
            color:         DT.text,
            height:        1.08,
            letterSpacing: -heroSize * 0.035,
          ),
        ).animate(key: ValueKey('hero-$level'))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut),

        // ── 보조 한 줄 ──────────────────────────────────
        if (showSub) ...[
          const SizedBox(height: 14),
          Text(
            _sub,
            style: const TextStyle(
              fontSize:      16,
              fontWeight:    FontWeight.w500,
              color:         DT.gray,
              letterSpacing: -0.16,
              height:        1.4,
            ),
          ),
        ],
      ],
    );
  }
}
