import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/services/notification_service.dart';
import 'package:mask_alert/data/models/user_profile.dart';

/// 테스트용 기본 프로필 (v2)
UserProfile _profile({
  String nickname = '',
  int respiratoryStatus = 0,
  int sensitivityLevel = 1,
}) =>
    UserProfile(
      nickname: nickname,
      birthYear: 1990,
      gender: 'male',
      respiratoryStatus: respiratoryStatus,
      sensitivityLevel: sensitivityLevel,
      isPregnant: false,
      recentSkinTreatment: false,
      outdoorMinutes: 1,
      activityTags: const [],
      discomfortLevel: 1,
    );

void main() {
  group('NotificationService - 아침 알림 (morningContent)', () {
    test('마스크 필요 시 제목에 이름 + 마스크 챙기세요 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(nickname: '지수'),
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
        profile: _profile(nickname: '지수'),
        pm25: 10,
        gradeName: '좋음',
        maskRequired: false,
        maskType: null,
      );
      expect(content.title, contains('없어도 돼요'));
    });

    test('이름 없을 때 제목에 님 포함', () {
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

    test('호흡기 질환 있을 때 본문에 기준 적용 문구 포함', () {
      final profile = _profile(nickname: '지수', respiratoryStatus: 1);
      final content = NotificationService.morningContent(
        profile: profile,
        pm25: 45,
        gradeName: '나쁨',
        maskRequired: true,
        maskType: 'KF80',
      );
      expect(content.body, isNotEmpty);
    });

    test('stateNote 있을 때 본문에 상태명 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(nickname: '지수'),
        pm25: 20,
        gradeName: '보통',
        maskRequired: true,
        maskType: 'KF94',
        stateNote: '임신 중',
      );
      expect(content.body, contains('임신 중'));
      expect(content.body, contains('KF94'));
    });

    test('stateOnlyMask=true 이면 제목에 🛡️ 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(nickname: '지수'),
        pm25: 10,
        gradeName: '좋음',
        maskRequired: true,
        maskType: 'KF80',
        stateNote: '피부 시술 후 회복',
        stateOnlyMask: true,
      );
      expect(content.title, contains('🛡️'));
      expect(content.title, contains('마스크 챙기세요'));
    });

    test('stateOnlyMask=false(공기 나쁨)이면 제목에 😷 포함', () {
      final content = NotificationService.morningContent(
        profile: _profile(nickname: '지수'),
        pm25: 40,
        gradeName: '나쁨',
        maskRequired: true,
        maskType: 'KF80',
        stateNote: '임신 중',
        stateOnlyMask: false,
      );
      expect(content.title, contains('😷'));
    });
  });

  group('NotificationService - 예보 알림 (forecastContent)', () {
    test('내일 나쁨 → 마스크 문구 포함', () {
      final content = NotificationService.forecastContent(
        profile: _profile(nickname: '지수'),
        tomorrowGrade: '나쁨',
      );
      expect(content.title, contains('마스크'));
      expect(content.body, contains('나쁨'));
    });

    test('내일 좋음 → 괜찮아요 포함', () {
      final content = NotificationService.forecastContent(
        profile: _profile(nickname: '지수'),
        tomorrowGrade: '좋음',
      );
      expect(content.title, contains('괜찮아요'));
      expect(content.body, contains('마스크 없이'));
    });

    test('stateNote + maskRequired override → 임신 문구 포함', () {
      final content = NotificationService.forecastContent(
        profile: _profile(nickname: '지수'),
        tomorrowGrade: '보통',
        maskRequired: true,
        maskType: 'KF94',
        stateNote: '임신 중',
        stateOnlyMask: true,
      );
      expect(content.title, contains('마스크 필요해요'));
      expect(content.body, contains('임신 중'));
      expect(content.body, contains('KF94'));
    });
  });

  group('NotificationService - 귀가 알림 (eveningReturnContent)', () {
    test('나쁨 + maskType → 챙기세요 + 타입 포함', () {
      final content = NotificationService.eveningReturnContent(
        profile: _profile(nickname: '지수'),
        gradeName: '매우나쁨',
        maskType: 'KF94',
      );
      expect(content.title, contains('챙기세요'));
      expect(content.body, contains('KF94'));
    });

    test('좋음 → 괜찮아요 + 수고 포함', () {
      final content = NotificationService.eveningReturnContent(
        profile: _profile(nickname: '지수'),
        gradeName: '좋음',
      );
      expect(content.title, contains('괜찮아요'));
      expect(content.body, contains('수고'));
    });

    test('stateNote 있으면 챙기세요 + 상태명 포함', () {
      final content = NotificationService.eveningReturnContent(
        profile: _profile(nickname: '지수'),
        gradeName: '좋음',
        stateNote: '피부 시술 후 회복',
        maskType: 'KF80',
      );
      expect(content.title, contains('챙기세요'));
      expect(content.body, contains('피부 시술 후 회복'));
    });
  });

  group('NotificationService - 실시간 급등 알림 (realtimeContent)', () {
    test('제목에 이름 + 나빠졌어요 포함', () {
      final content = NotificationService.realtimeContent(
        profile: _profile(nickname: '지수'),
        pm25: 72,
      );
      expect(content.title, contains('지수님'));
      expect(content.title, contains('나빠졌어요'));
      expect(content.body, contains('72'));
    });

    test('stateNote 있으면 본문에 상태명 + 즉시 포함', () {
      final content = NotificationService.realtimeContent(
        profile: _profile(nickname: '지수'),
        pm25: 90,
        stateNote: '임신 중',
      );
      expect(content.body, contains('임신 중'));
      expect(content.body, contains('즉시'));
    });
  });
}
