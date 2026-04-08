import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dust_standards.dart';
import '../../core/services/air_korea_service.dart' show AirKoreaService;
import '../../data/models/forecast_models.dart';
import '../../providers/providers.dart';
import '../location_setup/location_setup_screen.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/dust_gauge_widget.dart';
import 'dust_detail_screen.dart';
import 'dust_status_card.dart';
import 'dust_forecast_detail_screen.dart';

final _analytics = FirebaseAnalytics.instance;

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
              _analytics.logEvent(name: 'home_refreshed');
              ref.invalidate(dustDataProvider);
              ref.invalidate(tomorrowForecastProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _analytics.logEvent(name: 'home_refreshed');
          ref.invalidate(dustDataProvider);
          ref.invalidate(tomorrowForecastProvider);
          // 새로고침 완료까지 대기
          await ref.read(dustDataProvider.future).catchError((_) => null);
        },
        child: dustAsync.when(
          // 새로고침 중엔 이전 데이터 유지 (깜빡임 방지)
          skipLoadingOnRefresh: true,
          loading: () =>
              const LoadingStateWidget(message: '미세먼지 정보 불러오는 중...'),
          error: (e, _) {
            _analytics.logEvent(
              name: 'api_error',
              parameters: {'error_type': e.runtimeType.toString()},
            );
            return ErrorStateWidget(
              message: '미세먼지 정보를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
              onRetry: () {
                ref.invalidate(dustDataProvider);
                ref.invalidate(tomorrowForecastProvider);
              },
            );
          },
          data: (dust) {
            final savedStation =
                ref.read(dustRepositoryProvider).savedStation;

            // 측정소 자체가 미설정 → 위치 설정 유도
            if (savedStation == null) {
              return _NoStationWidget(
                onSetup: () => Navigator.of(context)
                    .pushNamed('/location_setup'),
              );
            }

            // 측정소는 설정됐지만 API가 데이터를 못 가져온 경우 → 재시도
            if (dust == null) {
              return ErrorStateWidget(
                icon: Icons.cloud_off_outlined,
                message: '[$savedStation] 데이터를 가져올 수 없어요.\n잠시 후 다시 시도해 주세요.',
                onRetry: () {
                  ref.invalidate(dustDataProvider);
                  ref.invalidate(tomorrowForecastProvider);
                },
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
                        AirKoreaService.displayLocation(savedStation),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LocationSetupScreen(),
                          ),
                        ).then((_) {
                          ref.invalidate(dustDataProvider);
                          ref.invalidate(tomorrowForecastProvider);
                        }),
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
        ref.read(dustRepositoryProvider).savedStation ?? '';
    if (stationName.isEmpty) return const SizedBox.shrink();

    final sidoName = AirKoreaService.sidoForStation(stationName) ??
        stationName.replaceAll(RegExp(r'\d'), '').trim();
    final hourlyAsync = ref.watch(hourlyDataProvider(stationName));

    return GestureDetector(
      onTap: () {
        _analytics.logEvent(name: 'detail_screen_opened');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DustForecastDetailScreen(
              stationName: stationName,
              sidoName: sidoName,
            ),
          ),
        );
      },
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
                onRetry: () =>
                    ref.invalidate(hourlyDataProvider(stationName)),
              ),
              data: (List<HourlyDustData> items) {
                if (items.isEmpty) {
                  return const _InlineEmptyTile(message: '시간별 데이터가 없어요.');
                }
                return _HourlyForecastTile(items: items.take(12).toList());
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

}

// ── 위치 미설정 상태 ──────────────────────────────────────

class _NoStationWidget extends StatelessWidget {
  final VoidCallback onSetup;
  const _NoStationWidget({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              '위치가 설정되지 않았어요.\n내 지역을 먼저 설정해주세요.',
              style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('지역 설정하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
          final isMidnight = !isNow && item.time.hour == 0;
          const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
          // 자정: 날짜+요일만 1줄 표시 (00시는 생략 — 타일 높이 유지)
          final timeLabel = isNow
              ? '지금'
              : isMidnight
                  ? '${item.time.month}/${item.time.day}'
                      '(${_weekdays[item.time.weekday - 1]})'
                  : '${item.time.hour}시';

          return Opacity(
            opacity: item.isForecast ? 0.55 : 1.0,
            child: Container(
              width: 58,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isNow
                    ? AppColors.primary.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isNow
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 16,
                    child: Center(
                      child: Text(
                        timeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMidnight ? 10 : 12,
                          fontWeight:
                              isNow ? FontWeight.bold : FontWeight.normal,
                          color: isNow
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  Text(item.pm10Grade.emoji,
                      style: const TextStyle(fontSize: 15)),
                  Text('미세',
                      style: TextStyle(
                          fontSize: 9, color: item.pm10Grade.color)),
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
                      style: TextStyle(
                          fontSize: 9, color: item.pm25Grade.color)),
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
          const Icon(Icons.error_outline, size: 18, color: AppColors.textHint),
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
                  style:
                      TextStyle(fontSize: 12, color: AppColors.primary)),
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
