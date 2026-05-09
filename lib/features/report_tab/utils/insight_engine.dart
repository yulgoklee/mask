import '../../../core/utils/dust_calculator.dart';
import '../../../data/models/notification_log.dart';
import '../models/report_models.dart';

/// 리포트 탭 인사이트 엔진
///
/// 매주 1개 인사이트를 생성한다.
/// 우선순위: actionMatch > envPeak > weekdayWeekend > avgSummary / allSafe > 데이터없음
class InsightEngine {
  InsightEngine._();

  // ── 공개 API ────────────────────────────────────────────

  /// 주간 인사이트 1개 생성.
  ///
  /// [weeklyNotifs]  최근 7일 알림 + AQI 컨텍스트 (getNotificationsWithAqiContext)
  /// [weeklyAqi]     최근 7일 일별 AQI 평균 (getDailyAqiAverages rows)
  /// [tFinalPm25]    현재 프로필의 개인 PM2.5 임계치
  /// [now]           기준 현재 시각 (테스트에서 고정 주입 가능)
  ///
  /// 데이터 없음 / 조건 미충족 시 null 반환 → 슬롯 숨김.
  static InsightData? compute({
    required List<NotificationWithAqiContext> weeklyNotifs,
    required List<Map<String, dynamic>> weeklyAqi,
    required double tFinalPm25,
    required DateTime now,
  }) {
    // ── 우선순위 1: 행동 매칭 ──────────────────────────────
    final maskedNotifs = weeklyNotifs
        .where((n) => n.notification.userAction == UserAction.maskWorn)
        .toList();

    if (maskedNotifs.isNotEmpty) {
      // ratio가 가장 높은 알림 선택
      NotificationWithAqiContext peak = maskedNotifs[0];
      double peakRatio = _ratioForNotif(peak, tFinalPm25);

      for (final n in maskedNotifs.skip(1)) {
        final r = _ratioForNotif(n, tFinalPm25);
        if (r > peakRatio) {
          peakRatio = r;
          peak = n;
        }
      }

      return _buildActionMatch(peak, tFinalPm25);
    }

    // ── 우선순위 2: 환경 피크 ─────────────────────────────
    if (weeklyAqi.isNotEmpty) {
      final peakRows = weeklyAqi.where((r) {
        final ratio = _ratioForAqiRow(r, tFinalPm25);
        return ratio >= 1.0;
      }).toList();

      if (peakRows.isNotEmpty) {
        // ratio 가장 높은 날 선택
        var peakRow = peakRows[0];
        double peakRatio = _ratioForAqiRow(peakRow, tFinalPm25);
        for (final r in peakRows.skip(1)) {
          final ratio = _ratioForAqiRow(r, tFinalPm25);
          if (ratio > peakRatio) {
            peakRatio = ratio;
            peakRow = r;
          }
        }
        return _buildEnvPeak(peakRow, weeklyNotifs, tFinalPm25);
      }

      // ── 우선순위 3: 주중-주말 차이 ───────────────────────
      final weekdayInsight =
          _tryWeekdayWeekend(weeklyAqi, tFinalPm25);
      if (weekdayInsight != null) return weekdayInsight;

      // ── 우선순위 4/5: 평균 요약 / 모두 안전 ──────────────
      // allSafe 체크를 avgSummary보다 먼저 수행 (§3.2 주의 사항)
      final allSafe = weeklyAqi.every((r) {
        return _ratioForAqiRow(r, tFinalPm25) < 1.0;
      });

      if (allSafe) {
        return _buildAllSafe();
      }
      return _buildAvgSummary(weeklyAqi, tFinalPm25);
    }

    // AQI 없음 + 알림 없음 = G-1 → null
    // AQI 없음 + 알림 있음 = G-3 처리 (notification 컬럼값 사용)
    if (weeklyNotifs.isNotEmpty) {
      // 알림은 있으나 AQI 기록이 없는 경우: notification 값으로 fallback
      // actionMatch가 아닌 경우 → envPeak 계열로 처리 (pm25Value 사용)
      final maskedInNotifs = weeklyNotifs
          .where((n) => n.notification.userAction == UserAction.maskWorn)
          .toList();
      if (maskedInNotifs.isNotEmpty) {
        NotificationWithAqiContext peak = maskedInNotifs[0];
        double peakRatio = _ratioForNotif(peak, tFinalPm25);
        for (final n in maskedInNotifs.skip(1)) {
          final r = _ratioForNotif(n, tFinalPm25);
          if (r > peakRatio) {
            peakRatio = r;
            peak = n;
          }
        }
        return _buildActionMatch(peak, tFinalPm25);
      }
      // 알림은 있으나 마스크 없음 + AQI 없음 → avgSummary 대신 null (데이터 부족)
      return null;
    }

    return null;
  }

