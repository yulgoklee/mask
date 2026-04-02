# 마스크 알림 (Mask Alert)

> 내 건강 상태에 맞는 개인화 미세먼지 알림 앱

한국환경공단 에어코리아 실시간 데이터를 기반으로, 나이·기저질환·활동량에 따라 미세먼지 위험도와 마스크 착용 여부를 알려주는 Flutter 앱입니다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 🌍 실시간 미세먼지 | PM10 / PM2.5 실시간 측정값 (에어코리아 API) |
| 👤 개인화 위험도 | 나이·기저질환·활동량 기반 맞춤 위험등급 |
| 😷 마스크 추천 | 위험도에 따라 KF80 / KF94 / 착용 불필요 안내 |
| 🔔 스마트 알림 | 외출 전 / 귀가 / 전날 예보 / 실시간 경보 (4종) |
| 📊 24시간 현황 | 현재 기준 +24시간 예보 |
| 📅 단기 예보 | 에어코리아 3일 예보 (오늘·내일·모레) |
| 📍 위치 자동 감지 | GPS 기반 가장 가까운 측정소 자동 선택 |

---

## 시작하기

### 1. 사전 준비

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치 (`>=3.0.0`)
- [에어코리아 API 키](#api-키-발급) 발급

### 2. 클론 & 의존성 설치

```bash
git clone https://github.com/yulgoklee/mask.git
cd mask
flutter pub get
```

### 3. API 키 설정

```bash
# 예시 파일을 복사
cp lib/core/config/app_config.dart.example lib/core/config/app_config.dart
```

`lib/core/config/app_config.dart` 파일을 열어 키를 입력합니다:

```dart
class AppConfig {
  static const String airKoreaApiKey = 'YOUR_ENCODED_API_KEY_HERE';
}
```

> ⚠️ `app_config.dart`는 `.gitignore`에 포함되어 있습니다. 절대 커밋하지 마세요.

### 4. 실행

```bash
flutter run
```

---

## API 키 발급

1. [공공데이터포털](https://www.data.go.kr) 접속 및 회원가입
2. **"한국환경공단_에어코리아_대기오염정보"** 검색
3. 활용신청 → 승인 후 **일반 인증키(Encoding)** 복사
4. `app_config.dart`에 붙여넣기

> 승인은 즉시~수 분 내 자동 승인됩니다.

---

## 기술 스택

| 분류 | 라이브러리 |
|------|-----------|
| 상태관리 | flutter_riverpod ^2.5.1 |
| 네트워크 | dio ^5.4.3 |
| 로컬 저장 | shared_preferences ^2.2.3 |
| 알림 | flutter_local_notifications ^17.2.2 |
| 백그라운드 | workmanager ^0.9.0 |
| 위치 | geolocator ^13.0.1 |
| 광고 | google_mobile_ads ^5.1.0 |
| 권한 | permission_handler ^11.3.1 |

---

## 프로젝트 구조

```
lib/
├── core/
│   ├── config/          # API 키 등 설정 (app_config.dart는 gitignored)
│   ├── constants/       # 색상, 미세먼지 기준값
│   ├── services/        # AirKorea API, 알림, 위치, 백그라운드
│   └── utils/           # 먼지 계산기, 날짜 유틸
├── data/
│   ├── models/          # DustData, UserProfile, HourlyDustData 등
│   └── repositories/    # DustRepository, ProfileRepository
├── features/
│   ├── home/                  # 홈 화면, 위험도 카드, 상세 화면
│   ├── onboarding/            # 5단계 온보딩
│   ├── profile/               # 건강 프로필 편집
│   ├── notification_setting/  # 알림 시간·종류 설정
│   ├── info/                  # 미세먼지 정보 (AdMob)
│   ├── location_setup/        # GPS 기반 측정소 선택
│   ├── splash/                # 스플래시 화면
│   └── tutorial/              # 최초 실행 튜토리얼
├── providers/           # Riverpod 프로바이더
└── widgets/             # DustGaugeWidget, GradeBadge 등
```

---

## AdMob 설정

광고 코드는 현재 **비활성화** 상태입니다 (`ad_banner_widget.dart`가 빈 위젯 반환). 출시 전 아래 순서로 활성화하세요.

1. `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID` 실제 ID로 교체
2. `ios/Runner/Info.plist` → `GADApplicationIdentifier` 실제 ID로 교체
3. `lib/widgets/ad_banner_widget.dart` → 주석 해제 후 배너 Unit ID 입력

---

## 개인정보처리방침

앱 배포에 필요한 개인정보처리방침은 GitHub Pages로 제공됩니다.

- URL: `https://yulgoklee.github.io/mask/`
- 파일 위치: `docs/privacy-policy.html`

> Play Store / App Store 제출 시 위 URL을 개인정보처리방침 링크로 입력하세요.

---

## 데이터 출처

- 실시간 측정 데이터: [한국환경공단 에어코리아](https://www.airkorea.or.kr)
- API: [공공데이터포털 에어코리아 대기오염정보](https://www.data.go.kr/data/15073861/openapi.do)

---

## 라이선스

MIT License
