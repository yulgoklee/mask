import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../providers/providers.dart';

// ── 표시명 → 에어코리아 실측정소명 매핑 ──────────────────────────────
// key: 사용자에게 보이는 지역명
// value: 에어코리아 API stationName (API 직접 검증 완료)

const _sidoList = [
  '서울', '경기', '인천', '부산', '대구',
  '광주', '대전', '울산', '세종', '강원',
  '충북', '충남', '전북', '전남', '경북',
  '경남', '제주',
];

const _regionStations = <String, Map<String, String>>{
  '서울': {
    '강남구': '강남구', '강동구': '강동구', '강북구': '강북구', '강서구': '강서구',
    '관악구': '관악구', '광진구': '광진구', '구로구': '구로구', '금천구': '금천구',
    '노원구': '노원구', '도봉구': '도봉구', '동대문구': '동대문구', '동작구': '동작구',
    '마포구': '마포구', '서대문구': '서대문구', '서초구': '서초구', '성동구': '성동구',
    '성북구': '성북구', '송파구': '송파구', '양천구': '양천구', '영등포구': '영등포구',
    '용산구': '용산구', '은평구': '은평구', '종로구': '종로구', '중구': '중구', '중랑구': '중랑구',
  },
  '경기': {
    '고양': '행신동', '광주': '경안동', '김포': '사우동', '남양주': '금곡동',
    '부천': '중2동', '성남': '수내동', '수원': '인계동', '시흥': '정왕동',
    '안산': '고잔동', '안양': '안양8동', '용인': '수지', '의정부': '의정부동',
    '파주': '운정', '평택': '비전동', '하남': '미사', '화성': '동탄',
  },
  '인천': {
    '계양구': '계산', '부평구': '부평', '연수구': '동춘', '남동구': '구월동',
    '서구': '청라', '연수구(송도)': '송도',
  },
  '부산': {
    '중구': '광복동', '동래구': '온천동', '사하구': '감천동',
    '북구': '화명동', '해운대구': '우동',
  },
  '대구': {
    '중구': '수창동', '달서구': '이곡동', '수성구': '만촌동',
  },
  '광주': {
    '동구': '서석동', '서구': '치평동', '북구': '두암동',
    '광산구': '일곡동', '남구': '주월동',
  },
  '대전': {
    '동구': '대성동', '중구': '문창동', '서구': '둔산동',
    '유성구': '노은동', '대덕구': '읍내동',
  },
  '울산': {
    '남구': '무거동', '중구': '신정동', '북구': '농소동', '울주군': '삼남읍',
  },
  '세종': {
    '세종': '한솔동',
  },
  '강원': {
    '강릉': '옥천동', '원주': '반곡동(명륜동)', '춘천': '중앙동(강원)',
  },
  '충북': {
    '청주': '용담동', '충주': '칠금동',
  },
  '충남': {
    '아산': '모종동', '천안': '성성동',
  },
  '전북': {
    '익산': '모현동', '전주': '삼천동',
  },
  '전남': {
    '순천': '부흥동', '여수': '용당동',
  },
  '경북': {
    '경주': '성건동', '구미': '원평동', '안동': '중방동', '포항': '장흥동',
  },
  '경남': {
    '김해': '장유동', '진주': '상봉동', '창원': '명서동',
  },
  '제주': {
    '서귀포': '동홍동', '제주': '이도동',
  },
};

// ── 화면 ────────────────────────────────────────────────────────────

class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() =>
      _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  bool _detecting = false;
  String? _errorMsg;
  VoidCallback? _settingsAction;
  String? _selectedSido;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _manualSectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── GPS 자동 감지 ───────────────────────────────────────────────

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _errorMsg = null;
      _settingsAction = null;
    });

    final result =
        await ref.read(dustRepositoryProvider).detectAndSaveStation();
    if (!mounted) return;

    if (result.isSuccess) {
      _goHome();
      return;
    }

    String msg;
    VoidCallback? action;
    switch (result.error) {
      case LocationError.serviceDisabled:
        msg = 'GPS가 꺼져 있어요.\n위치 서비스를 켠 뒤 다시 시도해주세요.';
        action = () => ref.read(locationServiceProvider).openLocationSettings();
      case LocationError.permissionDeniedForever:
        msg = '위치 권한이 영구 거절되었어요.\n설정에서 허용한 뒤 다시 시도해주세요.';
        action = () => ref.read(locationServiceProvider).openAppSettings();
      case LocationError.permissionDenied:
        msg = '위치 권한을 허용해야 자동 감지가 가능해요.\n아래에서 지역을 직접 선택해주세요.';
        action = null;
      case LocationError.timeout:
        msg = '위치를 찾는 데 너무 오래 걸려요.\n아래에서 지역을 직접 선택해주세요.';
        action = null;
      default:
        msg = '위치 감지에 실패했어요.\n아래에서 지역을 직접 선택해주세요.';
        action = null;
    }

    setState(() {
      _detecting = false;
      _errorMsg = msg;
      _settingsAction = action;
      _selectedSido ??= '서울';
    });

    // GPS 거절 시 수동 선택 영역이 화면에 보이도록 자동 스크롤
    _scrollToManualSection();
  }

  void _scrollToManualSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _manualSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── 지역 직접 선택 ──────────────────────────────────────────────

  Future<void> _selectStation(String apiStationName) async {
    await ref.read(dustRepositoryProvider).changeStation(apiStationName);
    _goHome();
  }

  void _goHome() {
    ref.invalidate(dustDataProvider);
    ref.invalidate(tomorrowForecastProvider);
    if (Navigator.of(context).canPop()) {
      // 설정 화면에서 진입한 경우 → 뒤로
      Navigator.of(context).pop();
    } else {
      // 온보딩 플로우에서 진입한 경우 → 알림 시간 설정으로
      Navigator.of(context).pushReplacementNamed('/notification_time');
    }
  }

  // ── 빌드 ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(Icons.location_on,
                      color: AppColors.primary, size: 34),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '내 지역을 설정해요',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                '정확한 미세먼지 정보를 위해\n내가 있는 지역을 알려주세요.',
                style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── GPS 자동 감지 버튼 ──────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _detecting ? null : _detectLocation,
                  icon: _detecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(
                      _detecting ? '위치 감지 중...' : '현재 위치로 자동 감지'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // ── GPS 오류 메시지 ─────────────────────────────────
              if (_errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(_errorMsg!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        height: 1.4)),
                if (_settingsAction != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _settingsAction,
                      icon:
                          const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('설정 열기'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(
                            color: AppColors.textSecondary),
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 28),

              // ── 구분선 (GPS 거절 시 자동 스크롤 앵커) ──────────
              Row(key: _manualSectionKey, children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는 지역 직접 선택',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint)),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 24),

              // ── 시/도 선택 ──────────────────────────────────────
              const Text('시·도 선택',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sidoList.map((sido) {
                  final selected = _selectedSido == sido;
                  return GestureDetector(
                    onTap: () =>
                        setState(() {
                          _selectedSido = selected ? null : sido;
                        }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        sido,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ── 시/군/구 선택 ────────────────────────────────────
              if (_selectedSido != null) ...[
                const SizedBox(height: 24),
                Text(
                  '$_selectedSido 지역 선택',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_regionStations[_selectedSido!] ?? {})
                      .entries
                      .map((entry) {
                    return GestureDetector(
                      onTap: () => _selectStation(entry.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 36),
              Center(
                child: TextButton(
                  onPressed: _goHome,
                  child: const Text('나중에 설정하기',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
