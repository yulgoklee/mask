import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/core/services/location_service.dart';
import 'package:mask_alert/data/repositories/dust_repository.dart';
import 'package:mask_alert/features/location_setup/location_setup_screen.dart';
import 'package:mask_alert/features/settings/widgets/settings_drill_header.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/dust_providers.dart';

// ── Mock ─────────────────────────────────────────────────────

class MockDustRepository extends Mock implements DustRepository {}

// ── 헬퍼 ─────────────────────────────────────────────────────

late SharedPreferences _prefs;

/// GPS 감지가 즉시 실패하는 스텁 (manual phase 전환용)
MockDustRepository _mockRepoGpsFail(LocationError error) {
  final repo = MockDustRepository();
  when(() => repo.detectAndSaveStation())
      .thenAnswer((_) async => DetectStationResult.failure(error));
  return repo;
}

/// changeStation stub 추가
void _stubChangeStation(MockDustRepository repo) {
  when(() => repo.changeStation(any())).thenAnswer((_) async {});
}

Widget _buildApp({bool isOnboarding = false, required MockDustRepository repo}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      dustRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: LocationSetupScreen(isOnboarding: isOnboarding),
    ),
  );
}

/// detecting phase → manual phase 전환
///
/// initState: PostFrameCallback → 700ms delayed → _detectLocation()
/// pump(0ms): PostFrameCallback 실행
/// pump(700ms): delayed 실행
/// pump(): GPS future + setState 반영
/// pumpAndSettle: flutter_animate 애니메이션 타이머 소비
Future<void> _pumpToManual(WidgetTester tester) async {
  await tester.pump();                                   // PostFrameCallback
  await tester.pump(const Duration(milliseconds: 700)); // delayed
  await tester.pump();                                   // GPS future settle
  await tester.pumpAndSettle();                          // 애니메이션 타이머 소비
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a: 헤더 분기 ─────────────────────────────────────────────

  group('a: 헤더 분기', () {
    testWidgets('isOnboarding=false → SettingsDrillHeader "위치 설정"',
        (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.byType(SettingsDrillHeader), findsOneWidget);
      expect(find.text('위치 설정'), findsOneWidget);
    });

    testWidgets('isOnboarding=true → "거의 다 왔어요" 표시, SettingsDrillHeader 없음',
        (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(isOnboarding: true, repo: repo));
      await _pumpToManual(tester);

      expect(find.text('거의 다 왔어요'), findsOneWidget);
      expect(find.byType(SettingsDrillHeader), findsNothing);
    });

    testWidgets('구버전 온보딩 헤더 텍스트 없음', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.text('내 지역을 설정해요'), findsNothing);
    });
  });

  // ── b: detecting phase (상태 A) ───────────────────────────────

  group('b: detecting phase', () {
    testWidgets('초기 화면 — "내 동네를" Hero 표시', (tester) async {
      // GPS가 오래 걸리는 것처럼 Completer 사용
      final completer = Completer<DetectStationResult>();
      final repo = MockDustRepository();
      when(() => repo.detectAndSaveStation())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildApp(repo: repo));
      await tester.pump();                                   // PostFrameCallback
      await tester.pump(const Duration(milliseconds: 700)); // delayed 실행

      // GPS future 아직 미완료 → detecting phase
      expect(find.textContaining('내 동네를'), findsOneWidget);
      expect(find.text('잠시만 기다려주세요'), findsOneWidget);

      // 타이머 정리
      completer.complete(DetectStationResult.failure(LocationError.timeout));
      await tester.pump();
      await tester.pumpAndSettle();
    });

    testWidgets('detecting 중에 시도 칩 미표시', (tester) async {
      final completer = Completer<DetectStationResult>();
      final repo = MockDustRepository();
      when(() => repo.detectAndSaveStation())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildApp(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('서울'), findsNothing);

      completer.complete(DetectStationResult.failure(LocationError.timeout));
      await tester.pump();
      await tester.pumpAndSettle();
    });
  });

  // ── c: manual phase (상태 B) ──────────────────────────────────

  group('c: manual phase — 시도 칩', () {
    testWidgets('GPS 실패 후 시도 칩 표시 (서울·경기)', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.text('서울'), findsOneWidget);
      expect(find.text('경기'), findsOneWidget);
    });

    testWidgets('"내 위치로 찾기" 재시도 버튼 표시', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.timeout);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.text('내 위치로 찾기'), findsOneWidget);
    });

    testWidgets('오류 메시지 표시', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.textContaining('위치 권한이 필요해요'), findsOneWidget);
    });

    testWidgets('serviceDisabled → "설정 열기" 버튼 표시', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.serviceDisabled);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.text('설정 열기'), findsOneWidget);
    });

    testWidgets('permissionDenied → "설정 열기" 버튼 미표시', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.text('설정 열기'), findsNothing);
    });
  });

  // ── d: 구·군 칩 ───────────────────────────────────────────────

  group('d: 구·군 칩', () {
    testWidgets('서울 선택 시 구 칩 표시 (강남구)', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      await tester.tap(find.text('서울'));
      await tester.pump();

      expect(find.text('강남구'), findsOneWidget);
    });
  });

  // ── e: 나중에 설정하기 (isOnboarding=true + manual) ──────────

  group('e: 나중에 설정하기', () {
    testWidgets('isOnboarding=true + manual → 버튼 및 안내문 표시', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.timeout);
      _stubChangeStation(repo);
      await tester.pumpWidget(_buildApp(isOnboarding: true, repo: repo));
      await _pumpToManual(tester);

      expect(find.text('나중에 설정하기'), findsOneWidget);
      expect(find.text('서울 종로구로 시작해요'), findsOneWidget);
    });

    testWidgets('isOnboarding=false → 나중에 설정하기 미표시', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.timeout);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      expect(find.text('나중에 설정하기'), findsNothing);
    });
  });

  // ── f: SLabel 제거 확인 ───────────────────────────────────────

  group('f: SLabel 제거 — Text 위젯으로 대체', () {
    testWidgets('시·도 선택 Text 표시 (manual phase)', (tester) async {
      final repo = _mockRepoGpsFail(LocationError.permissionDenied);
      await tester.pumpWidget(_buildApp(repo: repo));
      await _pumpToManual(tester);

      // SLabel이 아닌 일반 Text로 "시·도 선택" 표시
      expect(find.text('시·도 선택'), findsOneWidget);
    });
  });
}
