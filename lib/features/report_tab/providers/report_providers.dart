import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dust_calculator.dart';
import '../../../data/models/notification_log.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/location_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/report_models.dart';
import '../utils/insight_engine.dart';

// ── 요약 카드 데이터 ──────────────────────────────────────
//
// final_ratio 기반으로 dominantGrade를 결정 (§4.5).

final reportSummaryProvider = FutureProvider<ReportSummaryData>((ref) async {
  final db      = ref.watch(localDatabaseProvider);
  final station = ref.watch(locationStateProvider).station ?? '';
  final profile = ref.watch(profileProvider);

  const days = 7;

  final [dailies, grouped] = await Future.wait([
    db.getDailyAqiAverages(stationName: station, days: days),
    db.getLogsGroupedByDate(days: days),
  ]);

  final dailyRows = dailies as List<Map<String, dynamic>>;
  final logMap    = grouped as Map<String, List<NotificationLog>>;

  int dangerDays   = 0;
  int maskWornDays = 0;
  double ratioSum  = 0.0;
  int    ratioCnt  = 0;

  for (int i = 0; i < days; i++) {
    final date = DateTime.now().subtract(Duration(days: days - 1 - i));
    final key  = _dayKey(date);
    final row  = dailyRows.firstWhere(
      (r) => r['day'] == key,
      orElse: () => {},
    );

    if (row.isNotEmpty) {
      final pm25 = (row['pm25_avg'] as num?)?.round();
      final pm10 = (row['pm10_avg'] as num?)?.round();
      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: profile.tFinal,
        pm25: pm25,
        pm10: pm10,
      );
      ratioSum += ratio;
      ratioCnt++;
      if (ratio >= 1.0) dangerDays++;
    }

    final dayLogs = logMap[key] ?? [];
    if (dayLogs.any((l) => l.userAction == UserAction.maskWorn)) maskWornDays++;
  }

  // 7일 평균 final_ratio 기반 dominantGrade (§4.5)
  final avgRatio = ratioCnt > 0 ? ratioSum / ratioCnt : 0.0;
  final dominantGrade = _gradeFromAvgRatio(avgRatio);

  return ReportSummaryData(
    totalDays: days,
    dangerDays: dangerDays,
    maskWornDays: maskWornDays,
    defenseRate: 0.0, // deprecated — UI에서 미사용
    dominantGrade: dominantGrade,
  );
});

/// 7일 평균 final_ratio → dominantGrade 매핑 (§4.5)
String _gradeFromAvgRatio(double avgRatio) {
  if (avgRatio < 0.5) return '좋음';
  if (avgRatio < 1.0) return '보통';
  if (avgRatio < 1.5) return '나쁨';
  return '매우나쁨';
}

String _dayKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

// ── 단계 1 신규 Provider ──────────────────────────────────

/// 주간 인사이트 카드 데이터.
///
/// 14일 AQI + 7일 알림 컨텍스트를 동시 로드 후 InsightEngine.compute() 호출.
/// null 이면 InsightCard 슬롯 숨김.
final insightProvider = FutureProvider<InsightData?>((ref) async {
  final db      = ref.watch(localDatabaseProvider);
  final station = ref.watch(locationStateProvider).station;
  final profile = ref.watch(profileProvider);

  if (station == null || station.isEmpty) return null;

  final now   = DateTime.now();
  final start = now.subtract(const Duration(days: 6));
  final end   = now;

  final results = await Future.wait([
    db.getDailyAqiAverages(stationName: station, days: 7),
    db.getNotificationsWithAqiContext(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
      stationName: station,
    ),
  ]);

  final weeklyAqi    = results[0] as List<Map<String, dynamic>>;
  final weeklyNotifs = results[1] as List<NotificationWithAqiContext>;

  return InsightEngine.compute(
    weeklyNotifs: weeklyNotifs,
    weeklyAqi: weeklyAqi,
    tFinalPm25: profile.tFinal,
    now: now,
  );
});

/// WeeklyOverviewCard용 7일 원(Circle) 데이터 목록.
///
/// 7개 DayCircleData 반환 (오늘 포함, 누락일 finalRatio=null).
final weeklyOverviewProvider = FutureProvider<List<DayCircleData>>((ref) async {
  final db      = ref.watch(localDatabaseProvider);
  final station = ref.watch(locationStateProvider).station;
  final profile = ref.watch(profileProvider);

  final now = DateTime.now();

  final results = await Future.wait([
    db.getDailyAqiAverages(stationName: station ?? '', days: 7),
    db.getLogsGroupedByDate(days: 7),
  ]);

  final dailyRows = results[0] as List<Map<String, dynamic>>;
  final logMap    = results[1] as Map<String, List<NotificationLog>>;
  final tFinalPm25 = profile.tFinal;

  final aqiByDay = {for (final r in dailyRows) r['day'] as String: r};

  return List.generate(7, (i) {
    final date = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 6 - i));
    final key  = _dayKey(date);
    final row  = aqiByDay[key];

    final double? finalRatio;
    if (row == null) {
      finalRatio = null;
    } else {
      final pm25 = (row['pm25_avg'] as num?)?.round();
      final pm10 = (row['pm10_avg'] as num?)?.round();
      finalRatio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: tFinalPm25,
        pm25: pm25,
        pm10: pm10,
      );
    }

    final dayLogs = logMap[key] ?? [];
    final maskWorn = dayLogs.any((l) => l.userAction == UserAction.maskWorn);
    final isToday  = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    return DayCircleData(
      date: date,
      finalRatio: finalRatio,
      maskWorn: maskWorn,
      isToday: isToday,
    );
  });
});

/// 추세 한 줄 데이터.
///
/// 지난주(7~14일 전) AQI 기록이 1일 미만이면 null → TrendLine 슬롯 숨김.
final trendProvider = FutureProvider<TrendData?>((ref) async {
  final db      = ref.watch(localDatabaseProvider);
  final station = ref.watch(locationStateProvider).station;
  final profile = ref.watch(profileProvider);

  if (station == null || station.isEmpty) return null;

  final rows = await db.getDailyAqiAverages(
    stationName: station,
    days: 14,
  );

  return InsightEngine.computeTrend(
    last14DaysAqi: rows,
    tFinalPm25: profile.tFinal,
    now: DateTime.now(),
  );
});
