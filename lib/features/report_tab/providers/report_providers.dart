import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/dust_calculator.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/dust_providers.dart';
import '../../../providers/location_providers.dart';
import '../../../providers/profile_providers.dart';
import '../models/report_models.dart';

// ── weekReportProvider ────────────────────────────────────────

/// 주간 리포트 메인 데이터.
///
/// - dustDataProvider 직접 watch → currentFinalRatio 계산 (statusCardProvider 의존 X)
/// - station null/empty → WeekReportData.empty() fallback
/// - 데이터 있는 날짜 수 < 3 → WeekReportState.empty
/// - dangerHours = Set<String> 고유 시간대 (yyyy-MM-dd HH 키, ratio ≥ 1.0)
final weekReportProvider = FutureProvider.autoDispose<WeekReportData>((ref) async {
  final db       = ref.watch(localDatabaseProvider);
  final profile  = ref.watch(profileProvider);
  final prefs    = ref.watch(sharedPreferencesProvider);
  final station  = ref.watch(locationStateProvider).station;
  final dustAsync = ref.watch(dustDataProvider);

  // station null/empty fallback
  if (station == null || station.isEmpty) {
    return WeekReportData.empty();
  }

  // currentFinalRatio — dustDataProvider에서 직접 계산
  double currentFinalRatio = 0.0;
  dustAsync.whenData((dust) {
    if (dust != null) {
      currentFinalRatio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: profile.tFinal,
        pm25: dust.pm25Value,
        pm10: dust.pm10Value,
      );
    }
  });

  const days = 7;

  // firstActiveDate
  final firstActiveDateStr = prefs.getString(AppConstants.prefFirstActiveDate);
  final firstActiveDate = firstActiveDateStr != null
      ? DateTime.tryParse(firstActiveDateStr)
      : null;

  final now = DateTime.now();

  // 시간별 AQI 레코드 + 최고 PM2.5 레코드
  final hourlyRows = await db.getHourlyAqiRecords(
    stationName: station,
    days: days,
  );
  final maxPm25Record = await db.getMaxPm25Record(
    stationName: station,
    days: days,
  );

  // ── 날짜별 최고 ratio 집계 ────────────────────────────────
  final Map<String, double> dayPeakRatio = {};  // 'YYYY-MM-DD' → peak ratio
  final Set<String> dangerHourSet = {};          // 'YYYY-MM-DD HH' 고유 키

  for (final row in hourlyRows) {
    final dayStr  = row['day'] as String? ?? '';
    final hour    = row['hour'] as int? ?? 0;
    final pm25    = (row['pm25_value'] as int?);
    final pm10    = (row['pm10_value'] as int?);
    final dt      = DateTime.tryParse(row['data_time'] as String? ?? '');

    if (dayStr.isEmpty || pm25 == null || dt == null) continue;

    // firstActiveDate 이전 제외
    if (firstActiveDate != null) {
      final dateOnly   = DateTime(dt.year, dt.month, dt.day);
      final activeOnly = DateTime(
          firstActiveDate.year, firstActiveDate.month, firstActiveDate.day);
      if (dateOnly.isBefore(activeOnly)) continue;
    }

    final ratio = DustCalculator.computeHistoricalFinalRatio(
      tFinalPm25: profile.tFinal,
      pm25: pm25,
      pm10: pm10,
    );

    // 일별 max ratio
    final prev = dayPeakRatio[dayStr] ?? 0.0;
    if (ratio > prev) dayPeakRatio[dayStr] = ratio;

    // dangerHours
    if (ratio >= 1.0) {
      final hourKey =
          '$dayStr ${hour.toString().padLeft(2, '0')}';
      dangerHourSet.add(hourKey);
    }
  }

  // ── 7일 캘린더 (월~일 순서) ──────────────────────────────
  const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  final today   = DateTime(now.year, now.month, now.day);
  final mondayOffset = today.weekday - 1;  // weekday: 1=월~7=일
  final monday  = today.subtract(Duration(days: mondayOffset));

  final calDays = List.generate(7, (i) {
    final date    = monday.add(Duration(days: i));
    final dayStr  = _dayKey(date);
    final peak    = dayPeakRatio[dayStr];

    // firstActiveDate 이전은 hasData=false
    bool hasData = peak != null;
    if (firstActiveDate != null) {
      final activeOnly = DateTime(
          firstActiveDate.year, firstActiveDate.month, firstActiveDate.day);
      if (date.isBefore(activeOnly)) hasData = false;
    }

    return DayCalendarData(
      date: date,
      weekdayLabel: weekdayLabels[i],
      peakRatio: hasData ? peak : null,
      hasData: hasData,
    );
  });

  // ── 데이터 충분성 판단 ────────────────────────────────────
  final daysWithData = calDays.where((d) => d.hasData).length;
  if (daysWithData < 3) {
    final sunday = monday.add(const Duration(days: 6));
    return WeekReportData(
      weekCaption: _buildWeekCaption(monday, sunday),
      state: WeekReportState.empty,
      dangerHours: 0,
      days: calDays,
      pattern: null,
      updatedTimeLabel: _buildTimeLabel(now),
      currentFinalRatio: currentFinalRatio,
    );
  }

  // ── 상태 결정 ─────────────────────────────────────────────
  final dangerHours = dangerHourSet.length;
  final state = dangerHours > 0 ? WeekReportState.normal : WeekReportState.safe;

  // ── PatternData ───────────────────────────────────────────
  PatternData? pattern;
  if (state == WeekReportState.normal) {
    // 위험 레코드 수 최다 요일+시간대 찾기
    final Map<int, int> weekdayDangerCount = {};  // 0=월~6=일
    final Map<int, int> hourDangerCount    = {};  // 0~23

    for (final row in hourlyRows) {
      final pm25  = (row['pm25_value'] as int?);
      final pm10  = (row['pm10_value'] as int?);
      final dt    = DateTime.tryParse(row['data_time'] as String? ?? '');
      if (pm25 == null || dt == null) continue;

      if (firstActiveDate != null) {
        final dateOnly   = DateTime(dt.year, dt.month, dt.day);
        final activeOnly = DateTime(
            firstActiveDate.year, firstActiveDate.month, firstActiveDate.day);
        if (dateOnly.isBefore(activeOnly)) continue;
      }

      final ratio = DustCalculator.computeHistoricalFinalRatio(
        tFinalPm25: profile.tFinal,
        pm25: pm25,
        pm10: pm10,
      );
      if (ratio >= 1.0) {
        // weekday: 1=월~7=일 → 0~6
        final wIdx = (dt.weekday - 1).clamp(0, 6);
        weekdayDangerCount[wIdx] = (weekdayDangerCount[wIdx] ?? 0) + 1;
        hourDangerCount[dt.hour] = (hourDangerCount[dt.hour] ?? 0) + 1;
      }
    }

    if (weekdayDangerCount.isNotEmpty) {
      // 위험 요일 Top2 → 발견 문장
      final sortedWeekdays = weekdayDangerCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topWday1 = weekdayLabels[sortedWeekdays[0].key];
      final topWday2 = sortedWeekdays.length > 1
          ? weekdayLabels[sortedWeekdays[1].key]
          : null;

      // 위험 시간대 — 오전/오후 분류
      final dangerHoursInRange = hourDangerCount.keys.toList()..sort();
      final isPm = dangerHoursInRange.isNotEmpty &&
          dangerHoursInRange.any((h) => h >= 12);
      final timeStr = isPm ? '오후' : '오전';

      final discoveryText = topWday2 != null
          ? '$topWday1·$topWday2 $timeStr가 더 위험했어요'
          : '$topWday1 $timeStr가 더 위험했어요';

      // noteText — 최고 PM2.5 레코드
      String noteText = '';
      if (maxPm25Record != null) {
        final dt      = maxPm25Record.dataTime;
        final mmdd    = '${dt.month}/${dt.day}';
        final h       = dt.hour;
        final pm25val = maxPm25Record.pm25Value ?? 0;
        noteText = '$mmdd $h시 PM2.5 $pm25val㎍';
      }

      pattern = PatternData(
        discoveryText: discoveryText,
        noteText: noteText,
      );
    }
  } else if (state == WeekReportState.safe) {
    // safe 상태에서도 PatternData 생성 (주말 피크 등)
    // PM2.5가 임계치의 40% 미만이면 "살짝 올라왔어요"가 어색하므로 패턴 생성 X
    if (maxPm25Record != null && maxPm25Record.pm25Value != null) {
      final pm25val = maxPm25Record.pm25Value!;
      final threshold = (profile.tFinal * 0.4).round();
      if (pm25val >= threshold) {
        final dt      = maxPm25Record.dataTime;
        final mmdd    = '${dt.month}/${dt.day}';
        final h       = dt.hour;
        final wIdx    = (dt.weekday - 1).clamp(0, 6);
        final wLabel  = weekdayLabels[wIdx];
        final timeStr = h >= 12 ? '오후' : '오전';

        pattern = PatternData(
          discoveryText: '$wLabel $timeStr가 한 번 살짝 올라왔어요',
          noteText: '$mmdd $h시 PM2.5 $pm25val㎍ · 내 기준 아래',
        );
      }
    }
  }

  // ── weekCaption ───────────────────────────────────────────
  final sunday = monday.add(const Duration(days: 6));
  final weekCaption = _buildWeekCaption(monday, sunday);

  // ── updatedTimeLabel ──────────────────────────────────────
  final updatedTimeLabel = _buildTimeLabel(now);

  return WeekReportData(
    weekCaption: weekCaption,
    state: state,
    dangerHours: dangerHours,
    days: calDays,
    pattern: pattern,
    updatedTimeLabel: updatedTimeLabel,
    currentFinalRatio: currentFinalRatio,
  );
});

