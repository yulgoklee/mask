/// DB schema v4 마이그레이션 및 조인 쿼리 단위 테스트
///
/// sqflite_common_ffi를 사용해 인메모리 SQLite 위에서 실행.
/// 실제 LocalDatabase 클래스를 직접 사용하지 않고, 동등한 스키마를
/// 직접 재현해 테스트의 범위를 명확히 한다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mask_alert/data/models/notification_log.dart';

// ── 인메모리 DB 헬퍼 ──────────────────────────────────────────

/// v3 스키마 (pm10_value 없는 notification_logs) 생성
Future<Database> _openV3Db() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 3),
  );
  await db.execute('''
    CREATE TABLE aqi_records (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
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
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_notif_triggered ON notification_logs(triggered_at)',
  );
  return db;
}

/// v4 스키마 (pm10_value 있는 notification_logs) 생성
Future<Database> _openV4Db() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 4),
  );
  await db.execute('''
    CREATE TABLE aqi_records (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
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
      pm10_value        INTEGER,
      t_final           REAL,
      user_action       TEXT NOT NULL DEFAULT 'none',
      mask_type         TEXT,
      snooze_until      TEXT
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_notif_triggered ON notification_logs(triggered_at)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_aqi_station_time '
    'ON aqi_records(station_name, data_time)',
  );
  return db;
}

// ── getNotificationsWithAqiContext SQL (local_database.dart와 동일) ──

