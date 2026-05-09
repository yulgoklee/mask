// ── 리포트 탭 v2 모델 ─────────────────────────────────────────

/// 이번 주 리포트 상태
enum WeekReportState {
  /// 정상 — 임계치 초과 시간 있음
  normal,

  /// 안전 — 임계치 초과 없음
  safe,

  /// 빈 데이터 — 첫 가입 직후 등 데이터 부족 (3일 미만)
  empty,
}

/// 캘린더 7일 중 하루 데이터
class DayCalendarData {
  final DateTime date;

  /// '월'~'일'
  final String weekdayLabel;

  /// 그날 최고 final_ratio. null = 데이터 없음
  final double? peakRatio;

  final bool hasData;

  const DayCalendarData({
    required this.date,
    required this.weekdayLabel,
    required this.peakRatio,
    required this.hasData,
  });
}

/// 패턴 발견 한 줄
class PatternData {
  /// 발견 문장: "월·화 오후가 더 위험했어요"
  final String discoveryText;

  /// 데이터 근거 캡션: "5/4 14시 PM2.5 52㎍"
  final String noteText;

  const PatternData({
    required this.discoveryText,
    required this.noteText,
  });
}

/// 주간 리포트 전체 데이터 (weekReportProvider 반환값)
class WeekReportData {
  /// "5월 1주차 · 5/4 ~ 5/10"
  final String weekCaption;

  final WeekReportState state;

  /// 위험 고유 시간대 수 (Set<String> 키: 'yyyy-MM-dd HH')
  final int dangerHours;

  /// 7개 고정 (월~일 순서)
  final List<DayCalendarData> days;

  /// null이면 PatternLine 숨김
  final PatternData? pattern;

  /// "14:02 갱신"
  final String updatedTimeLabel;

  /// CareBackground 색상 결정용 — dustDataProvider에서 직접 계산
  final double currentFinalRatio;

  const WeekReportData({
    required this.weekCaption,
    required this.state,
    required this.dangerHours,
    required this.days,
    this.pattern,
    required this.updatedTimeLabel,
    required this.currentFinalRatio,
  });

  /// 빈 상태 팩토리
  factory WeekReportData.empty() {
    final now = DateTime.now();
    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    // 월~일 순서로 이번 주 7일
    final today = DateTime(now.year, now.month, now.day);
    // 이번 주 월요일 계산 (weekday 1=월~7=일)
    final mondayOffset = today.weekday - 1;
    final monday = today.subtract(Duration(days: mondayOffset));
    final days = List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return DayCalendarData(
        date: date,
        weekdayLabel: weekdayLabels[i],
        peakRatio: null,
        hasData: false,
      );
    });
    final caption = _buildWeekCaption(monday, monday.add(const Duration(days: 6)));
    return WeekReportData(
      weekCaption: caption,
      state: WeekReportState.empty,
      dangerHours: 0,
      days: days,
      pattern: null,
      updatedTimeLabel: _buildTimeLabel(now),
      currentFinalRatio: 0.0,
    );
  }

  static String _buildWeekCaption(DateTime monday, DateTime sunday) {
    final weekNum = ((monday.day - 1) ~/ 7) + 1;
    final mm = monday.month;
    final sd = sunday.month;
    return '${mm}월 ${weekNum}주차 · $mm/${monday.day} ~ $sd/${sunday.day}';
  }

  static String _buildTimeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m 갱신';
  }
}

// ── Drill-down 모델 ────────────────────────────────────────────

/// 일별 상세 행 (Drill-down)
class DrillDayRow {
  /// "월 · 5/4"
  final String dateLabel;

  /// "14~17시" 또는 "—"
  final String hoursRange;

  /// PM2.5 최고값 (null이면 "—")
  final int? peakPm25;

  /// 그날 최고 final_ratio
  final double peakRatio;

  /// 위험(≥1.0) 레코드 수
  final int dangerRecordCount;

  const DrillDayRow({
    required this.dateLabel,
    required this.hoursRange,
    required this.peakPm25,
    required this.peakRatio,
    required this.dangerRecordCount,
  });
}

/// 히트맵 데이터 (7×24)
class DrillHeatmapData {
  /// [weekdayIdx(0=월~6=일)][hour(0~23)] = ratio? (null=데이터없음)
  final List<List<double?>> grid;

  /// ['월','화','수','목','금','토','일']
  final List<String> weekdayLabels;

  const DrillHeatmapData({
    required this.grid,
    required this.weekdayLabels,
  });
}

/// Drill-down 화면 전체 데이터 (drillReportProvider 반환값)
class DrillReportData {
  final DrillHeatmapData heatmap;
  final List<DrillDayRow> dayRows;
  final String weekCaption;

  const DrillReportData({
    required this.heatmap,
    required this.dayRows,
    required this.weekCaption,
  });
}
