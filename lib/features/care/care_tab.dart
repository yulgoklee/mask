import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/dust_providers.dart';
import '../../widgets/async_state_widgets.dart';
import 'providers/care_providers.dart';
import 'widgets/care_background.dart';
import 'widgets/care_hero.dart';
import 'widgets/threshold_meter.dart';
import 'widgets/pollutant_row.dart';
import 'widgets/trend_chart.dart';

// ── 위치 표시 ────────────────────────────────────────────
String locationLabel(String? sido, String stationName) {
  if (sido == null || sido.isEmpty) return stationName;
  if (stationName.startsWith(sido)) return stationName;
  return '$sido $stationName';
}

// ── 갱신 시각 표시 ───────────────────────────────────────
String dataTimeLabel(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m 갱신';
}

// ── 예보 오류 배너 ───────────────────────────────────────

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

// ── 하단 푸터 (위치·시간 + 더 자세히 보기) ─────────────────

class _CareFooter extends ConsumerWidget {
  const _CareFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);
    return dustAsync.when(
      data: (dust) {
        if (dust == null) return const SizedBox.shrink();
        final sido = ref.watch(stationSidoProvider).valueOrNull;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 위치 + 갱신 (좌측, 핀 아이콘)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: DT.gray),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${locationLabel(sido, dust.stationName)}  ·  ${dataTimeLabel(dust.dataTime)}',
                      style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color:      DT.gray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 더 자세히 보기 (우측, 화살표)
            const _MoreLink(),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── 더 자세히 보기 진입 (시안 v3) ─────────────────────────

class _MoreLink extends StatelessWidget {
  const _MoreLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/care/details'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '더 자세히 보기',
              style: TextStyle(
                fontSize:      14,
                fontWeight:    FontWeight.w600,
                color:         DT.text,
                letterSpacing: -0.14,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: DT.text),
          ],
        ),
      ),
    );
  }
}

// ── 케어 탭 (시안 v3 정확) ───────────────────────────────

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
                  // ① 인사
                  if (statusCard.nickname.isNotEmpty)
                    CareHero(
                      level:    level,
                      nickname: statusCard.nickname,
                      heroSize: 64,
                      showSub:  true,
                    )
                  else
                    CareHero(
                      level:    level,
                      heroSize: 64,
                      showSub:  true,
                    ),
                  const SizedBox(height: 52),

                  // ③ 미세먼지 수치 (PM2.5·PM10) + hint
                  PollutantRow(
                    pm25:      statusCard.pm25Value,
                    pm10:      statusCard.pm10Value,
                    threshold: statusCard.tFinal,
                    level:     level,
                  ),
                  const SizedBox(height: 36),

                  // ④ 내 기준 위치 미터
                  ThresholdMeter(
                    pm25:      statusCard.pm25Value,
                    threshold: statusCard.tFinal,
                    level:     level,
                  ),
                  const SizedBox(height: 28),

                  // ⑤ 12시간 흐름 (라인 차트)
                  const TrendChart(),
                  const SizedBox(height: 24),

                  // 예보 에러 (있으면)
                  const _ForecastErrorBanner(),

                  // ⑥ 위치 + 갱신 시각 + ⑦ 더 자세히 보기 (시안 footer)
                  const _CareFooter(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