  /// 추세 계산.
  ///
  /// [last14DaysAqi] getDailyAqiAverages(days: 14) 결과
  /// [tFinalPm25]    현재 프로필의 개인 PM2.5 임계치
  /// [now]           기준 현재 시각
  ///
  /// 지난주(7~14일 전) AQI 기록이 1일 미만이면 null 반환.
  static TrendData? computeTrend({
    required List<Map<String, dynamic>> last14DaysAqi,
    required double tFinalPm25,
    required DateTime now,
  }) {
    // 날짜 기준으로 이번주 / 지난주 분리
    // daysAgo: now와의 차이 (일 단위)
    final thisWeekRows = <Map<String, dynamic>>[];
    final lastWeekRows = <Map<String, dynamic>>[];

    for (final row in last14DaysAqi) {
      final day = row['day'] as String?;
      if (day == null) continue;
      final date = DateTime.tryParse(day);
      if (date == null) continue;
      final daysAgo = now.difference(date).inDays;
      if (daysAgo <= 7) {
        thisWeekRows.add(row);
      } else if (daysAgo <= 14) {
        lastWeekRows.add(row);
      }
    }

    // 지난주 데이터 1일 미만 → null
    if (lastWeekRows.isEmpty) return null;

    final thisWeekAvg = _avgRatio(thisWeekRows, tFinalPm25);
    final lastWeekAvg = _avgRatio(lastWeekRows, tFinalPm25);

    final delta = thisWeekAvg - lastWeekAvg;
    final category = _trendCategory(delta);

    return TrendData(category: category, delta: delta);
  }

  // ── 카피 빌더 ────────────────────────────────────────────

  static InsightData _buildActionMatch(
    NotificationWithAqiContext peak,
    double tFinalPm25,
  ) {
    final notif = peak.notification;
    final triggeredAt = notif.triggeredAt;

    // PM2.5 값: hasAqiContext면 AQI 컨텍스트, 없으면 notification.pm25Value
    final pm25 = peak.hasAqiContext
        ? (peak.aqiPm25 ?? notif.pm25Value ?? 0)
        : (notif.pm25Value ?? 0);
    final tFinalInt = tFinalPm25.round();

    final weekdayStr = _weekdayLabel(triggeredAt.weekday);
    final timeOfDayStr = _timeOfDayLabel(triggeredAt.hour);

    final body =
        '$weekdayStr $timeOfDayStr, PM2.5가 ${pm25}µg/m³까지 올랐어요.\n'
        '당신 기준(${tFinalInt}µg/m³)으로는 나쁨 수준이었는데,\n'
        '그 때 마스크를 챙기셨네요.';

    final footnote = _actionMatchFootnote(triggeredAt, pm25);

    return InsightData(
      category: InsightCategory.actionMatch,
      bodyText: body,
      footnoteText: footnote,
    );
  }

  static InsightData _buildEnvPeak(
    Map<String, dynamic> peakRow,
    List<NotificationWithAqiContext> weeklyNotifs,
    double tFinalPm25,
  ) {
    final dayStr = peakRow['day'] as String;
    final date = DateTime.parse(dayStr);
    final pm25 = (peakRow['pm25_avg'] as num?)?.round() ?? 0;
    final tFinalInt = tFinalPm25.round();
    final weekdayStr = _weekdayLabel(date.weekday);

    // 해당 날 마스크 착용 여부 확인
    final dayKey = dayStr;
    final maskWornOnDay = weeklyNotifs.any((n) {
      final nDay = _dayKey(n.notification.triggeredAt);
      return nDay == dayKey &&
          n.notification.userAction == UserAction.maskWorn;
    });

    final String body;
    if (maskWornOnDay) {
      body =
          '$weekdayStr에 공기가 가장 안 좋았어요.\n'
          'PM2.5 일평균 ${pm25}µg/m³으로,\n'
          '당신 기준(${tFinalInt}µg/m³)을 넘었어요. 그 날 마스크를 챙기셨네요.';
    } else {
      body =
          '$weekdayStr에 공기가 가장 안 좋았어요.\n'
          'PM2.5 일평균 ${pm25}µg/m³으로,\n'
          '당신 기준(${tFinalInt}µg/m³)을 넘었어요.';
    }

    final footnote = _dateFootnote(date, pm25);

    return InsightData(
      category: InsightCategory.envPeak,
      bodyText: body,
      footnoteText: footnote,
    );
  }

  static InsightData? _tryWeekdayWeekend(
    List<Map<String, dynamic>> weeklyAqi,
    double tFinalPm25,
  ) {
    final weekdayRows =
        weeklyAqi.where((r) => _weekdayFromRow(r) <= 5).toList();
    final weekendRows =
        weeklyAqi.where((r) => _weekdayFromRow(r) >= 6).toList();

    // 토~일 데이터 없으면 G-6: 후보 제외
    if (weekendRows.isEmpty) return null;

    final weekdayAvg = _avgRatio(weekdayRows, tFinalPm25);
    final weekendAvg = _avgRatio(weekendRows, tFinalPm25);

    if ((weekdayAvg - weekendAvg).abs() < 0.15) return null;

    final String body;
    if (weekdayAvg > weekendAvg) {
      body =
          '이번 주는 주말보다 평일 공기가 안 좋았어요.\n'
          '당신 기준으로 주중은 보통 이상, 주말은 괜찮은 수준이었어요.';
    } else {
      body = '이번 주는 평일보다 주말 공기가 더 안 좋았어요.';
    }

    return InsightData(
      category: InsightCategory.weekdayWeekend,
      bodyText: body,
    );
  }

