import 'package:flutter/material.dart';
import 'app_colors.dart';

class DustStandards {
  static const int pm25Good   = 15;
  static const int pm25Normal = 35;
  static const int pm25Bad    = 75;

  static const int pm10Good   = 30;
  static const int pm10Normal = 80;
  static const int pm10Bad    = 150;

  static DustGrade getPm25Grade(int value) {
    if (value <= pm25Good)   return DustGrade.good;
    if (value <= pm25Normal) return DustGrade.normal;
    if (value <= pm25Bad)    return DustGrade.bad;
    return DustGrade.veryBad;
  }

  static DustGrade getPm10Grade(int value) {
    if (value <= pm10Good)   return DustGrade.good;
    if (value <= pm10Normal) return DustGrade.normal;
    if (value <= pm10Bad)    return DustGrade.bad;
    return DustGrade.veryBad;
  }

  static DustGrade worstGrade(DustGrade a, DustGrade b) =>
      a.index > b.index ? a : b;
}

enum DustGrade {
  good,
  normal,
  bad,
  veryBad;

  String get label {
    const labels = ['좋음', '보통', '나쁨', '매우나쁨'];
    return labels[index];
  }

  String get emoji {
    const emojis = ['😊', '🙂', '😷', '🚨'];
    return emojis[index];
  }

  /// 등급별 색상 (AppColors에서 중앙 관리)
  Color get color {
    switch (this) {
      case DustGrade.good:    return AppColors.dustGood;
      case DustGrade.normal:  return AppColors.dustNormal;
      case DustGrade.bad:     return AppColors.dustBad;
      case DustGrade.veryBad: return AppColors.dustVeryBad;
    }
  }

  String get advice {
    switch (this) {
      case DustGrade.good:
        return '공기가 맑아요. 야외 활동하기 좋은 날이에요.';
      case DustGrade.normal:
        return '보통 수준이에요. 민감한 분들은 주의하세요.';
      case DustGrade.bad:
        return '미세먼지가 나빠요. 외출 시 마스크를 착용하세요.';
      case DustGrade.veryBad:
        return '매우 나쁨이에요. 가급적 외출을 자제하세요.';
    }
  }

  /// 문자열 → DustGrade 변환 ("좋음", "보통", "나쁨", "매우나쁨")
  static DustGrade? fromString(String? s) {
    switch (s?.trim()) {
      case '좋음':    return DustGrade.good;
      case '보통':    return DustGrade.normal;
      case '나쁨':    return DustGrade.bad;
      case '매우나쁨': return DustGrade.veryBad;
      default:       return null;
    }
  }
}
