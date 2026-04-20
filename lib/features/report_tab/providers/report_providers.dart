import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_log.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/location_providers.dart';
import '../models/report_models.dart';

// ── 기간 선택 상태 ────────────────────────────────────────

final selectedPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.sevenDays;
});

// ── 일별 바 차트 데이터 ───────────────────────────────────

final dailyBarProvider = FutureProvider.family<List<DailyBarData>, ReportPeriod>(
  (ref, period) async {
    final db = ref.watch(localDatabaseProvider);
    final station = ref.watch(locationStateProvider).station ?? '';

    final records = await db.getRecentAqiRecords(
      stationName: station,
      hours: period.days * 24,
    );
    final byDay = <String, List<double>>{};
    final maskByDay = <String, bool>{};

    for (final r in records) {
      final key = _dayKey(r.dataTime);
      byDay.putIfAbsent(key, () => []);
      if (r.pm25Value != null) byDay[key]!.add(r.pm25Value!.toDouble());
    }

    final logs = await Future.wait(
      List.generate(period.days, (i) {
        final date = DateTime.now().subtract(Duration(days: period.days - 1 - i));
        return db.getLogsForDate(date);
      }),
    );

    for (int i = 0; i < period.days; i++) {
      final date = DateTime.now().subtract(Duration(days: period.days - 1 - i));
      final key = _dayKey(date);
      final dayLogs = logs[i];
      maskByDay[key] = dayLogs.any((l) => l.userAction == UserAction.maskWorn);
    }

    final result = <DailyBarData>[];
    for (int i = 0; i < period.days; i++) {
      final date = DateTime.now().subtract(Duration(days: period.days - 1 - i));
      final key = _dayKey(date);
      final vals = byDay[key] ?? [];
      final avg = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      result.add(DailyBarData(
        date: date,
        pm25Avg: avg,
        grade: gradeFromPm25(avg),
        maskWorn: maskByDay[key] ?? false,
      ));
    }
    return result;
  },
);

// ── 요약 카드 데이터 ──────────────────────────────────────

final reportSummaryProvider = FutureProvider.family<ReportSummaryData, ReportPeriod>(
  (ref, period) async {
    final db = ref.watch(localDatabaseProvider);
    final station = ref.watch(locationStateProvider).station ?? '';
    final records = await db.getRecentAqiRecords(stationName: station, hours: period.days * 24);
    final stats = await db.getNotifActionStats(days: period.days);

    final byDay = <String, String>{};
    for (final r in records) {
      final key = _dayKey(r.dataTime);
      byDay[key] = r.pm25Grade ?? '좋음';
    }

    int dangerDays = 0;
    int maskWornDays = 0;
    final grades = <String>[];

    for (int i = 0; i < period.days; i++) {
      final date = DateTime.now().subtract(Duration(days: period.days - 1 - i));
      final key = _dayKey(date);
      final grade = byDay[key] ?? '좋음';
      grades.add(grade);
      if (grade == '나쁨' || grade == '매우나쁨') dangerDays++;

      final dayLogs = await db.getLogsForDate(date);
      if (dayLogs.any((l) => l.userAction == UserAction.maskWorn)) maskWornDays++;
    }

    final total = stats.total;
    final defended = stats.defended;
    final rate = total > 0 ? (defended / total * 100) : 0.0;

    final gradeCount = <String, int>{};
    for (final g in grades) gradeCount[g] = (gradeCount[g] ?? 0) + 1;
    final dominant = gradeCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

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
    final db = ref.watch(localDatabaseProvider);
    final logs = await Future.wait(
      List.generate(7, (i) => db.getLogsForDate(
        DateTime.now().subtract(Duration(days: 6 - i)),
      )),
    );

    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dayLogs = logs[i];
      final hasMaskWorn = dayLogs.any((l) => l.userAction == UserAction.maskWorn);
      final hasAnyLog = dayLogs.isNotEmpty;
      final today = DateTime.now();

      return CalendarDayData(
        date: date,
        status: !hasAnyLog
            ? CalendarDayStatus.noData
            : hasMaskWorn
                ? CalendarDayStatus.worn
                : CalendarDayStatus.notWorn,
        isToday: date.year == today.year && date.month == today.month && date.day == today.day,
        isInSelectedPeriod: i >= (7 - period.days),
      );
    });
  },
);

// ── 하이라이트 카드 데이터 ────────────────────────────────

final highlightProvider = FutureProvider.family<HighlightData, ReportPeriod>(
  (ref, period) async {
    final db = ref.watch(localDatabaseProvider);
    final station = ref.watch(locationStateProvider).station ?? '';
    final records = await db.getRecentAqiRecords(stationName: station, hours: period.days * 24);

    if (records.isEmpty) return HighlightData.empty();

    final allSafe = records.every((r) => (r.pm25Value ?? 0) <= 15);
    final worst = records.reduce((a, b) =>
        (a.pm25Value ?? 0) >= (b.pm25Value ?? 0) ? a : b);
    final dayLogs = await db.getLogsForDate(worst.dataTime);
    final maskWorn = dayLogs.any((l) => l.userAction == UserAction.maskWorn);

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
