import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/health_calculator.dart';
import '../data/datasources/defense_repository.dart';
import '../data/models/defense_record.dart';
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
