import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/dust_providers.dart';
import '../../widgets/async_state_widgets.dart';
import 'widgets/status_card.dart';
import 'widgets/protection_area_chart.dart';
import 'widgets/pollutant_detail_card.dart';

// ── 갱신 시각 자연어 변환 ─────────────────────────────────
// 1곳에서만 사용 → care_tab.dart 내 top-level 함수로 유지.
// @visibleForTesting 없이도 테스트에서 import 가능 (public 함수).
String relativeTimeLabel(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24)   return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

// ── 예보 오류 배너 ────────────────────────────────────────

class _ForecastErrorBanner extends ConsumerWidget {
  const _ForecastErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(tomorrowForecastProvider);
    if (!forecastAsync.hasError) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 16, color: Color(0xFFF97316)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '내일 예보를 불러오지 못했어요. 차트는 현재 수치 기준으로 표시돼요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: () => ref.invalidate(tomorrowForecastProvider),
            child: const Icon(Icons.refresh, size: 16, color: Color(0xFFF97316)),
          ),
        ],
      ),
    );
  }
}

// ── 케어 탭 ──────────────────────────────────────────────

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

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dustDataProvider);
            ref.invalidate(tomorrowForecastProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── 페이지 상단 타이틀 (§3.1) ──────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '케어',
                        style: TextStyle(
                          fontSize:   24,
                          fontWeight: FontWeight.w600,
                          color:      DT.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      dustAsync.when(
                        data: (dust) => dust != null
                            ? Text(
                                '${dust.stationName} · ${relativeTimeLabel(dust.dataTime)}',
                                style: const TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w500,
                                  color:      DT.gray,
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error:   (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 카드 목록 ─────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _ForecastErrorBanner(),
                    const StatusCard(),
                    const SizedBox(height: 20),   // 카드 간격 (§3.5)
                    const ProtectionAreaChart(),
                    const SizedBox(height: 20),   // 카드 간격 (§3.5)
                    const PollutantDetailCard(),
                    const SizedBox(height: 24),   // 하단 여백
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
