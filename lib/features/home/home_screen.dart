import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dust_standards.dart';
import '../../core/services/air_korea_service.dart' show AirKoreaService;
import '../../data/models/forecast_models.dart';
import '../../providers/providers.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/dust_gauge_widget.dart';
import 'dust_detail_screen.dart';
import 'dust_status_card.dart';
import 'dust_forecast_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);
    final calcResult = ref.watch(dustCalculationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '마스크 알림',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(dustDataProvider);
              ref.invalidate(tomorrowForecastProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dustDataProvider);
          ref.invalidate(tomorrowForecastProvider);
        },
        child: dustAsync.when(
          loading: () => const LoadingStateWidget(message: '미세먼지 정보 불러오는 중...'),
          error: (e, _) => ErrorStateWidget(
            message: '미세먼지 정보를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
            onRetry: () {
              ref.invalidate(dustDataProvider);
              ref.invalidate(tomorrowForecastProvider);
            },
          ),
          data: (dust) {
            if (dust == null) {
              return ErrorStateWidget(
                message: '측정소 데이터가 없어요.\n측정소 이름을 확인하거나\n다른 측정소를 선택해 보세요.',
                icon: Icons.location_off_outlined,
                onRetry: () => ref.invalidate(dustDataProvider),
              );
            }

            final pm25Grade =
                DustStandards.getPm25Grade(dust.pm25Value ?? 0);
            final pm10Grade =
                DustStandards.getPm10Grade(dust.pm10Value ?? 0);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 측정소 + 업데이트 시간
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        dust.stationName,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showStationPicker(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '변경',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(dust.dataTime),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 나의 위험도 카드
                  if (calcResult != null) DustStatusCard(result: calcResult),
                  const SizedBox(height: 20),

                  // 미세먼지 / 초미세먼지 게이지 (탭하면 세부정보)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DustDetailScreen(
                                pm10Value: dust.pm10Value,
                                pm25Value: dust.pm25Value,
                                pm10Grade: pm10Grade,
                                pm25Grade: pm25Grade,
                              ),
                            ),
                          ),
                          child: DustGaugeWidget(
                            value: dust.pm10Value,
                            label: 'PM10',
                            grade: pm10Grade,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DustDetailScreen(
                                pm10Value: dust.pm10Value,
                                pm25Value: dust.pm25Value,
                                pm10Grade: pm10Grade,
                                pm25Grade: pm25Grade,
                              ),
                            ),
                          ),
                          child: DustGaugeWidget(
                            value: dust.pm25Value,
                            label: 'PM2.5',
                            grade: pm25Grade,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 시간별 예보
                  _buildHourlySection(context, ref),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHourlySection(BuildContext context, WidgetRef ref) {
    final stationName =
        ref.read(dustRepositoryProvider).savedStation ?? '강남구';
    // 로컬 매핑 우선, 없으면 숫자 제거한 측정소명으로 fallback
    final sidoName = AirKoreaService.sidoForStation(stationName)
        ?? stationName.replaceAll(RegExp(r'\d'), '').trim();
    final hourlyAsync = ref.watch(hourlyDataProvider(stationName));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DustForecastDetailScreen(
            stationName: stationName,
            sidoName: sidoName,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('시간별 현황',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const Spacer(),
                const Text('자세히 보기',
                    style: TextStyle(fontSize: 11, color: AppColors.primary)),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            hourlyAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
              ),
              error: (_, __) => _InlineErrorTile(
                message: '시간별 현황을 불러올 수 없어요.',
                onRetry: () => ref.invalidate(
                    hourlyDataProvider(stationName)),
              ),
              data: (List<HourlyDustData> items) {
                if (items.isEmpty) {
                  return const _InlineEmptyTile(message: '시간별 데이터가 없어요.');
                }
                return _HourlyForecastTile(items: items);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.month}/${dt.day} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')} 기준';

  Future<void> _showStationPicker(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(dustRepositoryProvider);
    final controller = TextEditingController(text: repo.savedStation ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('측정소 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '에어코리아 측정소명을 입력하세요.\n예) 수원, 강남구, 해운대구',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '측정소명 입력',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await repo.changeStation(name);
                ref.invalidate(dustDataProvider);
                ref.invalidate(tomorrowForecastProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('저장',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


// ── 시간별 예보 ───────────────────────────────────────────

class _HourlyForecastTile extends StatelessWidget {
  final List<HourlyDustData> items;
  const _HourlyForecastTile({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final item = items[i];
          final isNow = (i == 0);
          final forecast = item.isForecast;
          final timeLabel = isNow ? '지금' : '${item.time.hour}시';

          return Opacity(
            opacity: forecast ? 0.55 : 1.0,
            child: Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isNow ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isNow
                    ? Border.all(color: AppColors.primary.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                        color: isNow ? AppColors.primary : AppColors.textSecondary,
                      )),
                  if (forecast)
                    const Text('예보',
                        style: TextStyle(fontSize: 8, color: AppColors.textHint)),
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  Text(item.pm10Grade.emoji,
                      style: const TextStyle(fontSize: 15)),
                  Text('미세',
                      style: TextStyle(fontSize: 9, color: item.pm10Grade.color)),
                  Text(item.pm10Grade.label,
                      style: TextStyle(
                          fontSize: 10,
                          color: item.pm10Grade.color,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  Text(item.pm25Grade.emoji,
                      style: const TextStyle(fontSize: 15)),
                  Text('초미세',
                      style: TextStyle(fontSize: 9, color: item.pm25Grade.color)),
                  Text(item.pm25Grade.label,
                      style: TextStyle(
                          fontSize: 10,
                          color: item.pm25Grade.color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 카드 내부 인라인 에러 ─────────────────────────────────

class _InlineErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _InlineErrorTile({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4)),
              child: const Text('재시도',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

class _InlineEmptyTile extends StatelessWidget {
  final String message;
  const _InlineEmptyTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
