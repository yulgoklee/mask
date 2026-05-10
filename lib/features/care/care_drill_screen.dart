import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/engine/threshold_engine.dart';
import '../../data/models/user_profile.dart';
import '../../providers/dust_providers.dart';
import '../../providers/profile_providers.dart';
import 'care_tab.dart' as care_tab;
import 'providers/care_providers.dart';
import 'widgets/care_background.dart';
import 'widgets/trend_chart.dart';

/// Drill-down 화면 (시안 v3 — 별도 화면, sticky 헤더)
///
/// 케어 탭 "더 자세히 보기" → 이 화면으로 push.
/// 같은 그라디언트 위에 깊은 정보 노출.
class CareDrillScreen extends ConsumerWidget {
  const CareDrillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusCard = ref.watch(statusCardProvider);
    final profile    = ref.watch(profileProvider);
    final level      = CareBackground.levelFromRatio(statusCard.finalRatio);
    final base       = CareBackground.baseColor(level);
    final breakdown  = const ThresholdEngine().breakdown(profile);

    // Hero compact 카피
    final compactHero = switch (level) {
      CareRiskLevel.safe    => '오늘은 마스크 안 써도 돼요',
      CareRiskLevel.caution => '마스크 챙기시면 좋아요',
      CareRiskLevel.danger  => '오늘은 마스크 필요해요',
    };

    final tFinal = statusCard.tFinal.round();
    final pm25   = statusCard.pm25Value.round();
    final pm10   = statusCard.pm10Value?.round();
    final ratio  = statusCard.finalRatio;

