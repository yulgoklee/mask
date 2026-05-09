import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/korean_hero_text.dart';
import '../models/report_models.dart';

/// 리포트 탭 Hero — 이번 주 양(quantity) 압도적 표시
///
/// animate 적용 X (케어 Hero 미적용과 일치).
class ReportHero extends StatelessWidget {
  final WeekReportState state;
  final int dangerHours;
  final double heroSize;

  const ReportHero({
    super.key,
    required this.state,
    required this.dangerHours,
    this.heroSize = 64,
  });

  /// Hero 본문 — 첫 줄은 의미적 강제 break (시안 정합), 둘째 줄은 자연 wrap.
  String get _heroText {
    switch (state) {
      case WeekReportState.empty:  return '이번 주는\n아직 데이터가 쌓이는 중이에요';
      case WeekReportState.safe:   return '이번 주,\n내 기준을 넘은 시간은 없었어요';
      case WeekReportState.normal: return '이번 주,\n$dangerHours시간 위험에 노출됐어요';
    }
  }

  String? get _sub {
    if (state == WeekReportState.empty) {
      return '며칠 더 지나면 한 주를 정리해 드릴게요';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 한국어 단어 단위 줄바꿈, 64pt 유지 (폭 좁아도 글씨 안 줄임)
        KoreanHeroText(
          text: _heroText,
          style: TextStyle(
            fontSize:      heroSize,
            fontWeight:    FontWeight.w700,
            color:         DT.text,
            height:        1.08,
            letterSpacing: -heroSize * 0.035,
          ),
        ),
        if (_sub != null) ...[
          const SizedBox(height: 14),
          Text(
            _sub!,
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
