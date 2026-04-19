import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/dust_standards.dart';
import '../../core/services/air_korea_service.dart' show AirKoreaService;
import '../../core/utils/dust_calculator.dart';
import '../../core/utils/sensitivity_calculator.dart';
import '../../data/models/dust_data.dart';
import '../../data/models/forecast_models.dart';
import '../../data/models/today_situation.dart';
import '../../providers/providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/dust_gauge_widget.dart';
import '../location_setup/location_setup_screen.dart';
import 'dust_detail_screen.dart';
import 'dust_forecast_detail_screen.dart';
import 'aqi_chart_section.dart';
import 'risk_detail_screen.dart';

final _analytics = FirebaseAnalytics.instance;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _timeGuideKey = GlobalKey();
  bool _highlightHero = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeDeepLink());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _consumeDeepLink() {
    final type = ref.read(pendingPayloadTypeProvider);
    if (type == null) return;
    ref.read(pendingPayloadTypeProvider.notifier).state = null;

    if (type == 'relief') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTimeGuide());
    } else if (type == 'risk') {
      setState(() => _highlightHero = true);
      Future.delayed(const Duration(seconds: 3),
          () { if (mounted) setState(() => _highlightHero = false); });
    }
  }

  void _scrollToTimeGuide() {
    final ctx = _timeGuideKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1);
  }

  Color _bgColor(RiskLevel? level) {
    switch (level) {
      case RiskLevel.low:      return const Color(0xFFECFDF5);
      case RiskLevel.warning:  return const Color(0xFFFFF7ED);
      case RiskLevel.danger:   return const Color(0xFFFEF2F2);
      case RiskLevel.critical: return const Color(0xFFF5F3FF);
      default:                 return AppColors.background;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingPayloadTypeProvider, (_, next) {
      if (next != null) _consumeDeepLink();
    });

    final dustAsync    = ref.watch(dustDataProvider);
    final calcResult   = ref.watch(dustCalculationProvider);
    final locationState = ref.watch(locationStateProvider);
    final profile      = ref.watch(profileProvider);

    final bgColor = _bgColor(calcResult?.riskLevel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: bgColor,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _analytics.logEvent(name: 'home_refreshed');
            ref.invalidate(dustDataProvider);
            ref.invalidate(tomorrowForecastProvider);
            await ref.read(dustDataProvider.future).catchError((_) => null);
          },
          child: dustAsync.when(
            skipLoadingOnRefresh: true,
            loading: () => const HomeSkeleton(),
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

              if (savedStation == null) {
                return _NoStationView(
                  onSetup: () =>
                      Navigator.of(context).pushNamed('/location_setup'),
                );
              }

              if (dust == null) {
                return ErrorStateWidget(
                  icon: Icons.cloud_off_outlined,
                  message:
                      '[$savedStation] 데이터를 가져올 수 없어요.\n잠시 후 다시 시도해 주세요.',
                  onRetry: () {
                    ref.invalidate(dustDataProvider);
                    ref.invalidate(tomorrowForecastProvider);
                  },
                );
              }

              final pm25Grade = DustStandards.getPm25Grade(dust.pm25Value ?? 0);
              final pm10Grade = DustStandards.getPm10Grade(dust.pm10Value ?? 0);
              final s = SensitivityCalculator.compute(profile);
              final tFinal = SensitivityCalculator.threshold(s);

              return SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── 상단 Location 헤더 ──────────────────────
                    _LocationHeader(
                      station: savedStation,
                      dataTime: dust.dataTime,
                      isDetecting: locationState.isDetecting,
                      onChangeStation: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LocationSetupScreen()),
                      ).then((_) {
                        ref
                            .read(locationStateProvider.notifier)
                            .onStationChanged();
                        ref.invalidate(dustDataProvider);
                        ref.invalidate(tomorrowForecastProvider);
                      }),
                      onGpsRefresh: locationState.isDetecting
                          ? null
                          : () => _onGpsRefresh(context, ref),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          // ── 빅버튼 Hero ─────────────────────────
                          _HeroButton(
                            result: calcResult,
                            pm25: dust.pm25Value?.toDouble(),
                            tFinal: tFinal,
                            name: profile.nickname.isNotEmpty ? profile.nickname : null,
                            highlightOverride: _highlightHero,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RiskDetailScreen()),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── PM2.5 추이 Area Chart ───────────────
                          AqiChartSection(
                            forecastGrade: dust.pm25Grade ?? '보통',
                            timeGuideKey: _timeGuideKey,
                          ),

                          const SizedBox(height: 12),

                          // ── 오늘 상황 퀵 토글 ───────────────────
                          _TodayQuickToggle(),

                          const SizedBox(height: 16),

                          // ── PM10 / PM25 게이지 ──────────────────
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
                                    label: '미세먼지',
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
                                    label: '초미세먼지',
                                    grade: pm25Grade,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── 기타 오염물질 ────────────────────────
                          _ExtraPollutantsRow(dust: dust),

                          const SizedBox(height: 16),

                          // ── 시간별 현황 ──────────────────────────
                          _HourlySection(
                            stationName: savedStation,
                            ref: ref,
                            context: context,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _onGpsRefresh(BuildContext context, WidgetRef ref) async {
    _analytics.logEvent(name: 'gps_quick_refresh');
    final success =
        await ref.read(locationStateProvider.notifier).detectFromGps();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내 위치로 측정소를 업데이트했어요'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final state = ref.read(locationStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? '위치 감지에 실패했어요'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: state.needsSettings
              ? SnackBarAction(
                  label: '설정 열기',
                  onPressed: () =>
                      ref.read(locationServiceProvider).openAppSettings(),
                )
              : null,
        ),
      );
    }
  }
}