    return Scaffold(
      body: CareBackground(
        level: level,
        child: SafeArea(
          child: Column(
            children: [
              // ── Sticky 헤더: back + compact hero ─────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                          color: DT.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        compactHero,
                        style: const TextStyle(
                          fontSize:      17,
                          fontWeight:    FontWeight.w700,
                          color:         DT.text,
                          letterSpacing: -0.34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 본문 (스크롤) ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. 내 임계치 자세히 ──────────────
                      const _DetailSection(title: '내 임계치 자세히'),
                      _KeyValueRow(k: '현재 PM2.5', v: '$pm25㎍/㎥'),
                      _KeyValueRow(k: '현재 PM10',  v: pm10 != null ? '$pm10㎍/㎥' : '—'),
                      _KeyValueRow(
                        k: '개인 임계치',
                        v: '$tFinal㎍/㎥',
                        highlight: base,
                      ),
                      const _KeyValueRow(
                        k: "환경공단 '나쁨' 기준",
                        v: '35㎍/㎥',
                        muted: true,
                      ),
                      _KeyValueRow(
                        k: '현재 비율',
                        v: '${ratio.toStringAsFixed(2)} (${(ratio * 100).round()}%)',
                        highlight: base,
                      ),
                      const SizedBox(height: 36),

                      // ── 2. 임계치는 어떻게 정해졌나 ───────
                      const _DetailSection(title: '내 임계치는 어떻게 정해졌나요'),
                      const _ReasonRow(
                        label: "기본값 (환경공단 '나쁨')",
                        value: '35㎍/㎥',
                        weight: 1.0,
                        note: '모든 사용자 공통 시작점',
                      ),
                      if (breakdown.wAge > 0)
                        _ReasonRow(
                          label: '연령 가중치',
                          value: '−${(35.0 * breakdown.wAge).toStringAsFixed(1)}㎍/㎥',
                          weight: breakdown.wAge,
                          note: profile.isVulnerableAge ? '취약 연령' : '연령 보정',
                        ),
                      if (breakdown.wRespiratory > 0)
                        _ReasonRow(
                          label: '호흡기 민감도',
                          value: '−${(35.0 * breakdown.wRespiratory).toStringAsFixed(1)}㎍/㎥',
                          weight: breakdown.wRespiratory,
                          note: _respiratoryNote(profile),
                        ),
                      if (breakdown.wCardiovascular > 0)
                        _ReasonRow(
                          label: '심혈관 민감도',
                          value: '−${(35.0 * breakdown.wCardiovascular).toStringAsFixed(1)}㎍/㎥',
                          weight: breakdown.wCardiovascular,
                          note: _cardioNote(profile),
                        ),
                      if (breakdown.wSmoking > 0)
                        _ReasonRow(
                          label: '흡연 이력',
                          value: '−${(35.0 * breakdown.wSmoking).toStringAsFixed(1)}㎍/㎥',
                          weight: breakdown.wSmoking,
                          note: _smokingNote(profile),
                        ),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: '계산 결과 '),
                            TextSpan(
                              text: '$tFinal㎍/㎥',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color:      DT.text,
                              ),
                            ),
                            const TextSpan(
                              text: '가 내 임계치예요. 프로필에서 호흡기 정보를 바꾸면 다시 계산됩니다.',
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize:      12,
                          fontWeight:    FontWeight.w500,
                          color:         DT.gray,
                          height:        1.5,
                          letterSpacing: -0.06,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── 3. 12시간 흐름 (큰 버전) ──────────
                      const _DetailSection(title: '오늘 12시간 흐름'),
                      const TrendChart(),
                      const SizedBox(height: 36),

                      // ── 4. 자료원 ────────────────────────
                      const _DetailSection(title: '자료원'),
                      const _SourceRow(
                        title: '한국환경공단 AirKorea',
                        sub:   '실시간 PM2.5·PM10 측정망 · 전국 약 600개소',
                      ),
                      const _SourceRow(
                        title: '개인 호흡기·심혈관 정보',
                        sub:   '온보딩 6문항 · 프로필에서 수정 가능',
                      ),
                      const _SourceRow(
                        title: '의학 가이드라인',
                        sub:   'ARIA · ATS EIB · WHO 2021 · 대한천식알레르기학회',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단이나 처방을 대체하지 않습니다.',
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                          color:      DT.gray,
                          height:     1.55,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 푸터: 위치 · 갱신 ─────────────────
                      const _DrillFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 푸터 (Drill 전용 — care_tab.dart 함수 재사용) ──────────

class _DrillFooter extends ConsumerWidget {
  const _DrillFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);
    return dustAsync.when(
      data: (dust) {
        if (dust == null) return const SizedBox.shrink();
        final sido = ref.watch(stationSidoProvider).valueOrNull;
        return Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 12, color: DT.gray),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                care_tab.locationLabel(sido, dust.stationName),
                style: const TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                  color:      DT.gray,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Text(
              care_tab.dataTimeLabel(dust.dataTime),
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      DT.gray,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── 섹션 라벨 ─────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String title;
  const _DetailSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize:      13,
          fontWeight:    FontWeight.w700,
          color:         DT.gray,
          letterSpacing: 0.52,
        ),
      ),
    );
  }
}

// ── KeyValueRow (hairline 행) ─────────────────────────────

class _KeyValueRow extends StatelessWidget {
  final String k;
  final String v;
  final Color? highlight;
  final bool   muted;

  const _KeyValueRow({
    required this.k,
    required this.v,
    this.highlight,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DT.text.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                fontSize:      14,
                fontWeight:    FontWeight.w500,
                color:         muted ? DT.gray : DT.text,
                letterSpacing: -0.14,
              ),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize:      15,
              fontWeight:    FontWeight.w700,
              color:         highlight ?? (muted ? DT.gray : DT.text),
              letterSpacing: -0.15,
              fontFamily:    'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── ReasonRow (가중치 노출) ───────────────────────────────

class _ReasonRow extends StatelessWidget {
  final String label;
  final String value;
  final double weight;
  final String note;

  const _ReasonRow({
    required this.label,
    required this.value,
    required this.weight,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DT.text.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize:      14,
                    fontWeight:    FontWeight.w600,
                    color:         DT.text,
                    letterSpacing: -0.14,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize:      14,
                  fontWeight:    FontWeight.w700,
                  color:         DT.text,
                  letterSpacing: -0.14,
                  fontFamily:    'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      DT.gray,
                  ),
                ),
              ),
              Text(
                '가중치 ${weight.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                  color:      DT.gray,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── SourceRow ─────────────────────────────────────────────

class _SourceRow extends StatelessWidget {
  final String title;
  final String sub;

  const _SourceRow({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize:      14,
              fontWeight:    FontWeight.w600,
              color:         DT.text,
              letterSpacing: -0.14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w500,
              color:      DT.gray,
              height:     1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── note 헬퍼 ─────────────────────────────────────────────

String _respiratoryNote(UserProfile profile) {
  final items = <String>[];
  if (profile.asthma)   items.add('천식');
  if (profile.copd)     items.add('COPD');
  if (profile.rhinitis) items.add('비염');
  if (profile.allergy)  items.add('알레르기');
  return items.isEmpty ? '진단 없음' : items.join('·');
}

String _cardioNote(UserProfile profile) {
  final items = <String>[];
  if (profile.hypertension) items.add('고혈압');
  if (profile.heartDisease) items.add('심장 질환');
  if (profile.stroke)       items.add('뇌졸중');
  return items.isEmpty ? '진단 없음' : items.join('·');
}

String _smokingNote(UserProfile profile) {
  switch (profile.smokingStatus) {
    case SmokingStatus.current: return '현재 흡연 중';
    case SmokingStatus.former:  return '과거 흡연';
    case SmokingStatus.never:   return '비흡연';
  }
}
