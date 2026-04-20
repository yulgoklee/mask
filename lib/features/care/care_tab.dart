import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/dust_providers.dart';
import '../../widgets/async_state_widgets.dart';
import 'widgets/status_card.dart';
import 'widgets/protection_area_chart.dart';
import 'widgets/pollutant_detail_card.dart';

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
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
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

class CareTab extends ConsumerWidget {
  const CareTab({super.key});

  void _retry(WidgetRef ref) {
    ref.invalidate(dustDataProvider);
    ref.invalidate(tomorrowForecastProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);

    if (dustAsync.hasError) {
      return Scaffold(
        backgroundColor: DT.background,
        body: ErrorStateWidget(
          message: '미세먼지 정보를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
          onRetry: () => _retry(ref),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dustDataProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        '케어',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DT.text,
                        ),
                      ),
                      const Spacer(),
                      dustAsync.when(
                        data: (dust) => dust != null
                            ? Text(
                                '${dust.stationName} · ${_relativeTime(dust.dataTime)}',
                                style: const TextStyle(fontSize: 12, color: DT.gray),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _ForecastErrorBanner(),
                    const StatusCard(),
                    const SizedBox(height: 16),
                    const ProtectionAreaChart(),
                    const SizedBox(height: 16),
                    const PollutantDetailCard(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    return '${diff.inHours}시간 전';
  }
}
