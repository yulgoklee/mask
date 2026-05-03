import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dust_calculator.dart';
import '../../../data/models/notification_log.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/location_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/report_models.dart';
import '../utils/insight_engine.dart';

// ── 기간 선택 상태 ────────────────────────────────────────

final selectedPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.sevenDays;
});

// ── 일별 바 차트 데이터 ───────────────────────────────────

final dailyBarProvider = FutureProvider.family<List<DailyBarData>, ReportPeriod>(
  (ref, period) async {
    final db = ref.watch(localDatabaseProvider);
    final station = ref.watch(locationStateProvider).station ?? '';

    final [dailies, grouped] = await Future.wait([
      db.getDailyAqiAverages(stationName: station, days: period.days),
      db.getLogsGroupedByDate(days: period.days),
    ]);

    final dailyRows = dailies as List<Map<String, dynamic>>;
    final logMap    = grouped as Map<String, List<NotificationLog>>;

    final byDay = {for (final r in dailyRows) r['day'] as String: r};

    return List.generate(period.days, (i) {
      final date = DateTime.now().subtract(Duration(days: period.days - 1 - i));
      final key  = _dayKey(date);
      final row  = byDay[key];
      final avg  = (row?['pm25_avg'] as num?)?.toDouble() ?? 0.0;
      final dayLogs = logMap[key] ?? [];

      return DailyBarData(
        date: date,
        pm25Avg: avg,
        grade: gradeFromPm25(avg),
        maskWorn: dayLogs.any((l) => l.userAction == UserAction.maskWorn),
      );
    });
  },
);

// ── 요약 카드 데이터 ──────────────────────────────────────

final reportSummaryProvider = FutureProvider.family<ReportSummaryData, ReportPeriod>(
  (ref, period) async {
    final db      = ref.watch(localDatabaseProvider);
    final station = ref.watch(locationStateProvider).station ?? '';

    final [dailies, grouped, statsResult] = await Future.wait([
      db.getDailyAqiAverages(stationName: station, days: period.days),
      db.getLogsGroupedByDate(days: period.days),
      db.getNotifActionStats(days: period.days),
    ]);

    final dailyRows = dailies as List<Map<String, dynamic>>;
    final logMap    = grouped as Map<String, List<NotificationLog>>;
    final stats     = statsResult as ({int total, int defended, int estimated});

    int dangerDays    = 0;
    int maskWornDays  = 0;
    final grades      = <String>[];

    for (int i = 0; i < period.days; i++) {
      final date = DateTime.now().subtract(Duration(days: period.days - 1 - i));
      final key  = _dayKey(date);
      final row  = dailyRows.firstWhere(
        (r) => r['day'] == key,
        orElse: () => {},
      );
      final avg  = (row['pm25_avg'] as num?)?.toDouble() ?? 0.0;
      final grade = gradeFromPm25(avg);
      grades.add(grade);
      if (grade == '나쁨' || grade == '매우나쁨') dangerDays++;

      final dayLogs = logMap[key] ?? [];
      if (dayLogs.any((l) => l.userAction == UserAction.maskWorn)) maskWornDays++;
    }

    final total    = stats.total;
    final defended = stats.defended;
    final rate     = total > 0 ? (defended / total * 100) : 0.0;

    final gradeCount = <String, int>{};
    for (final g in grades) gradeCount[g] = (gradeCount[g] ?? 0) + 1;
    final dominant = gradeCount.isEmpty
        ? '좋음'
        : gradeCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return ReportSummaryData(
      totalDays: period.days,
      dangerDays: dangerDays,
      maskWornDays: maskWornDays,
      defenseRate: rate.toDouble(),
      dominantGrade: dominant,
    );
  },
);

// ── 캘린더 데이터 ─────────────────────────────────────────

final calendarProvider = FutureProvider.family<List<CalendarDayData>, ReportPeriod>(
  (ref, period) async {
    final db     = ref.watch(localDatabaseProvider);
    final grouped = await db.getLogsGroupedByDate(days: 7);
    final today  = DateTime.now();

    return List.generate(7, (i) {
      final date    = today.subtract(Duration(days: 6 - i));
      final key     = _dayKey(date);
      final dayLogs = grouped[key] ?? [];
      final hasMask = dayLogs.any((l) => l.userAction == UserAction.maskWorn);

      return CalendarDayData(
        date: date,
        status: dayLogs.isEmpty
            ? CalendarDayStatus.noData
            : hasMask
                ? CalendarDayStatus.worn
                : CalendarDayStatus.notWorn,
        isToday: date.year == today.year &&
            date.month == today.month &&
            date.day == today.day,
        isInSelectedPeriod: i >= (7 - period.days),
      );
    });
  },
);

// ── 하이라이트 카드 데이터 ────────────────────────────────

final highlightProvider = FutureProvider.family<HighlightData, ReportPeriod>(
  (ref, period) async {
    final db      = ref.watch(localDatabaseProvider);
    final station = ref.watch(locationStateProvider).station ?? '';

    final worst = await db.getMaxPm25Record(
      stationName: station,
      days: period.days,
    );
    if (worst == null) return HighlightData.empty();

    final grouped = await db.getLogsGroupedByDate(days: period.days);
    final key     = _dayKey(worst.dataTime);
    final dayLogs = grouped[key] ?? [];
    final maskWorn = dayLogs.any((l) => l.userAction == UserAction.maskWorn);

    final records = await db.getRecentAqiRecords(
      stationName: station,
      hours: period.days * 24,
    );
    final allSafe = records.every((r) => (r.pm25Value ?? 0) <= 15);

    return HighlightData(
      date: worst.dataTime,
      pm25Max: worst.pm25Value?.toDouble() ?? 0,
      grade: worst.pm25Grade ?? '보통',
      maskWorn: maskWorn,
      isAllSafe: allSafe,
    );
  },
);

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

  final weeklyAqi   = results[0] as List<Map<String, dynamic>>;
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