Future<List<NotificationWithAqiContext>> _getNotificationsWithAqiContext(
  Database db, {
  required DateTime start,
  required DateTime end,
  required String stationName,
}) async {
  final startStr = start.toIso8601String();
  final endStr = end.toIso8601String();

  final rows = await db.rawQuery('''
    SELECT
      n.id                 AS n_id,
      n.triggered_at       AS n_triggered_at,
      n.notification_type  AS n_notification_type,
      n.pm25_value         AS n_pm25_value,
      n.pm10_value         AS n_pm10_value,
      n.t_final            AS n_t_final,
      n.user_action        AS n_user_action,
      n.mask_type          AS n_mask_type,
      n.snooze_until       AS n_snooze_until,
      a.pm25_value         AS a_pm25_value,
      a.pm10_value         AS a_pm10_value,
      a.data_time          AS a_data_time
    FROM notification_logs n
    LEFT JOIN aqi_records a ON
      a.station_name = ?
      AND ABS(julianday(n.triggered_at) - julianday(a.data_time)) <= (1.0 / 24.0)
      AND a.id = (
        SELECT a2.id FROM aqi_records a2
        WHERE a2.station_name = ?
        ORDER BY ABS(julianday(n.triggered_at) - julianday(a2.data_time)) ASC
        LIMIT 1
      )
    WHERE n.triggered_at >= ?
      AND n.triggered_at <= ?
    ORDER BY n.triggered_at ASC
  ''', [stationName, stationName, startStr, endStr]);

  return rows.map((row) {
    final log = NotificationLog(
      id: row['n_id'] as int?,
      triggeredAt: DateTime.parse(row['n_triggered_at'] as String),
      notificationType: NotificationType.values.firstWhere(
        (e) => e.name == row['n_notification_type'],
        orElse: () => NotificationType.dangerEntry,
      ),
      pm25Value: row['n_pm25_value'] as int?,
      pm10Value: row['n_pm10_value'] as int?,
      tFinal: (row['n_t_final'] as num?)?.toDouble(),
      userAction: UserAction.values.firstWhere(
        (e) => e.name == row['n_user_action'],
        orElse: () => UserAction.none,
      ),
      maskType: row['n_mask_type'] as String?,
      snoozeUntil: row['n_snooze_until'] != null
          ? DateTime.parse(row['n_snooze_until'] as String)
          : null,
    );
    final aqiDataTimeStr = row['a_data_time'] as String?;
    return NotificationWithAqiContext(
      notification: log,
      aqiPm25: row['a_pm25_value'] as int?,
      aqiPm10: row['a_pm10_value'] as int?,
      aqiDataTime:
          aqiDataTimeStr != null ? DateTime.parse(aqiDataTimeStr) : null,
    );
  }).toList();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  // ── 작업 1: DB v3 → v4 마이그레이션 검증 ────────────────────

  group('DB v3 → v4 migration', () {
    test('v3 DB에 pm10_value 컬럼 없음 (기준 확인)', () async {
      final db = await _openV3Db();

      // v3 INSERT: pm10_value 없이 성공해야 함
      await db.insert('notification_logs', {
        'triggered_at': DateTime.now().toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 45,
        'user_action': 'none',
      });

      final rows = await db.query('notification_logs');
      expect(rows.length, 1);
      // pm10_value 컬럼 자체가 없으므로 키가 없음
      expect(rows.first.containsKey('pm10_value'), false);

      await db.close();
    });

    test('v3 → v4: ALTER TABLE 후 pm10_value 컬럼 추가 검증', () async {
      final db = await _openV3Db();

      // 기존 데이터 삽입 (pm10_value 없음)
      await db.insert('notification_logs', {
        'triggered_at': DateTime.now().toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 30,
        'user_action': 'maskWorn',
      });

      // v3 → v4 마이그레이션 적용
      await db.execute(
        'ALTER TABLE notification_logs ADD COLUMN pm10_value INTEGER',
      );

      // 기존 row는 pm10_value = NULL
      final rows = await db.query('notification_logs');
      expect(rows.length, 1);
      expect(rows.first['pm10_value'], isNull);

      // 새 INSERT에는 pm10_value 포함 가능
      await db.insert('notification_logs', {
        'triggered_at': DateTime.now().toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 50,
        'pm10_value': 90,
        'user_action': 'none',
      });

      final after = await db.query('notification_logs', orderBy: 'id ASC');
      expect(after.length, 2);
      expect(after[0]['pm10_value'], isNull);   // 마이그레이션 전 row
      expect(after[1]['pm10_value'], 90);       // 마이그레이션 후 row

      await db.close();
    });

    test('v4 신규 설치: pm10_value 컬럼 존재', () async {
      final db = await _openV4Db();

      await db.insert('notification_logs', {
        'triggered_at': DateTime.now().toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 55,
        'pm10_value': 100,
        'user_action': 'none',
      });

      final rows = await db.query('notification_logs');
      expect(rows.first['pm10_value'], 100);

      await db.close();
    });
  });

  // ── 작업 3: getNotificationsWithAqiContext 조인 쿼리 검증 ───

  group('getNotificationsWithAqiContext', () {
    late Database db;
    const station = '서울';
    // 기준 시각: 2026-05-03T10:00:00
    final base = DateTime(2026, 5, 3, 10, 0, 0);

    setUp(() async {
      db = await _openV4Db();
    });

    tearDown(() async {
      await db.close();
    });

    test('정확한 매칭 — 알림과 AQI가 동일 시각 → AQI 컨텍스트 반환', () async {
      // AQI 삽입: base 시각
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 40,
        'pm10_value': 75,
        'data_time': base.toIso8601String(),
        'fetched_at': base.toIso8601String(),
      });

      // 알림 삽입: base 시각 (차이 0분)
      await db.insert('notification_logs', {
        'triggered_at': base.toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 40,
        'pm10_value': 75,
        'user_action': 'none',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: base.subtract(const Duration(hours: 1)),
        end: base.add(const Duration(hours: 1)),
        stationName: station,
      );

      expect(result.length, 1);
      expect(result[0].hasAqiContext, true);
      expect(result[0].aqiPm25, 40);
      expect(result[0].aqiPm10, 75);
    });

    test('30분 오프셋 — 1시간 이내 → AQI 컨텍스트 반환', () async {
      final aqiTime = base.add(const Duration(minutes: 30));
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 38,
        'pm10_value': 70,
        'data_time': aqiTime.toIso8601String(),
        'fetched_at': aqiTime.toIso8601String(),
      });

      await db.insert('notification_logs', {
        'triggered_at': base.toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 35,
        'user_action': 'maskWorn',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: base.subtract(const Duration(hours: 1)),
        end: base.add(const Duration(hours: 2)),
        stationName: station,
      );

      expect(result.length, 1);
      expect(result[0].hasAqiContext, true);
      expect(result[0].aqiPm25, 38);
    });

    test('70분 오프셋 — 1시간 초과 → AQI 컨텍스트 없음 (null)', () async {
      final aqiTime = base.add(const Duration(minutes: 70));
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 42,
        'pm10_value': 80,
        'data_time': aqiTime.toIso8601String(),
        'fetched_at': aqiTime.toIso8601String(),
      });

      await db.insert('notification_logs', {
        'triggered_at': base.toIso8601String(),
        'notification_type': 'realtime',
        'pm25_value': 41,
        'user_action': 'none',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: base.subtract(const Duration(hours: 1)),
        end: base.add(const Duration(hours: 2)),
        stationName: station,
      );

      expect(result.length, 1);
      expect(result[0].hasAqiContext, false);
      expect(result[0].aqiPm25, isNull);
      expect(result[0].aqiPm10, isNull);
    });

    test('AQI 데이터 없음 → 알림은 반환되지만 AQI 컨텍스트 null', () async {
      await db.insert('notification_logs', {
        'triggered_at': base.toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 25,
        'user_action': 'none',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: base.subtract(const Duration(hours: 1)),
        end: base.add(const Duration(hours: 1)),
        stationName: station,
      );

      expect(result.length, 1);
      expect(result[0].hasAqiContext, false);
      expect(result[0].notification.pm25Value, 25);
    });

    test('기간 밖 알림 — 조회 범위에서 제외', () async {
      // 범위 밖 알림 (base - 2h)
      await db.insert('notification_logs', {
        'triggered_at': base.subtract(const Duration(hours: 2)).toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 20,
        'user_action': 'none',
      });
      // 범위 안 알림 (base)
      await db.insert('notification_logs', {
        'triggered_at': base.toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 50,
        'user_action': 'none',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: base.subtract(const Duration(hours: 1)),
        end: base.add(const Duration(hours: 1)),
        stationName: station,
      );

      expect(result.length, 1);
      expect(result[0].notification.pm25Value, 50);
    });

    test('다른 측정소 AQI — 조인 안 됨', () async {
      await db.insert('aqi_records', {
        'station_name': '부산',  // 다른 측정소
        'pm25_value': 60,
        'pm10_value': 110,
        'data_time': base.toIso8601String(),
        'fetched_at': base.toIso8601String(),
      });

      await db.insert('notification_logs', {
        'triggered_at': base.toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 55,
        'user_action': 'none',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: base.subtract(const Duration(hours: 1)),
        end: base.add(const Duration(hours: 1)),
        stationName: station, // '서울' 기준으로 조회
      );

      expect(result.length, 1);
      expect(result[0].hasAqiContext, false); // 부산 AQI는 조인 안 됨
    });

    test('복수 알림 — 각각 독립 매칭', () async {
      final t1 = base;
      final t2 = base.add(const Duration(hours: 3));

      // AQI: t1 시각
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 30,
        'pm10_value': 55,
        'data_time': t1.toIso8601String(),
        'fetched_at': t1.toIso8601String(),
      });

      // 알림 1: t1 (AQI 있음)
      await db.insert('notification_logs', {
        'triggered_at': t1.toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 30,
        'user_action': 'none',
      });

      // 알림 2: t2 (AQI 없음, 3시간 차이)
      await db.insert('notification_logs', {
        'triggered_at': t2.toIso8601String(),
        'notification_type': 'return',
        'pm25_value': 22,
        'user_action': 'maskWorn',
      });

      final result = await _getNotificationsWithAqiContext(
        db,
        start: t1.subtract(const Duration(minutes: 30)),
        end: t2.add(const Duration(minutes: 30)),
        stationName: station,
      );

      expect(result.length, 2);
      expect(result[0].hasAqiContext, true);
      expect(result[0].aqiPm25, 30);
      expect(result[1].hasAqiContext, false); // 3시간 차이 → 매칭 없음
    });
  });

  // ── 단계 1 신규: getDailyAqiAverages 쿼리 검증 ──────────────

  group('getDailyAqiAverages', () {
    late Database db;
    const station = '서울';

    setUp(() async {
      db = await _openV4Db();
    });

    tearDown(() async {
      await db.close();
    });

    /// 헬퍼: getDailyAqiAverages SQL 재현
    Future<List<Map<String, dynamic>>> getDailyAqiAverages(
      Database db, {
      required String stationName,
      required int days,
    }) async {
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

    test('일별 평균 정확성 — 동일 날짜 2개 레코드 평균', () async {
      final day = DateTime.now().subtract(const Duration(days: 1));
      final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      // 같은 날 2개 레코드
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 20,
        'pm10_value': 40,
        'data_time': '${dayStr}T09:00:00',
        'fetched_at': '${dayStr}T09:00:00',
      });
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 30,
        'pm10_value': 60,
        'data_time': '${dayStr}T15:00:00',
        'fetched_at': '${dayStr}T15:00:00',
      });

      final rows = await getDailyAqiAverages(
        db,
        stationName: station,
        days: 7,
      );

      expect(rows.length, 1);
      expect(rows[0]['day'], dayStr);
      // pm25_avg = (20 + 30) / 2 = 25
      expect((rows[0]['pm25_avg'] as num).toDouble(), closeTo(25.0, 0.01));
      // pm10_avg = (40 + 60) / 2 = 50
      expect((rows[0]['pm10_avg'] as num).toDouble(), closeTo(50.0, 0.01));
    });

    test('NULL pm10 포함 케이스 — pm25_avg만 반환, pm10_avg null', () async {
      final day = DateTime.now().subtract(const Duration(days: 1));
      final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      // pm10_value = NULL인 레코드
      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 25,
        'pm10_value': null,
        'data_time': '${dayStr}T09:00:00',
        'fetched_at': '${dayStr}T09:00:00',
      });

      final rows = await getDailyAqiAverages(
        db,
        stationName: station,
        days: 7,
      );

      expect(rows.length, 1);
      // pm10_avg = AVG(NULL) = NULL
      expect(rows[0]['pm10_avg'], isNull);
      // pm25_avg = 25.0
      expect((rows[0]['pm25_avg'] as num).toDouble(), closeTo(25.0, 0.01));
    });

    test('다른 측정소 데이터 제외', () async {
      final day = DateTime.now().subtract(const Duration(days: 1));
      final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      await db.insert('aqi_records', {
        'station_name': '부산',  // 다른 측정소
        'pm25_value': 50,
        'pm10_value': 100,
        'data_time': '${dayStr}T09:00:00',
        'fetched_at': '${dayStr}T09:00:00',
      });

      final rows = await getDailyAqiAverages(
        db,
        stationName: station, // '서울' 기준
        days: 7,
      );

      expect(rows.length, 0);
    });

    test('범위 밖 데이터 제외 — days=1이면 1일 전까지만', () async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      final oldStr = '${old.year}-${old.month.toString().padLeft(2, '0')}-${old.day.toString().padLeft(2, '0')}';

      await db.insert('aqi_records', {
        'station_name': station,
        'pm25_value': 40,
        'pm10_value': 80,
        'data_time': '${oldStr}T09:00:00',
        'fetched_at': '${oldStr}T09:00:00',
      });

      final rows = await getDailyAqiAverages(
        db,
        stationName: station,
        days: 3, // 3일 이내만 — 10일 전 데이터는 제외
      );

      expect(rows.length, 0);
    });
  });

  // ── 단계 1 신규: getLogsGroupedByDate 쿼리 검증 ─────────────

  group('getLogsGroupedByDate', () {
    late Database db;

    setUp(() async {
      db = await _openV4Db();
    });

    tearDown(() async {
      await db.close();
    });

    /// 헬퍼: getLogsGroupedByDate SQL 재현 (local_database.dart와 동일)
    Future<Map<String, List<NotificationLog>>> getLogsGroupedByDate(
      Database db, {
      int days = 7,
    }) async {
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

    test('날짜 그룹핑 정확성 — 서로 다른 날짜는 다른 그룹', () async {
      final day1 = DateTime.now().subtract(const Duration(days: 2));
      final day2 = DateTime.now().subtract(const Duration(days: 1));

      await db.insert('notification_logs', {
        'triggered_at': day1.toIso8601String(),
        'notification_type': 'dangerEntry',
        'pm25_value': 40,
        'user_action': 'maskWorn',
      });
      await db.insert('notification_logs', {
        'triggered_at': day2.toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 25,
        'user_action': 'none',
      });

      final grouped = await getLogsGroupedByDate(db, days: 7);

      expect(grouped.length, 2); // 2개 날짜 그룹
      final day1Key = day1.toIso8601String().substring(0, 10);
      final day2Key = day2.toIso8601String().substring(0, 10);
      expect(grouped[day1Key]?.length, 1);
      expect(grouped[day2Key]?.length, 1);
      expect(grouped[day1Key]!.first.userAction, UserAction.maskWorn);
    });

    test('같은 날짜 복수 로그 — 동일 그룹에 포함', () async {
      final day = DateTime.now().subtract(const Duration(days: 1));

      await db.insert('notification_logs', {
        'triggered_at':
            day.copyWith(hour: 9).toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 20,
        'user_action': 'none',
      });
      await db.insert('notification_logs', {
        'triggered_at':
            day.copyWith(hour: 18).toIso8601String(),
        'notification_type': 'evening',
        'pm25_value': 30,
        'user_action': 'maskWorn',
      });

      final grouped = await getLogsGroupedByDate(db, days: 7);
      final dayKey = day.toIso8601String().substring(0, 10);

      expect(grouped.length, 1); // 1개 날짜 그룹
      expect(grouped[dayKey]?.length, 2); // 같은 날 2개 로그
    });

    test('범위 밖 로그 제외 — days=7이면 7일 내만', () async {
      final old = DateTime.now().subtract(const Duration(days: 10));

      await db.insert('notification_logs', {
        'triggered_at': old.toIso8601String(),
        'notification_type': 'morning',
        'pm25_value': 20,
        'user_action': 'none',
      });

      final grouped = await getLogsGroupedByDate(db, days: 7);
      expect(grouped.isEmpty, true);
    });

    test('빈 DB → 빈 맵 반환', () async {
      final grouped = await getLogsGroupedByDate(db, days: 7);
      expect(grouped.isEmpty, true);
    });
  });
}