  static InsightData _buildAvgSummary(
    List<Map<String, dynamic>> weeklyAqi,
    double tFinalPm25,
  ) {
    final avg = _avgRatio(weeklyAqi, tFinalPm25);

    final String body;
    if (avg < 0.7) {
      body = '이번 주 평균은 당신 기준으로 보통 수준이었어요.\n크게 나쁘지 않은 한 주였어요.';
    } else if (avg < 1.0) {
      body = '이번 주 평균은 당신 기준으로 조금 안 좋은 편이었어요.\n마스크를 챙기면 도움이 돼요.';
    } else {
      body = '이번 주 평균은 당신 기준으로 꽤 안 좋은 편이었어요.\n마스크를 꼭 챙기세요.';
    }

    return InsightData(
      category: InsightCategory.avgSummary,
      bodyText: body,
    );
  }

  static InsightData _buildAllSafe() {
    return const InsightData(
      category: InsightCategory.allSafe,
      bodyText: '이번 한 주는 내내 괜찮았어요.\n당신 기준으로도 무리 없이 지낼 수 있는 공기였어요.',
    );
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────

  /// 알림 컨텍스트 기반 final_ratio 계산
  /// hasAqiContext = true면 AQI 컨텍스트 사용, false면 notification 컬럼값 사용
  static double _ratioForNotif(
    NotificationWithAqiContext n,
    double tFinalPm25,
  ) {
    final pm25 = n.hasAqiContext
        ? n.aqiPm25
        : n.notification.pm25Value;
    final pm10 = n.hasAqiContext
        ? n.aqiPm10
        : n.notification.pm10Value;
    return DustCalculator.computeHistoricalFinalRatio(
      tFinalPm25: tFinalPm25,
      pm25: pm25,
      pm10: pm10,
    );
  }

  /// AQI row(일평균) 기반 final_ratio 계산
  static double _ratioForAqiRow(
    Map<String, dynamic> row,
    double tFinalPm25,
  ) {
    final pm25 = (row['pm25_avg'] as num?)?.round();
    final pm10 = (row['pm10_avg'] as num?)?.round();
    return DustCalculator.computeHistoricalFinalRatio(
      tFinalPm25: tFinalPm25,
      pm25: pm25,
      pm10: pm10,
    );
  }

  /// 행 목록의 final_ratio 평균 계산
  static double _avgRatio(
    List<Map<String, dynamic>> rows,
    double tFinalPm25,
  ) {
    if (rows.isEmpty) return 0.0;
    final sum = rows.fold<double>(
      0.0,
      (acc, r) => acc + _ratioForAqiRow(r, tFinalPm25),
    );
    return sum / rows.length;
  }

  /// AQI row에서 요일(1=월 ~ 7=일) 추출
  static int _weekdayFromRow(Map<String, dynamic> row) {
    final day = row['day'] as String?;
    if (day == null) return 0;
    final date = DateTime.tryParse(day);
    return date?.weekday ?? 0;
  }

  /// Δ 값 → TrendCategory 매핑
  static TrendCategory _trendCategory(double delta) {
    if (delta <= -0.3) return TrendCategory.muchBetter;
    if (delta <= -0.1) return TrendCategory.slightlyBetter;
    if (delta < 0.1) return TrendCategory.similar;
    if (delta < 0.3) return TrendCategory.slightlyWorse;
    return TrendCategory.muchWorse;
  }

  // ── 날짜·시간 라벨 ──────────────────────────────────────

  static String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final idx = (weekday - 1).clamp(0, 6);
    return labels[idx];
  }

  /// 시각 → 시간대 레이블
  /// 아침(6~9시) / 오전(9~12) / 점심(12~14) / 오후(14~18) / 저녁(18~21) / 밤(21~6)
  static String _timeOfDayLabel(int hour) {
    if (hour >= 6 && hour < 9) return '아침';
    if (hour >= 9 && hour < 12) return '오전';
    if (hour >= 12 && hour < 14) return '점심';
    if (hour >= 14 && hour < 18) return '오후';
    if (hour >= 18 && hour < 21) return '저녁';
    return '밤';
  }

  /// actionMatch 미주 텍스트
  static String _actionMatchFootnote(DateTime triggeredAt, int pm25) {
    final month = triggeredAt.month;
    final day = triggeredAt.day;
    final weekday = _weekdayLabel(triggeredAt.weekday);
    return 'PM2.5 ${pm25}µg/m³ · ${month}월 ${day}일 ($weekday)';
  }

  /// envPeak 미주 텍스트
  static String _dateFootnote(DateTime date, int pm25) {
    final month = date.month;
    final day = date.day;
    final weekday = _weekdayLabel(date.weekday);
    return 'PM2.5 ${pm25}µg/m³ · ${month}월 ${day}일 ($weekday)';
  }

  /// 날짜 키 — "yyyy-MM-dd"
  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
