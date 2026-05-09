import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/dust_providers.dart';
import '../../widgets/async_state_widgets.dart';
import 'providers/care_providers.dart';
import 'widgets/care_background.dart';
import 'widgets/care_hero.dart';
import 'widgets/threshold_meter.dart';
import 'widgets/protection_area_chart.dart';
import 'widgets/pollutant_detail_card.dart';

// ── 위치 표시 ────────────────────────────────────────────
String locationLabel(String? sido, String stationName) {
  if (sido == null || sido.isEmpty) return stationName;
  if (stationName.startsWith(sido)) return stationName;
  return '$sido $stationName';
}

// ── 갱신 시각 표시 ───────────────────────────────────────
String dataTimeLabel(DateTime dt) {
  final isAm  = dt.hour < 12;
  final h12   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  return '${isAm ? "오전" : "오후"} $h12시 기준';
}

// ── 예보 오류 배너 (그라디언트 위에 가벼운 인라인) ────────────

class _ForecastErrorBanner extends ConsumerWidget {
  const _ForecastErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(tomorrowForecastProvider);
    if (!forecastAsync.hasError) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 14, color: DT.gray),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '내일 예보를 불러오지 못했어요',
              style: TextStyle(fontSize: 12, color: DT.gray, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: () => ref.invalidate(tomorrowForecastProvider),
            child: const Icon(Icons.refresh, size: 14, color: DT.gray),
          ),
        ],
      ),
    );
  }
}

// ── 미세먼지 수치 표시 (공공 측정 — 노출 OK) ─────────────────

class _PollutantValues extends StatelessWidget {
  final double pm25;
  final double? pm10;

  const _PollutantValues({required this.pm25, required this.pm10});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ValueColumn(label: '초미세먼지', value: pm25.round())),
        const SizedBox(width: 32),
        Expanded(child: _ValueColumn(label: '미세먼지', value: pm10?.round())),
      ],
    );
  }
}

class _ValueColumn extends StatelessWidget {
  final String label;
  final int? value;

  const _ValueColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      DT.gray,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? '—',
          style: const TextStyle(
            fontSize:   26,
            fontWeight: FontWeight.w700,
            color:      DT.text,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ── 푸터 (위치 · 갱신 시각) ───────────────────────────────

class _CareFooter extends ConsumerWidget {
  const _CareFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);
    return dustAsync.when(
      data: (dust) {
        if (dust == null) return const SizedBox.shrink();
        final sido = ref.watch(stationSidoProvider).valueOrNull;
        return Text(
          '${locationLabel(sido, dust.stationName)} · ${dataTimeLabel(dust.dataTime)}',
          style: const TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w500,
            color:      DT.gray,
            letterSpacing: -0.1,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── 케어 탭 (시각 재설계 v3 — 카드 X, Hero + 배경 그라디언트) ───

class CareTab extends ConsumerWidget {
  const CareTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);

    if (dustAsync.hasError) {
      return Scaffold(
        backgroundColor: DT.background,
        body: ErrorStateWidget(
          message: '미세먼지 정보를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
          onRetry: () {
            ref.invalidate(dustDataProvider);
            ref.invalidate(tomorrowForecastProvider);
          },
        ),
      );
    }

    final statusCard = ref.watch(statusCardProvider);
    final level = CareBackground.levelFromRatio(statusCard.finalRatio);

    return Scaffold(
      body: CareBackground(
        level: level,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dustDataProvider);
              ref.invalidate(tomorrowForecastProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 인사 + Hero 답 ──────────────────────────
                  CareHero(
                    level:    level,
                    nickname: statusCard.nickname,
                  ),
                  const SizedBox(height: 52),

                  // ── 미세먼지 수치 (공공 측정 노출 OK) ────────
                  _PollutantValues(
                    pm25: statusCard.pm25Value,
                    pm10: statusCard.pm10Value,
                  ),
                  const SizedBox(height: 36),

                  // ── 내 기준 위치 미터 ───────────────────────
                  ThresholdMeter(
                    ratio: statusCard.finalRatio,
                    level: level,
                  ),
                  const SizedBox(height: 28),

                  // ── 12시간 흐름 차트 (다음 단계에서 카드 X 처리) ─
                  const ProtectionAreaChart(),
                  const SizedBox(height: 28),

                  // ── 푸터: 위치 · 갱신 시각 ──────────────────
                  const _CareFooter(),
                  const SizedBox(height: 24),

                  // ── 예보 에러 (있으면) ──────────────────────
                  const _ForecastErrorBanner(),

                  // ── 자세히 보기 (Drill-down) — 다음 단계에서 펼침 처리 ─
                  const PollutantDetailCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
