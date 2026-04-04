import 'package:flutter_test/flutter_test.dart';
import 'package:mask_alert/core/services/notification_service.dart';

void main() {
  group('NotificationService - 오전 알림 메시지', () {
    test('KF94 마스크 권장 시 메시지 포함', () {
      final msg = NotificationService.morningMessage(
        80,
        '매우나쁨',
        riskLabel: '매우나쁨',
        maskType: 'KF94',
      );
      expect(msg, contains('KF94'));
      expect(msg, contains('PM2.5'));
      expect(msg, contains('80'));
    });

    test('KF80 마스크 권장 시 메시지 포함', () {
      final msg = NotificationService.morningMessage(
        45,
        '나쁨',
        riskLabel: '주의',
        maskType: 'KF80',
      );
      expect(msg, contains('KF80'));
    });

    test('마스크 불필요 시 외출 가능 문구 포함', () {
      final msg = NotificationService.morningMessage(
        10,
        '좋음',
        riskLabel: '안전',
        maskType: null,
      );
      expect(msg, contains('마스크 없이'));
    });

    test('maskType 없고 등급 나쁨 시 착용 권장 문구', () {
      final msg = NotificationService.morningMessage(45, '나쁨');
      expect(msg, contains('마스크를 착용'));
    });

    test('위험도 라벨 없어도 정상 동작', () {
      final msg = NotificationService.morningMessage(25, '보통');
      expect(msg, isNotEmpty);
      expect(msg, contains('PM2.5'));
    });
  });

  group('NotificationService - 예보 알림 메시지', () {
    test('내일 나쁨 → 마스크 챙기기 문구', () {
      final msg = NotificationService.forecastMessage(
        '나쁨',
        riskLabel: '주의',
      );
      expect(msg, contains('마스크를 꼭'));
      expect(msg, contains('나쁨'));
    });

    test('내일 좋음 → 외출 가능 문구', () {
      final msg = NotificationService.forecastMessage(
        '좋음',
        riskLabel: '안전',
      );
      expect(msg, contains('마스크 없이'));
    });

    test('내일 보통 → 외출 가능 문구', () {
      final msg = NotificationService.forecastMessage('보통');
      expect(msg, contains('마스크 없이'));
      expect(msg, contains('보통'));
    });

    test('내일 매우나쁨 → 마스크 챙기기 문구', () {
      final msg = NotificationService.forecastMessage('매우나쁨');
      expect(msg, contains('마스크를 꼭'));
    });
  });

  group('NotificationService - 귀가 알림 메시지', () {
    test('KF94 마스크 권장 시 귀가 문구 포함', () {
      final msg = NotificationService.eveningReturnMessage(
        '매우나쁨',
        riskLabel: '매우나쁨',
        maskType: 'KF94',
      );
      expect(msg, contains('귀가'));
      expect(msg, contains('KF94'));
    });

    test('등급 좋음 → 공기 괜찮음 문구', () {
      final msg = NotificationService.eveningReturnMessage(
        '좋음',
        riskLabel: '안전',
      );
      expect(msg, contains('괜찮아요'));
    });

    test('등급 나쁨 + maskType 없음 → 착용 권장 문구', () {
      final msg = NotificationService.eveningReturnMessage('나쁨');
      expect(msg, contains('마스크를 착용'));
    });

    test('현재 미세먼지 등급 항상 포함', () {
      final msg = NotificationService.eveningReturnMessage('보통');
      expect(msg, contains('현재 미세먼지'));
    });
  });
}
