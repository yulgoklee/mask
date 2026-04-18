import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/health_calculator.dart';
import '../data/datasources/defense_repository.dart';
import '../data/models/defense_record.dart';
import '../data/models/notification_log.dart';
import 'core_providers.dart';

// ── Repository ────────────────────────────────────────────────

/// [DefenseRepository] 인스턴스
final defenseRepositoryProvider = Provider<DefenseRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DefenseRepository(prefs);
});

// ── Records ───────────────────────────────────────────────────

/// 전체 방어 기록 목록 (최근 90일, 최신 순)
final defenseRecordsProvider = Provider<List<DefenseRecord>>((ref) {
  final repo = ref.watch(defenseRepositoryProvider);
  return repo.loadAll();
});

/// 이번 주(최근 7일) 방어 기록
final weeklyRecordsProvider = Provider<List<DefenseRecord>>((ref) {
  final repo = ref.watch(defenseRepositoryProvider);
  return repo.thisWeek();
});

// ── Stats ─────────────────────────────────────────────────────

/// 이번 주 통계
class WeeklyStats {
  final int count;
  final double totalUg;
  final int streakDays;
  final List<double> dailyTotals; // index 0 = 오늘, 6 = 6일 전

  const WeeklyStats({
    required this.count,
    required this.totalUg,
    required this.streakDays,
    required this.dailyTotals,
  });
}

final weeklyStatsProvider = Provider<WeeklyStats>((ref) {
  final repo = ref.watch(defenseRepositoryProvider);
  final allRecords = repo.loadAll();

  // dailyTotals용 레코드 변환
  final forChart = allRecords
      .map((r) => (timestamp: r.timestamp, blockedMassUg: r.blockedMassUg))
      .toList();

  return WeeklyStats(
    count: repo.weeklyCount,
    totalUg: repo.weeklyTotalUg,
    streakDays: repo.streakDays,
    dailyTotals: HealthCalculator.dailyTotals(forChart),
  );
});

// ── Notifier (기록 추가 후 상태 갱신) ─────────────────────────

/// 방어 기록을 추가하고 관련 Provider를 갱신하는 StateNotifier
class DefenseRecordNotifier extends StateNotifier<List<DefenseRecord>> {
  final DefenseRepository _repo;
  final Ref _ref;

  DefenseRecordNotifier(this._repo, this._ref) : super(_repo.loadAll());

  Future<void> addRecord(DefenseRecord record) async {
    await _repo.addRecord(record);
    state = _repo.loadAll();
    // weeklyStats도 갱신되도록 관련 프로바이더 invalidate
    _ref.invalidate(defenseRepositoryProvider);
  }
}

final defenseRecordNotifierProvider =
    StateNotifierProvider<DefenseRecordNotifier, List<DefenseRecord>>((ref) {
  final repo = ref.watch(defenseRepositoryProvider);
  return DefenseRecordNotifier(repo, ref);
});

// ── Phase 5: 방어율 (SQLite 기반) ─────────────────────────────

/// 방어율 통계 모델
class DefenseRateStats {
  /// 기간 내 총 알림 수
  final int total;

  /// [마스크 챙겼어요] 탭 = 확정 방어 수
  final int defended;

  /// 알림 탭(앱 열기만) = 추정 방어 수
  final int estimated;

  const DefenseRateStats({
    required this.total,
    required this.defended,
    required this.estimated,
  });

  /// 확정 방어율 (0.0 ~ 1.0)
  double get confirmedRate => total > 0 ? defended / total : 0.0;

  /// 확정 + 추정 합산 방어율
  double get totalRate =>
      total > 0 ? (defended + estimated) / total : 0.0;

  /// 방어율 % 문자열 (소수점 없음)
  String get ratePercent => '${(confirmedRate * 100).round()}%';

  /// 방어율 기반 메타포 문구 — '다정한 물리학자' 톤
  String get metaphorText {
    final r = confirmedRate;
    if (total == 0) return '아직 위험 알림이 없었어요. 공기가 맑은 날이에요 😊';
    if (r >= 0.9)   return '미세먼지가 넘보지 못했어요 🏆 완벽에 가까운 방어예요!';
    if (r >= 0.75)  return '아주 든든한 방어력이에요 💪 거의 다 막아냈어요';
    if (r >= 0.5)   return '마스크와 꽤 친해졌어요 😊 반 이상을 지켜냈어요';
    if (r >= 0.25)  return '조금씩 방어 습관이 쌓이고 있어요 💙';
    return '첫 발걸음을 내디뎠어요. 알림이 오면 챙겨봐요 🌱';
  }

  /// 방어율 서브 문구 (수치 근거)
  String subText(int days) =>
      total > 0 ? '최근 ${days}일 알림 $total회 중 $defended회 챙김' : '최근 ${days}일 위험 알림 없음';

  static const DefenseRateStats empty =
      DefenseRateStats(total: 0, defended: 0, estimated: 0);
}

/// 방어율 통계 Provider (최근 7일 기본)
final defenseRateProvider =
    FutureProvider.family<DefenseRateStats, int>((ref, days) async {
  final db = ref.watch(localDatabaseProvider);
  try {
    final stats = await db.getNotifActionStats(days: days);
    return DefenseRateStats(
      total: stats.total,
      defended: stats.defended,
      estimated: stats.estimated,
    );
  } catch (_) {
    return DefenseRateStats.empty;
  }
});

// ── Phase 5: 방어 달력 (SQLite 기반) ──────────────────────────

/// 달력 하루의 방어 상태
enum CalendarDayStatus {
  defended, // 위험 알림 AND 마스크 챙겼어요 → 초록
  missed,   // 위험 알림 AND 미응답 → 주황
  clean,    // 위험 알림 없음 → 회색
}

/// 달력 단일 날짜 모델
class DefenseCalendarDay {
  final DateTime date;
  final CalendarDayStatus status;

  /// 당일 발송된 알림 수
  final int notifCount;

  const DefenseCalendarDay({
    required this.date,
    required this.status,
    required this.notifCount,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// 30일 방어 달력 Provider
final defenseCalendarProvider =
    FutureProvider<List<DefenseCalendarDay>>((ref) async {
  const days = 30;
  final db = ref.watch(localDatabaseProvider);
  try {
    final logs = await db.getNotificationLogsSince(days: days);

    // 날짜별 그룹핑
    final Map<String, List<NotificationLog>> byDate = {};
    for (final log in logs) {
      final key = _dateKey(log.triggeredAt);
      byDate.putIfAbsent(key, () => []).add(log);
    }

    // 오늘부터 29일 전까지 달력 생성 (최신 → 과거 순)
    final result = <DefenseCalendarDay>[];
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dateKey(date);
      final dayLogs = byDate[key] ?? [];

      CalendarDayStatus status;
      if (dayLogs.isEmpty) {
        status = CalendarDayStatus.clean;
      } else if (dayLogs.any((l) => l.isConfirmedDefense)) {
        status = CalendarDayStatus.defended;
      } else {
        status = CalendarDayStatus.missed;
      }

      result.add(DefenseCalendarDay(
        date: date,
        status: status,
        notifCount: dayLogs.length,
      ));
    }
    return result;
  } catch (_) {
    return [];
  }
});

String _dateKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';
