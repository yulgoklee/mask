import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/services/notification_service.dart';
import 'package:mask_alert/data/models/user_profile.dart';

/// 테스트용 기본 프로필
UserProfile _profile({String? name, SensitivityLevel sensitivity = SensitivityLevel.normal}) =>
    UserProfile(
      name: name,
      ageGroup: AgeGroup.thirties,
      hasCondition: false,
      activityLevel: ActivityLevel.normal,
      sensitivity: sensitivity,
    );

void main() {
  group('NotificationService - 아침 알림 (morningContent)', () {
    test('마스크 필요 시 제목에 이름 + 마스크 챙기세요 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(name: '지수'),
        pm25: 80,
        gradeName: '매우나쁨',
        maskRequired: true,
        maskType: 'KF94',
      );
      expect(content.title, contains('지수님'));
      expect(content.title, contains('마스크'));
      expect(content.body, contains('KF94'));
      expect(content.body, contains('PM2.5'));
      expect(content.body, contains('80'));
    });

    test('마스크 불필요 시 제목에 없어도 돼요 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(name: '지수'),
        pm25: 10,
        gradeName: '좋음',
        maskRequired: false,
        maskType: null,
      );
      expect(content.title, contains('없어도 돼요'));
    });

    test('이름 없을 때 제목에 님, 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(),
        pm25: 45,
        gradeName: '나쁨',
        maskRequired: true,
        maskType: 'KF80',
      );
      expect(content.title, contains('님'));
      expect(content.body, contains('KF80'));
    });

    test('기저질환 있을 때 본문에 기준 적용 문구 포함', () {
      final profile = UserProfile(
        name: '지수',
        ageGroup: AgeGroup.thirties,
        hasCondition: true,
        conditionType: ConditionType.respiratory,
        severity: Severity.mild,
        activityLevel: ActivityLevel.normal,
      );
      final content = NotificationService.morningContent(
        profile: profile,
        pm25: 45,
        gradeName: '나쁨',
        maskRequired: true,
        maskType: 'KF80',
      );
      expect(content.body, contains('호흡기 질환'));
    });
  });

  group('NotificationService - 예보 알림 (forecastContent)', () {
    test('내일 나쁨 → 제목에 마스크 필요해요 포함', () {
      final content = NotificationService.forecastContent(
        profile: _profile(name: '지수'),
        tomorrowGrade: '나쁨',
      );
      expect(content.title, contains('마스크'));
      expect(content.body, contains('나쁨'));
    });

    test('내일 좋음 → 제목에 괜찮아요 포함', () {
      final content = NotificationService.forecastContent(
        profile: _profile(name: '지수'),
        tomorrowGrade: '좋음',
      );
      expect(content.title, contains('괜찮아요'));
      expect(content.body, contains('마스크 없이'));
    });

    test('내일 매우나쁨 → 마스크 문구 포함', () {
      final content = NotificationService.forecastContent(
        profile: _profile(),
        tomorrowGrade: '매우나쁨',
      );
      expect(content.title, contains('마스크'));
    });
  });

  group('NotificationService - 귀가 알림 (eveningReturnContent)', () {
    test('등급 나쁨 + maskType → 제목에 챙기세요 + 본문에 마스크 타입 포함', () {
      final content = NotificationService.eveningReturnContent(
        profile: _profile(name: '지수'),
        gradeName: '매우나쁨',
        maskType: 'KF94',
      );
      expect(content.title, contains('챙기세요'));
      expect(content.body, contains('KF94'));
    });

    test('등급 좋음 → 제목에 괜찮아요 + 본문에 수고 문구', () {
      final content = NotificationService.eveningReturnContent(
        profile: _profile(name: '지수'),
        gradeName: '좋음',
      );
      expect(content.title, contains('괜찮아요'));
      expect(content.body, contains('수고'));
    });

    test('등급 나쁨 + maskType 없음 → 본문에 착용 권장', () {
      final content = NotificationService.eveningReturnContent(
        profile: _profile(),
        gradeName: '나쁨',
      );
      expect(content.body, contains('마스크 착용'));
    });
  });

  group('NotificationService - 실시간 급등 알림 (realtimeContent)', () {
    test('제목에 이름 + 나빠졌어요 포함', () {
      final content = NotificationService.realtimeContent(
        profile: _profile(name: '지수'),
        pm25: 72,
      );
      expect(content.title, contains('지수님'));
      expect(content.title, contains('나빠졌어요'));
      expect(content.body, contains('72'));
    });
  });
}
