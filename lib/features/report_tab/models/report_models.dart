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
