import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/aqi_record.dart';
import '../../data/models/notification_log.dart';

/// SQLite 로컬 데이터베이스 서비스
///
/// 테이블 구성:
/// - aqi_records      : 시간별 AQI 폴링 기록 (최근 7일만 유지)
/// - notification_logs: 알림 발송 및 사용자 액션 기록 (최근 90일)
/// - defense_daily    : 일별 방어율 집계 (Stage 4 리포트용)
class LocalDatabase {
  static const _dbName = 'mask_alert.db';
  static const _dbVersion = 1;

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
        user_action       TEXT NOT NULL DEFAULT 'none'
      )
    ''');

    await db.execute('''
      CREATE TABLE defense_daily (
        id                          INTEGER PRIMARY KEY AUTOINCREMENT,
        date                        TEXT NOT NULL UNIQUE,
        danger_minutes              INTEGER NOT NULL DEFAULT 0,
        confirmed_defense_minutes   INTEGER NOT NULL DEFAULT 0,
        estimated_defense_minutes   INTEGER NOT NULL DEFAULT 0
      )
    ''');
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

  /// 알림 발송 후 사용자 액션 업데이트 (마스크 챙김 / 앱 열기)
  Future<void> updateUserAction(int id, UserAction action) async {
    final db = await database;
    await db.update(
      'notification_logs',
      {'user_action': action.name},
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // ── Defense Daily ────────────────────────────────────────────

  /// 일별 방어 통계 upsert
  Future<void> upsertDefenseDaily({
    required DateTime date,
    required int dangerMinutes,
    required int confirmedDefenseMinutes,
    required int estimatedDefenseMinutes,
  }) async {
    final db = await database;
    final dateStr = _dateKey(date);
    await db.insert(
      'defense_daily',
      {
        'date': dateStr,
        'danger_minutes': dangerMinutes,
        'confirmed_defense_minutes': confirmedDefenseMinutes,
        'estimated_defense_minutes': estimatedDefenseMinutes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 최근 N일 방어 통계 조회
  Future<List<Map<String, dynamic>>> getDefenseDailySummary({int days = 30}) async {
    final db = await database;
    final since = _dateKey(DateTime.now().subtract(Duration(days: days)));
    return db.query(
      'defense_daily',
      where: 'date >= ?',
      whereArgs: [since],
      orderBy: 'date ASC',
    );
  }

  // ── 유틸 ─────────────────────────────────────────────────────

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  Future<void> close() async => _db?.close();
}
