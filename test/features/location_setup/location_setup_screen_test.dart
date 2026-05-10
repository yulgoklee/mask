import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mask_alert/data/repositories/dust_repository.dart';
import 'package:mask_alert/features/location_setup/location_setup_screen.dart';
import 'package:mask_alert/features/settings/widgets/s_label.dart';
import 'package:mask_alert/features/settings/widgets/settings_drill_header.dart';
import 'package:mask_alert/providers/core_providers.dart';
import 'package:mask_alert/providers/dust_providers.dart';

// ── Mock ─────────────────────────────────────────────────────

class MockDustRepository extends Mock implements DustRepository {}

// ── 헬퍼 ─────────────────────────────────────────────────────

late SharedPreferences _prefs;

Widget _buildApp({bool isOnboarding = false}) {
  final mockRepo = MockDustRepository();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      dustRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp(
      home: LocationSetupScreen(isOnboarding: isOnboarding),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ── a: SettingsDrillHeader ────────────────────────────────

  group('a: SettingsDrillHeader 헤더', () {
    testWidgets('"위치 설정" 타이틀 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(SettingsDrillHeader), findsOneWidget);
      expect(find.text('위치 설정'), findsOneWidget);
    });

    testWidgets('기존 온보딩 스타일 대제목 아이콘 없음', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      // 구버전 온보딩 헤더 텍스트 없음
      expect(find.text('내 지역을 설정해요'), findsNothing);
    });
  });

  // ── b: SLabel 섹션 라벨 ───────────────────────────────────

  group('b: SLabel 섹션 라벨 표시', () {
    testWidgets('시·도 선택 SLabel 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final sLabels = tester.widgetList<SLabel>(find.byType(SLabel));
      final texts = sLabels.map((w) => w.text).toSet();

      expect(texts, contains('시·도 선택'));
    });
  });

  // ── c: GPS 버튼 표시 ──────────────────────────────────────

  group('c: GPS 자동 감지 버튼', () {
    testWidgets('"현재 위치로 자동 감지" 버튼 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('현재 위치로 자동 감지'), findsOneWidget);
    });
  });

  // ── d: 시·도 칩 Wrap 유지 (D-5) ──────────────────────────

  group('d: D-5 시·도 칩 Wrap 표시', () {
    testWidgets('서울·경기 등 시도 칩 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      // 시도 칩이 텍스트로 표시됨
      expect(find.text('서울'), findsOneWidget);
      expect(find.text('경기'), findsOneWidget);
    });
  });

  // ── e: 나중에 설정하기 버튼 ───────────────────────────────

  group('e: 나중에 설정하기', () {
    testWidgets('"나중에 설정하기" 버튼 표시', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('나중에 설정하기'), findsOneWidget);
    });
  });

  // ── f: isOnboarding 분기 ─────────────────────────────────

  group('f: isOnboarding 파라미터 공통 헤더', () {
    testWidgets('isOnboarding=true에서도 동일 헤더 표시', (tester) async {
      await tester.pumpWidget(_buildApp(isOnboarding: true));
      await tester.pump();

      expect(find.text('위치 설정'), findsOneWidget);
      expect(find.byType(SettingsDrillHeader), findsOneWidget);
    });
  });
}
