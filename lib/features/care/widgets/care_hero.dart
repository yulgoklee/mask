import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/design_tokens.dart';
import 'care_background.dart';

/// 케어 탭 Hero — 인사 + 큰 타이포 답
///
/// 시안 v3 채택. 카드 X, 화면 자체가 메시지.
/// 사실 표시 톤 (행동 명령 X): "필요해요" / "안 써도 돼요" / "챙기시면 좋아요"
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

  /// 위험도별 답 텍스트 (사실 표시, 명령 X)
  String get _title {
    switch (level) {
      case CareRiskLevel.safe:
        return '오늘은 마스크\n안 써도 돼요';
      case CareRiskLevel.caution:
        return '마스크\n챙기시면 좋아요';
      case CareRiskLevel.danger:
        return '지금 마스크\n필요해요';
    }
  }

  /// 보조 한 줄 (16pt 그레이) — 사실 표시 + 부드러운 권유
  String get _sub {
    switch (level) {
      case CareRiskLevel.safe:    return '공기가 깨끗해요';
      case CareRiskLevel.caution: return '외출 시 챙기시는 게 좋아요';
      case CareRiskLevel.danger:  return '외출 전 꼭 챙겨주세요';
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
              fontSize:   16,
              fontWeight: FontWeight.w500,
              color:      DT.gray,
              letterSpacing: -0.2,
            ),
          ),
        const SizedBox(height: 8),

        // ── Hero 답 ─────────────────────────────────────
        Text(
          _title,
          style: TextStyle(
            fontSize:   heroSize,
            fontWeight: FontWeight.w700,
            color:      DT.text,
            height:     1.1,
            letterSpacing: -1.2,
          ),
        ).animate(key: ValueKey('hero-$level'))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut),

        // ── 보조 한 줄 ──────────────────────────────────
        if (showSub) ...[
          const SizedBox(height: 16),
          Text(
            _sub,
            style: const TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w400,
              color:      DT.gray,
              height:     1.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}
