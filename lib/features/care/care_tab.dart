import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/design_tokens.dart';
import '../../providers/dust_providers.dart';
import '../../widgets/async_state_widgets.dart';
import 'widgets/status_card.dart';
import 'widgets/protection_area_chart.dart';
import 'widgets/pollutant_detail_card.dart';

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