// ── Location 헤더 ──────────────────────────────────────────────

class _LocationHeader extends StatelessWidget {
  final String station;
  final DateTime dataTime;
  final bool isDetecting;
  final VoidCallback onChangeStation;
  final VoidCallback? onGpsRefresh;

  const _LocationHeader({
    required this.station,
    required this.dataTime,
    required this.isDetecting,
    required this.onChangeStation,
    required this.onGpsRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${dataTime.month}/${dataTime.day} '
        '${dataTime.hour.toString().padLeft(2, '0')}:'
        '${dataTime.minute.toString().padLeft(2, '0')} 기준';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // 위치 칩
          GestureDetector(
            onTap: onChangeStation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    AirKoreaService.displayLocation(station),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // GPS 갱신
          GestureDetector(
            onTap: onGpsRefresh,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: isDetecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location,
                        size: 14, color: AppColors.textSecondary),
              ),
            ),
          ),

          const Spacer(),

          Text(
            timeStr,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ── 빅버튼 Hero ────────────────────────────────────────────────
//
// 현재 마스크 필요 여부를 화면 중심에 크게 표시하는 메인 액션 버튼.
// 위험 등급이 warning 이상이면 외곽선 펄스 애니메이션 표시.

class _HeroButton extends StatefulWidget {
  final DustCalculationResult? result;
  final double? pm25;
  final double tFinal;
  final String? name;
  final bool highlightOverride;
  final VoidCallback onTap;

  const _HeroButton({
    required this.result,
    required this.pm25,
    required this.tFinal,
    required this.name,
    required this.highlightOverride,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(_HeroButton old) {
    super.didUpdateWidget(old);
    if (old.result?.riskLevel != widget.result?.riskLevel ||
        old.highlightOverride != widget.highlightOverride) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    final risk = widget.result?.riskLevel ?? RiskLevel.unknown;
    final shouldPulse = widget.highlightOverride ||
        risk == RiskLevel.warning ||
        risk == RiskLevel.danger ||
        risk == RiskLevel.critical;
    if (shouldPulse) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── 등급별 색상 ─────────────────────────────────────────────
  List<Color> _gradientColors(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case RiskLevel.normal:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case RiskLevel.warning:
        return [AppColors.coral, const Color(0xFFE8541E)];
      case RiskLevel.danger:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case RiskLevel.critical:
        return [const Color(0xFF7C3AED), const Color(0xFF6D28D9)];
      case RiskLevel.unknown:
        return [AppColors.textSecondary, const Color(0xFF475569)];
    }
  }

  String _emoji(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:      return '😊';
      case RiskLevel.normal:   return '🙂';
      case RiskLevel.warning:  return '😷';
      case RiskLevel.danger:   return '⚠️';
      case RiskLevel.critical: return '🚨';
      case RiskLevel.unknown:  return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final riskLevel = result?.riskLevel ?? RiskLevel.unknown;
    final colors = _gradientColors(riskLevel);
    final shouldPulse = widget.highlightOverride ||
        riskLevel == RiskLevel.warning ||
        riskLevel == RiskLevel.danger ||
        riskLevel == RiskLevel.critical;
    final pm25Val = widget.pm25;
    final nameStr =
        (widget.name != null && widget.name!.isNotEmpty) ? widget.name! : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 펄스 링
              if (shouldPulse)
                Opacity(
                  opacity: (1.0 - _pulseAnim.value).clamp(0.0, 0.4),
                  child: Transform.scale(
                    scale: 1.0 + _pulseAnim.value * 0.06,
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: colors[0],
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 행: 이름 + 등급 배지
              Row(
                children: [
                  Text(
                    nameStr != null ? '$nameStr님의 지금' : '지금 미세먼지',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      riskLevel.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 이모지 + PM2.5 수치 (핵심 정보)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _emoji(riskLevel),
                    style: const TextStyle(fontSize: 52),
                  ),
                  const SizedBox(width: 16),
                  if (pm25Val != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pm25Val.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'PM2.5 μg/m³',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // 행동 결론 hero text
              Text(
                result?.heroText ?? '데이터를 불러오는 중이에요',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),

              // 마스크 타입 pill
              if (result?.maskRequired == true &&
                  result?.maskType != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _WhitePill(
                      icon: Icons.masks_outlined,
                      text: '마스크 착용 권고',
                    ),
                    const SizedBox(width: 8),
                    _WhitePill(
                      text: result!.maskType!,
                      highlight: true,
                      bgColor: colors[0],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // 구분선
              Divider(
                  color: Colors.white.withValues(alpha: 0.25), height: 1),
              const SizedBox(height: 12),

              // 개인 기준 근거
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pm25Val != null) ...[
                          Text(
                            pm25Val >= widget.tFinal
                                ? '내 기준(${widget.tFinal.toStringAsFixed(1)}μg) 초과 중'
                                : '내 기준(${widget.tFinal.toStringAsFixed(1)}μg)은 아직 안전',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (result?.personalNote != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            result!.personalNote!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 상세 보기 힌트
                  Row(
                    children: [
                      Text(
                        '상세',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 12,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final bool highlight;
  final Color? bgColor;

  const _WhitePill({
    this.icon,
    required this.text,
    this.highlight = false,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                color: highlight ? (bgColor ?? AppColors.coral) : Colors.white,
                size: 15),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: highlight ? (bgColor ?? AppColors.coral) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 오늘 상황 퀵 토글 ─────────────────────────────────────────

class _TodayQuickToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySituations = ref.watch(todaySituationProvider);
    final activeTypes =
        todaySituations.where((s) => s.isActive).map((s) => s.type).toSet();

    return Row(
      children: TodaySituationType.values.map((type) {
        final isActive = activeTypes.contains(type);
        final icon  = type == TodaySituationType.outdoorExercise ? '🏃' : '🤒';
        final label = type == TodaySituationType.outdoorExercise
            ? '야외 운동'
            : '몸 상태 안 좋음';

        return Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(todaySituationProvider.notifier).toggle(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: type == TodaySituationType.outdoorExercise ? 6 : 0,
                left:  type == TodaySituationType.outdoorExercise ? 0 : 6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.40)
                      : AppColors.divider,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 기타 오염물질 (O3 · NO2) ──────────────────────────────────

class _ExtraPollutantsRow extends StatelessWidget {
  final DustData dust;
  const _ExtraPollutantsRow({required this.dust});

  @override
  Widget build(BuildContext context) {
    final o3  = dust.o3Value;
    final no2 = dust.no2Value;
    if (o3 == null && no2 == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          if (o3 != null)
            Expanded(
              child: _PollutantChip(
                label: '오존(O₃)',
                value: '${o3.toStringAsFixed(3)} ppm',
                grade: dust.o3Grade,
              ),
            ),
          if (o3 != null && no2 != null)
            Container(
                width: 1,
                height: 32,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 12)),
          if (no2 != null)
            Expanded(
              child: _PollutantChip(
                label: '이산화질소(NO₂)',
                value: '${no2.toStringAsFixed(3)} ppm',
                grade: dust.no2Grade,
              ),
            ),
        ],
      ),
    );
  }
}

class _PollutantChip extends StatelessWidget {
  final String label;
  final String value;
  final String grade;
  const _PollutantChip(
      {required this.label, required this.value, required this.grade});

  Color get _gradeColor {
    switch (grade) {
      case '좋음':    return AppColors.dustGood;
      case '보통':    return AppColors.dustNormal;
      case '나쁨':    return AppColors.dustBad;
      case '매우나쁨': return AppColors.dustVeryBad;
      default:       return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _gradeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                grade == '알수없음' ? '-' : grade,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _gradeColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 시간별 현황 섹션 ──────────────────────────────────────────

class _HourlySection extends StatelessWidget {
  final String stationName;
  final WidgetRef ref;
  final BuildContext context;

  const _HourlySection({
    required this.stationName,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
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
                const Text(
                  '시간별 현황',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Text('자세히 보기',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.primary)),
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
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
              error: (_, __) => _InlineError(
                message: '시간별 현황을 불러올 수 없어요.',
                onRetry: () =>
                    ref.invalidate(hourlyDataProvider(stationName)),
              ),
              data: (List<HourlyDustData> items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('시간별 데이터가 없어요.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  );
                }
                return _HourlyList(items: items.take(12).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HourlyList extends StatelessWidget {
  final List<HourlyDustData> items;
  const _HourlyList({required this.items});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

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
          final timeLabel = isNow
              ? '지금'
              : isMidnight
                  ? '${item.time.month}/${item.time.day}'
                      '(${weekdays[item.time.weekday - 1]})'
                  : '${item.time.hour}시';

          return Opacity(
            opacity: item.isForecast ? 0.55 : 1.0,
            child: Container(
              width: 58,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isNow
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isNow
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30))
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
                          fontWeight: isNow
                              ? FontWeight.bold
                              : FontWeight.normal,
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

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _InlineError({required this.message, this.onRetry});

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('재시도',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

// ── 위치 미설정 ───────────────────────────────────────────────

class _NoStationView extends StatelessWidget {
  final VoidCallback onSetup;
  const _NoStationView({required this.onSetup});

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

