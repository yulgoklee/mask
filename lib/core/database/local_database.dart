import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/aqi_record.dart';
import '../../data/models/notification_log.dart';

/// SQLite 로컬 데이터베이스 서비스
///
/// 테이블 구성:
/// - aqi_records      : 시간별 AQI 폴링 기록 (최근 7일만 유지)
/// - notification_logs: 알림 발송 및 사용자 액션 기록 (최근 90일)
///                      notification_logs가 모든 통계의 단일 SoT
///                      v2: mask_type, snooze_until 컬럼 추가 / defense_daily 제거
class LocalDatabase {
  static const _dbName = 'mask_alert.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE aqi_records (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        station_name TEXT NOT NULL,
        pm25_value   INTEGER,
        pm10_value   INTEGER,
        pm25_grade   TEXT,
        data_time    TEXT NOT NULL,
        fetched_at   TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_aqi_fetched ON aqi_records(fetched_at)
    ''');

    await db.execute('''
      CREATE TABLE notification_logs (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        triggered_at      TEXT NOT NULL,
        notification_type TEXT NOT NULL,
        pm25_value        INTEGER,
        t_final           REAL,
        user_action       TEXT NOT NULL DEFAULT 'none',
        mask_type         TEXT,
        snooze_until      TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE notification_logs ADD COLUMN mask_type TEXT');
      await db.execute(
          'ALTER TABLE notification_logs ADD COLUMN snooze_until TEXT');
      await db.execute('DROP TABLE IF EXISTS defense_daily');
    }
    if (oldVersion < 3) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_aqi_station_time '
        'ON aqi_records(station_name, data_time)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notif_triggered '
        'ON notification_logs(triggered_at)',
      );
    }
  }

  // ── AQI Records ─────────────────────────────────────────────

  Future<void> insertAqiRecord(AqiRecord record) async {
    final db = await database;
    await db.insert('aqi_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await _pruneAqiRecords(db);
  }

  /// 최근 N시간 AQI 기록 조회 (차트용)
  Future<List<AqiRecord>> getRecentAqiRecords({
    required String stationName,
    int hours = 6,
  }) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(hours: hours)).toIso8601String();
    final rows = await db.query(
      'aqi_records',
      where: 'station_name = ? AND fetched_at >= ?',
      whereArgs: [stationName, since],
      orderBy: 'fetched_at ASC',
    );
    return rows.map(AqiRecord.fromMap).toList();
  }

  /// 7일 초과 데이터 자동 삭제
  Future<void> _pruneAqiRecords(Database db) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    await db.delete('aqi_records', where: 'fetched_at < ?', whereArgs: [cutoff]);
  }

  // ── Notification Logs ────────────────────────────────────────

  /// 알림 로그 삽입 — 반환값: SQLite row id (background handler 연결용)
  Future<int> insertNotificationLog(NotificationLog log) async {
    final db = await database;
    return db.insert('notification_logs', log.toMap());
  }

  /// 알림 발송 후 사용자 액션 업데이트 (앱 열기 등 기본 액션)
  Future<void> updateUserAction(int id, UserAction action) async {
    final db = await database;
    await db.update(
      'notification_logs',
      {'user_action': action.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// [마스크 챙겼어요] 액션 — user_action + 마스크 종류 스냅샷 동시 기록
  Future<void> updateMaskWorn(int id, String maskType) async {
    final db = await database;
    await db.update(
      'notification_logs',
      {
        'user_action': UserAction.maskWorn.name,
        'mask_type': maskType,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// [나중에 ✋] 액션 — user_action + 스누즈 만료 시각 기록
  Future<void> updateSnoozed(int id, DateTime snoozeUntil) async {
    final db = await database;
    await db.update(
      'notification_logs',
      {
        'user_action': UserAction.snoozed.name,
        'snooze_until': snoozeUntil.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 현재 활성 스누즈 여부 — snooze_until > now 인 로그가 존재하면 true
  Future<bool> isSnoozeActive() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM notification_logs WHERE snooze_until > ?',
          [now],
        )) ??
        0;
    return count > 0;
  }

  /// 특정 날짜의 알림 로그 조회 (방어율 계산용)
  Future<List<NotificationLog>> getLogsForDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final rows = await db.query(
      'notification_logs',
      where: 'triggered_at >= ? AND triggered_at <= ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'triggered_at ASC',
    );
    return rows.map(NotificationLog.fromMap).toList();
  }

  /// 가장 최근 미처리(none) 알림 조회 — 딥링크 충돌 해결용
  ///
  /// 여러 알림이 연속 발송됐을 때 유저 액션을 가장 최신 알림에 귀속시킨다.
  Future<NotificationLog?> getLatestNoneLog() async {
    final db = await database;
    final rows = await db.query(
      'notification_logs',
      where: 'user_action = ?',
      whereArgs: [UserAction.none.name],
      orderBy: 'triggered_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NotificationLog.fromMap(rows.first);
  }

  /// 최근 발송된 알림 조회 (도배 방지 로직용)
  Future<NotificationLog?> getLastNotification() async {
    final db = await database;
    final rows = await db.query(
      'notification_logs',
      orderBy: 'triggered_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NotificationLog.fromMap(rows.first);
  }

  // ── 리포트 탭 집계 쿼리 ──────────────────────────────────────

  /// 날짜별 PM2.5 평균 집계 (리포트 바 차트용)
  ///
  /// 반환: [{day: 'YYYY-MM-DD', pm25_avg: double, pm10_avg: double, record_count: int}]
  Future<List<Map<String, dynamic>>> getDailyAqiAverages({
    required String stationName,
    required int days,
  }) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    return db.rawQuery('''
      SELECT
        DATE(data_time) AS day,
        AVG(CAST(pm25_value AS REAL)) AS pm25_avg,
        AVG(CAST(pm10_value AS REAL)) AS pm10_avg,
        COUNT(*) AS record_count
      FROM aqi_records
      WHERE station_name = ?
        AND data_time >= ?
        AND pm25_value IS NOT NULL
      GROUP BY DATE(data_time)
      ORDER BY day ASC
    ''', [stationName, since]);
  }

  /// 기간 내 PM2.5 최고값 기록 (하이라이트 카드용)
  Future<AqiRecord?> getMaxPm25Record({
    required String stationName,
    required int days,
  }) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await db.rawQuery('''
      SELECT * FROM aqi_records
      WHERE station_name = ?
        AND data_time >= ?
        AND pm25_value IS NOT NULL
      ORDER BY pm25_value DESC
      LIMIT 1
    ''', [stationName, since]);
    if (rows.isEmpty) return null;
    return AqiRecord.fromMap(rows.first);
  }

  /// 최근 N일 알림 로그 날짜별 그룹 조회 (캘린더용)
  ///
  /// 반환: {'YYYY-MM-DD': [NotificationLog, ...]}
  Future<Map<String, List<NotificationLog>>> getLogsGroupedByDate({
    int days = 7,
  }) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days - 1))
        .toIso8601String();
    final rows = await db.query(
      'notification_logs',
      where: 'triggered_at >= ?',
      whereArgs: [since],
      orderBy: 'triggered_at ASC',
    );
    final result = <String, List<NotificationLog>>{};
    for (final row in rows) {
      final log = NotificationLog.fromMap(row);
      final key = log.triggeredAt.toIso8601String().substring(0, 10);
      result.putIfAbsent(key, () => []).add(log);
    }
    return result;
  }

  // ── Phase 5: 방어율·달력 쿼리 ────────────────────────────────

  /// 기간 내 알림 액션 집계 (방어율 카드용)
  ///
  /// 반환: (total, defended, estimated)
  /// suppressedByQuietHours 로그는 분모(total)에서 제외 — 방해 금지 억제는 기회 자체가 없었으므로 비율 왜곡 방지
  Future<({int total, int defended, int estimated})> getNotifActionStats({
    int days = 7,
  }) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    final total = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM notification_logs "
          "WHERE triggered_at >= ? AND user_action != 'suppressedByQuietHours'",
          [since],
        )) ??
        0;
    final defended = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM notification_logs "
          "WHERE triggered_at >= ? AND user_action = 'maskWorn'",
          [since],
        )) ??
        0;
    final estimated = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM notification_logs "
          "WHERE triggered_at >= ? AND user_action = 'appOpened'",
          [since],
        )) ??
        0;
    return (total: total, defended: defended, estimated: estimated);
  }

  /// defense_daily → notification_logs 마이그레이션 (구버전 데이터 변환용)
  ///
  /// pre-launch에서는 DROP이 기본이지만, 향후 구버전 → v2 업그레이드 사용자를
  /// 위해 defense_daily 레코드를 notification_logs 형식으로 변환한다.
  /// defense_daily 테이블이 없으면 조용히 종료.
  Future<void> migrateDefenseDailyToLogs() async {
    final db = await database;
    try {
      // 테이블 존재 여부 확인
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='defense_daily'",
      );
      if (tables.isEmpty) return;

      final rows = await db.rawQuery('SELECT * FROM defense_daily');
      for (final row in rows) {
        final dateStr = row['date'] as String?;
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        // defense_daily 1행 = 해당 날짜에 마스크 착용 기록
        await db.insert(
          'notification_logs',
          {
            'triggered_at': date.toIso8601String(),
            'notification_type': 'morning',
            'user_action': 'maskWorn',
            'mask_type': row['mask_type'] as String? ?? 'KF80',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      // 이전 테이블 정리
      await db.execute('DROP TABLE IF EXISTS defense_daily');
    } catch (_) {
      // 마이그레이션 실패는 조용히 무시 — 신규 설치에는 defense_daily 없음
    }
  }

  /// 기간 내 알림 로그 목록 (달력 구성용)
  Future<List<NotificationLog>> getNotificationLogsSince({
    int days = 30,
  }) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await db.query(
      'notification_logs',
      where: 'triggered_at >= ?',
      whereArgs: [since],
      orderBy: 'triggered_at ASC',
    );
    return rows.map(NotificationLog.fromMap).toList();
  }

  // ── 유틸 ─────────────────────────────────────────────────────

  Future<void> close() async => _db?.close();
}