// ── drillReportProvider ───────────────────────────────────────

/// Drill-down 화면 데이터 (히트맵 + 일별 상세).
final drillReportProvider = FutureProvider.autoDispose<DrillReportData>((ref) async {
  final db      = ref.watch(localDatabaseProvider);
  final profile = ref.watch(profileProvider);
  final station = ref.watch(locationStateProvider).station;
  final prefs   = ref.watch(sharedPreferencesProvider);

  const days = 7;
  const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  // station null/empty fallback
  if (station == null || station.isEmpty) {
    final emptyGrid = List.generate(7, (_) => List<double?>.filled(24, null));
    return DrillReportData(
      heatmap: DrillHeatmapData(
        grid: emptyGrid,
        weekdayLabels: weekdayLabels,
      ),
      dayRows: [],
      weekCaption: '',
    );
  }

  final firstActiveDateStr = prefs.getString(AppConstants.prefFirstActiveDate);
  final firstActiveDate = firstActiveDateStr != null
      ? DateTime.tryParse(firstActiveDateStr)
      : null;

  final now = DateTime.now();

  final hourlyRows = await db.getHourlyAqiRecords(stationName: station, days: days);
  final avgRows    = await db.getWeekdayHourAverages(stationName: station, days: days);

  // ── 히트맵 7×24 빌드 ──────────────────────────────────────
  // avgRows: weekday_num(0=일~6=토) → Dart 월~일 재정렬
  // SQLite %w: 0=일, 1=월,...,6=토 → index 변환: 일(0)→6, 월(1)→0,...
  final grid = List.generate(7, (_) => List<double?>.filled(24, null));

  for (final row in avgRows) {
    final sqliteWeekday = row['weekday_num'] as int? ?? 0;
    final hourNum       = row['hour_num'] as int? ?? 0;
    final pm25avg       = (row['pm25_avg'] as num?)?.toDouble();
    final pm10avg       = (row['pm10_avg'] as num?)?.toDouble();

    if (pm25avg == null) continue;

    // SQLite 0(일)~6(토) → 월(0)~일(6) 변환
    final dartIdx = sqliteWeekday == 0 ? 6 : sqliteWeekday - 1;

    final ratio = DustCalculator.computeHistoricalFinalRatio(
      tFinalPm25: profile.tFinal,
      pm25: pm25avg.round(),
      pm10: pm10avg?.round(),
    );

    if (hourNum >= 0 && hourNum < 24 && dartIdx >= 0 && dartIdx < 7) {
      grid[dartIdx][hourNum] = ratio;
    }
  }

  // ── 일별 상세 rows ─────────────────────────────────────────
  // hourlyRows에서 날짜별 집계
  final Map<String, _DayAgg> dayAggMap = {};

  for (final row in hourlyRows) {
    final dayStr  = row['day'] as String? ?? '';
    final pm25    = (row['pm25_value'] as int?);
    final pm10    = (row['pm10_value'] as int?);
    final dtStr   = row['data_time'] as String? ?? '';
    final dt      = DateTime.tryParse(dtStr);

    if (dayStr.isEmpty || pm25 == null || dt == null) continue;

    if (firstActiveDate != null) {
      final dateOnly   = DateTime(dt.year, dt.month, dt.day);
      final activeOnly = DateTime(
          firstActiveDate.year, firstActiveDate.month, firstActiveDate.day);
      if (dateOnly.isBefore(activeOnly)) continue;
    }

    final ratio = DustCalculator.computeHistoricalFinalRatio(
      tFinalPm25: profile.tFinal,
      pm25: pm25,
      pm10: pm10,
    );

    final agg = dayAggMap.putIfAbsent(dayStr, () => _DayAgg(dayStr));
    agg.update(ratio, pm25, dt.hour);
  }

  // 월~일 순서로 정렬된 일별 rows
  final sortedKeys = dayAggMap.keys.toList()..sort();
  final dayRows = <DrillDayRow>[];

  for (final key in sortedKeys) {
    final agg = dayAggMap[key]!;
    final dt  = DateTime.tryParse(key);
    if (dt == null) continue;

    final wIdx    = (dt.weekday - 1).clamp(0, 6);
    final wLabel  = weekdayLabels[wIdx];
    final dateLabel = '$wLabel · ${dt.month}/${dt.day}';

    String hoursRange = '—';
    if (agg.dangerHours.isNotEmpty) {
      final sorted  = agg.dangerHours.toList()..sort();
      final minH    = sorted.first;
      final maxH    = sorted.last;
      hoursRange = minH == maxH ? '$minH시' : '$minH~$maxH시';
    }

    dayRows.add(DrillDayRow(
      dateLabel: dateLabel,
      hoursRange: hoursRange,
      peakPm25: agg.peakPm25,
      peakRatio: agg.peakRatio,
      dangerRecordCount: agg.dangerHours.length,
    ));
  }

  // ── weekCaption ───────────────────────────────────────────
  final today  = DateTime(now.year, now.month, now.day);
  final mondayOffset = today.weekday - 1;
  final monday = today.subtract(Duration(days: mondayOffset));
  final sunday = monday.add(const Duration(days: 6));
  final weekCaption = _buildWeekCaption(monday, sunday);

  return DrillReportData(
    heatmap: DrillHeatmapData(grid: grid, weekdayLabels: weekdayLabels),
    dayRows: dayRows,
    weekCaption: weekCaption,
  );
});

// ── 헬퍼 ─────────────────────────────────────────────────────

String _dayKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

String _buildWeekCaption(DateTime monday, DateTime sunday) {
  final weekNum = ((monday.day - 1) ~/ 7) + 1;
  final mm = monday.month;
  final sd = sunday.month;
  return '$mm월 $weekNum주차 · $mm/${monday.day} ~ $sd/${sunday.day}';
}

String _buildTimeLabel(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m 갱신';
}

/// 일별 집계 내부 클래스
class _DayAgg {
  final String dayKey;
  double peakRatio = 0.0;
  int? peakPm25;
  final Set<int> dangerHours = {};

  _DayAgg(this.dayKey);

  void update(double ratio, int pm25, int hour) {
    if (ratio > peakRatio) {
      peakRatio = ratio;
      peakPm25  = pm25;
    }
    if (ratio >= 1.0) {
      dangerHours.add(hour);
    }
  }
}
