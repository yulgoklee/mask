import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dust_standards.dart';
import '../../core/services/air_korea_service.dart' show AirKoreaService;
import '../../core/services/location_service.dart';
import '../../data/models/forecast_models.dart';
import '../../data/repositories/dust_repository.dart';
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
          loading: () =>
              const LoadingStateWidget(message: '미세먼지 정보 불러오는 중...'),
          error: (e, _) => ErrorStateWidget(
            message: '미세먼지 정보를 불러올 수 없어요.\n네트워크 연결을 확인해 주세요.',
            onRetry: () {
              ref.invalidate(dustDataProvider);
              ref.invalidate(tomorrowForecastProvider);
            },
          ),
          data: (dust) {
            // 측정소 미설정 → 위치 설정 유도
            if (dust == null) {
              return _NoStationWidget(
                onSetup: () => Navigator.of(context)
                    .pushNamed('/location_setup'),
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
        ref.read(dustRepositoryProvider).savedStation ?? '';
    if (stationName.isEmpty) return const SizedBox.shrink();

    final sidoName = AirKoreaService.sidoForStation(stationName) ??
        stationName.replaceAll(RegExp(r'\d'), '').trim();
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
                onRetry: () =>
                    ref.invalidate(hourlyDataProvider(stationName)),
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
    final locService = ref.read(locationServiceProvider);
    final controller = TextEditingController(text: repo.savedStation ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => _StationPickerDialog(
        controller: controller,
        repo: repo,
        locService: locService,
        onSaved: () {
          ref.invalidate(dustDataProvider);
          ref.invalidate(tomorrowForecastProvider);
        },
      ),
    );
  }
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

// ── 측정소 변경 다이얼로그 (GPS + 직접 입력) ──────────────

class _StationPickerDialog extends StatefulWidget {
  final TextEditingController controller;
  final DustRepository repo;
  final LocationService locService;
  final VoidCallback onSaved;

  const _StationPickerDialog({
    required this.controller,
    required this.repo,
    required this.locService,
    required this.onSaved,
  });

  @override
  State<_StationPickerDialog> createState() => _StationPickerDialogState();
}

class _StationPickerDialogState extends State<_StationPickerDialog> {
  bool _detecting = false;
  String? _detectError;
  VoidCallback? _settingsAction;

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _detectError = null;
      _settingsAction = null;
    });

    final result = await widget.repo.detectAndSaveStation();
    if (!mounted) return;

    if (result.isSuccess) {
      widget.onSaved();
      Navigator.pop(context);
      return;
    }

    String msg;
    VoidCallback? action;
    switch (result.error) {
      case LocationError.serviceDisabled:
        msg = 'GPS가 꺼져 있어요. 위치 서비스를 켜주세요.';
        action = () => widget.locService.openLocationSettings();
      case LocationError.permissionDeniedForever:
        msg = '위치 권한이 거절되었어요. 설정에서 허용해주세요.';
        action = () => widget.locService.openAppSettings();
      case LocationError.permissionDenied:
        msg = '위치 권한을 허용해야 자동 감지가 가능해요.';
        action = null;
      case LocationError.timeout:
        msg = '위치를 찾을 수 없어요. 다시 시도해주세요.';
        action = null;
      default:
        msg = '위치 감지에 실패했어요. 직접 입력해주세요.';
        action = null;
    }

    setState(() {
      _detecting = false;
      _detectError = msg;
      _settingsAction = action;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('지역 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS 자동 감지
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _detecting ? null : _detectLocation,
              icon: _detecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(_detecting ? '위치 감지 중...' : '현재 위치로 자동 감지'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_detectError != null) ...[
            const SizedBox(height: 6),
            Text(_detectError!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.error, height: 1.4)),
            if (_settingsAction != null)
              TextButton(
                onPressed: _settingsAction,
                style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2)),
                child: const Text('설정 열기',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            '시·군·구 직접 입력\n예) 수원, 강남구, 해운대구',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            autofocus: false,
            decoration: const InputDecoration(
              hintText: '지역명 입력',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        ElevatedButton(
          onPressed: () async {
            final name = widget.controller.text.trim();
            if (name.isNotEmpty) {
              await widget.repo.changeStation(name);
              widget.onSaved();
            }
            if (mounted) Navigator.pop(context);
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('저장', style: TextStyle(color: Colors.white)),
        ),
      ],
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
                  Text(timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isNow ? FontWeight.bold : FontWeight.normal,
                        color: isNow
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      )),
                  if (forecast)
                    const Text('예보',
                        style: TextStyle(
                            fontSize: 8, color: AppColors.textHint)),
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
