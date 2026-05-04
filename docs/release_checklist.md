# 출시 체크리스트

> 최종 갱신: 2026-05-05 | 대상: mask_alert Android Play Store 출시
> 사이클 #3 (출시 준비) 시점 기준.

---

## 1. 버전 정보 (`pubspec.yaml`)

`build.gradle.kts`는 `flutter.versionCode` / `flutter.versionName`을 사용 → 실제 값은 `pubspec.yaml`의 `version` 필드.

| 항목 | 현재 값 |
|---|---|
| pubspec.yaml version | `1.0.5+8` |
| versionName (Play Store 표시) | `1.0.5` |
| versionCode (정수 빌드 번호) | `8` |

- ✅ 1.0.4+6 → 1.0.5+8로 갱신됨 (사이클 #1·#2 진행 중 +1, +2 증가).
- 출시 직전 빌드 번호 한 번 더 올림 권장 (예: +9). versionCode는 이전 출시보다 무조건 커야 함.

---

## 2. SDK 버전 (`android/app/build.gradle.kts`)

`minSdk`, `targetSdk`, `compileSdk` 모두 Flutter SDK 기본값 위임(`flutter.*`).

| 항목 | 현재 값 | Play Store 요건 (2026) |
|---|---|---|
| minSdkVersion | 24 (Android 7.0) | 제한 없음 |
| targetSdkVersion | **36** | **35 이상 필수** |
| compileSdkVersion | 36 | — |

- ✅ targetSdk 36 — 2026년 Play Store 기준(35+) 충족.

---

## 3. ProGuard/R8 — Crashlytics 매핑 파일 업로드

`build.gradle.kts` 플러그인 선언:
```
id("com.google.firebase.crashlytics")
```

- ✅ Crashlytics Gradle 플러그인이 릴리스 빌드 시 R8 매핑 파일을 Firebase에 자동 업로드. 별도 설정 불필요.

---

## 4. 서명 키 (`android/key.properties`) ⚠️ **사용자 액션 필요**

**현재 상태**: ❌ `android/key.properties` 없음. `*.jks`/`*.keystore` 파일도 없음.

**필요 작업** (사용자가 직접):

1. **Keystore 생성** (한 번만, 평생 보관):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
- 비밀번호 설정 (잊지 말 것)
- 안전한 곳에 백업 (분실 시 같은 앱으로 업데이트 불가)

2. **`android/key.properties` 작성** (gitignore 대상):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/iyulgog/upload-keystore.jks
```

3. **검증**:
```bash
flutter build appbundle --release
```
서명된 AAB가 `build/app/outputs/bundle/release/app-release.aab`에 생성되면 성공.

**대안**: Play App Signing (Google이 키 관리). 첫 출시 때만 upload key 필요. 이후 분실 시 Google 통해 재발급 가능.

---

## 5. AndroidManifest.xml 권한 목록

파일: `android/app/src/main/AndroidManifest.xml`

| 권한 | 용도 | 상태 |
|---|---|---|
| `INTERNET` | API 호출, Firebase | ✅ |
| `ACCESS_FINE_LOCATION` | GPS 위치 감지 | ✅ |
| `ACCESS_COARSE_LOCATION` | 대략 위치 | ✅ |
| `ACCESS_BACKGROUND_LOCATION` | 백그라운드 위치 | ✅ 명시적 제거 (`tools:node="remove"`) |
| `POST_NOTIFICATIONS` | 알림 (Android 13+) | ✅ |
| `RECEIVE_BOOT_COMPLETED` | 기기 재시작 후 알림 복구 | ✅ |
| `WAKE_LOCK` | 백그라운드 작업 | ✅ |
| `FOREGROUND_SERVICE` | WorkManager foreground | ✅ |

- ✅ 백그라운드 위치 권한이 명시적으로 제거되어 있어 Play Store 심사 위험 없음.

---

## 6. 개인정보처리방침 URL

- Play Store 등록 URL: `https://yulgoklee.github.io/mask/`
- 파일 위치: `docs/privacy-policy.html` (GitHub Pages 서빙)
- ✅ HTTP 200 응답 확인 (2026-05-05 검증)

---

## 7. 앱 아이콘 (`android/app/src/main/res/`)

| 폴더 | 파일 | 상태 |
|---|---|---|
| `mipmap-mdpi` | `ic_launcher.png` | ✅ |
| `mipmap-hdpi` | `ic_launcher.png` | ✅ |
| `mipmap-xhdpi` | `ic_launcher.png` | ✅ |
| `mipmap-xxhdpi` | `ic_launcher.png` | ✅ |
| `mipmap-xxxhdpi` | `ic_launcher.png` | ✅ |
| `mipmap-anydpi-v26` | `ic_launcher.xml` + `ic_launcher_round.xml` | ✅ |

- ✅ Android 8+ 적응형 아이콘 모두 생성됨.
- 재생성 필요 시: `flutter pub run flutter_launcher_icons` (pubspec에 `flutter_launcher_icons` 설정 있음).

---

## 8. assets / pubspec 정리

- ✅ `assets/images/` 빈 디렉토리 라인 제거 (사이클 #3, 2026-05-05).
- ✅ `assets/icon/app_icon.png` — flutter_launcher_icons용으로 사용 중.

---

## 9. 출시용 AAB 빌드

```bash
flutter build appbundle --release
```

- 출력 경로: `build/app/outputs/bundle/release/app-release.aab`
- Play Console에서 해당 `.aab` 업로드.
- ⚠️ **§4 서명 키 셋업 후에만 가능**. 현재는 서명 없이 빌드되어 Play Console 업로드 불가.

---

## 10. 출시 직전 마지막 점검 (Day 0)

서명 키 셋업 완료 후 출시 전 확인:

- [ ] `pubspec.yaml` version 한 번 더 +1 (예: 1.0.5+9)
- [ ] `flutter analyze` 0 errors
- [ ] `flutter test` 모두 통과
- [ ] 디바이스 검수 — 신규 유저 흐름 끝-끝 (스플래시 → 환영 → 온보딩 → 결과지 → 위치 → 알림시간 → 권한 → 완료 → 케어 탭)
- [ ] `flutter build appbundle --release` 성공
- [ ] Play Console 업로드
- [ ] 내부 테스트 트랙으로 먼저 배포 → 본인 단말 설치 확인
- [ ] 본 트랙 출시

---

## 11. 출시 후 1~2주 모니터링

- Firebase Crashlytics — 크래시 발생 모니터링
- Firebase Analytics — 신규 유저 진입 / 알림 발송 / 마스크 챙김 액션 등 이벤트
- Play Console — 설치 / 평점 / 리뷰

문제 발견 시 사이클 #4 (출시 후 정리)에서 핫픽스.
