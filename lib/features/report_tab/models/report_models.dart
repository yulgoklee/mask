import '../../../data/models/notification_log.dart';

// ── 단계 1 신규 모델 ───────────────────────────────────────

/// 인사이트 카드 카테고리 (우선순위 순)
enum InsightCategory {
  actionMatch,       // 1: 마스크 챙긴 알림 존재
  envPeak,           // 2: final_ratio 1.0 초과 날 존재
  weekdayWeekend,    // 3: 주중-주말 평균 차 ≥ 0.15
  avgSummary,        // 4: 데이터 있음, 위 조건 미충족
  allSafe,           // 5: 전 기간 ratio < 1.0
}

/// InsightEngine이 생성한 인사이트 카드 데이터
class InsightData {
  final InsightCategory category;

  /// 렌더링할 최종 카피 본문
  final String bodyText;

  /// 미주 텍스트 — "PM2.5 XXµg/m³ · 5월 3일 (토)" 형태 (없을 수 있음)
  final String? footnoteText;

  const InsightData({
    required this.category,
    required this.bodyText,
    this.footnoteText,
  });
}

/// WeeklyOverviewCard 1일 원(Circle) 데이터
class DayCircleData {
  final DateTime date;

  /// null = 데이터 없음 (누락 표시)
  final double? finalRatio;

  /// 해당 날 마스크 착용 기록 존재 여부
  final bool maskWorn;

  /// 오늘 날짜 여부 (원 강조 표시용)
  final bool isToday;

  const DayCircleData({
    required this.date,
    required this.finalRatio,
    required this.maskWorn,
    required this.isToday,
  });
}

/// 추세 분류 (이번 주 vs 지난주 final_ratio 평균 차이)
enum TrendCategory {
  muchBetter,      // Δ ≤ -0.3
  slightlyBetter,  // -0.3 < Δ ≤ -0.1
  similar,         // |Δ| < 0.1
  slightlyWorse,   // 0.1 ≤ Δ < 0.3
  muchWorse,       // Δ ≥ 0.3
}

/// TrendLine 위젯용 추세 데이터
class TrendData {
  final TrendCategory category;

  /// 이번 주 평균 - 지난주 평균 (양수 = 악화)
  final double delta;

  const TrendData({required this.category, required this.delta});
}

/// 알림 발송 시점의 AQI 환경 컨텍스트를 포함한 조인 결과
///
/// [notification]  알림 로그 원본
/// [aqiPm25]       조인된 aqi_records의 PM2.5 (1시간 이내 매칭 없으면 null)
/// [aqiPm10]       조인된 aqi_records의 PM10  (1시간 이내 매칭 없으면 null)
/// [aqiDataTime]   조인된 aqi_records의 측정 시각 (null이면 컨텍스트 없음)
class NotificationWithAqiContext {
  final NotificationLog notification;
  final int? aqiPm25;
  final int? aqiPm10;
  final DateTime? aqiDataTime;

  const NotificationWithAqiContext({
    required this.notification,
    this.aqiPm25,
    this.aqiPm10,
    this.aqiDataTime,
  });

  /// 1시간 이내 AQI 컨텍스트가 존재하는지 여부
  bool get hasAqiContext => aqiDataTime != null;
}

enum ReportPeriod { today, threeDays, sevenDays }

extension ReportPeriodX on ReportPeriod {
  int get days => switch (this) {
    ReportPeriod.today      => 1,
    ReportPeriod.threeDays  => 3,
    ReportPeriod.sevenDays  => 7,
  };

  String get label => switch (this) {
    ReportPeriod.today      => '오늘',
    ReportPeriod.threeDays  => '3일',
    ReportPeriod.sevenDays  => '7일',
  };
}

class DailyBarData {
  final DateTime date;
  final double pm25Avg;
  final String grade;
  final bool maskWorn;

  const DailyBarData({
    required this.date,
    required this.pm25Avg,
    required this.grade,
    required this.maskWorn,
  });
}

enum CalendarDayStatus { worn, notWorn, noData }

class CalendarDayData {
  final DateTime date;
  final CalendarDayStatus status;
  final bool isToday;
  final bool isInSelectedPeriod;

  const CalendarDayData({
    required this.date,
    required this.status,
    required this.isToday,
    required this.isInSelectedPeriod,
  });
}

class HighlightData {
  final DateTime date;
  final double pm25Max;
  final String grade;
  final bool maskWorn;
  final bool isAllSafe;

  const HighlightData({
    required this.date,
    required this.pm25Max,
    required this.grade,
    required this.maskWorn,
    required this.isAllSafe,
  });

  factory HighlightData.empty() => HighlightData(
    date: DateTime.now(),
    pm25Max: 0,
    grade: '좋음',
    maskWorn: false,
    isAllSafe: true,
  );
}

class ReportSummaryData {
  final int totalDays;
  final int dangerDays;
  final int maskWornDays;
  final double defenseRate;
  final String dominantGrade;

  const ReportSummaryData({
    required this.totalDays,
    required this.dangerDays,
    required this.maskWornDays,
    required this.defenseRate,
    required this.dominantGrade,
  });

  String get summaryText {
    if (dangerDays == 0) {
      return '지난 ${totalDays}일 동안 위험한 날이 없었어요. 쾌적한 기간이었어요. 👍';
    }
    if (maskWornDays == 0) {
      return '지난 ${totalDays}일 중 ${dangerDays}일이 위험 수준이었어요. 마스크를 챙겨보세요.';
    }
    return '지난 ${totalDays}일 중 ${dangerDays}일이 위험 수준이었고, '
        '마스크를 착용한 날은 ${maskWornDays}일이었어요.';
  }
}

String gradeFromPm25(double pm25) {
  if (pm25 <= 15) return '좋음';
  if (pm25 <= 35) return '보통';
  if (pm25 <= 75) return '나쁨';
  return '매우나쁨';
}
