import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/constants/location_stations.dart';
import '../../core/services/location_service.dart';
import '../../features/settings/widgets/s_label.dart';
import '../../features/settings/widgets/settings_drill_header.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../onboarding/widgets/onboarding_background.dart';

// 공유 상수 별칭 (하위 호환)
const _sidoList = locationSidoList;
const _regionStations = locationRegionStations;

// ── 화면 ────────────────────────────────────────────────────────────

class LocationSetupScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;
  const LocationSetupScreen({super.key, this.isOnboarding = false});

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
        msg = 'GPS가 꺼져 있어요.\n위치 서비스를 켜주시면 자동으로 찾아드릴게요.';
        action = () => ref.read(locationServiceProvider).openLocationSettings();
      case LocationError.permissionDeniedForever:
        msg = '위치 권한이 영구 거절되었어요.\n설정에서 허용한 뒤 다시 시도해주세요.';
        action = () => ref.read(locationServiceProvider).openAppSettings();
      case LocationError.permissionDenied:
        msg = '위치 권한이 필요해요.\n아래에서 지역을 직접 선택하셔도 돼요.';
        action = null;
      case LocationError.timeout:
        msg = '위치를 찾는 데 시간이 걸려요.\n직접 지역을 선택해주셔도 괜찮아요.';
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
    if (widget.isOnboarding) {
      context.go('/notification_time', extra: true);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── 빌드 ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 ──────────────────────────────────────────────
              SettingsDrillHeader(
                title: '위치 설정',
                onBack: () => context.pop(),
              ),

              // ── 본문 (스크롤) ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── GPS 자동 감지 버튼 ────────────────────────
                    AppButton.secondary(
                      label: _detecting ? '위치 감지 중...' : '현재 위치로 자동 감지',
                      onTap: _detecting ? null : _detectLocation,
                      isLoading: _detecting,
                      leading: _detecting
                          ? null
                          : const Icon(Icons.my_location,
                              size: 18, color: DT.primary),
                    ),

                    // ── GPS 오류 메시지 ───────────────────────────
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Text(_errorMsg!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: DT.danger,
                              height: 1.4)),
                      if (_settingsAction != null) ...[
                        const SizedBox(height: 6),
                        AppButton.secondary(
                          label: '설정 열기',
                          onTap: _settingsAction,
                          leading: const Icon(Icons.settings_outlined,
                              size: 16, color: DT.primary),
                        ),
                      ],
                    ],

                    const SizedBox(height: 28),

                    // ── 구분선 (GPS 거절 시 자동 스크롤 앵커) ─────
                    Row(key: _manualSectionKey, children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('또는 지역 직접 선택',
                            style: TextStyle(
                                fontSize: 13, color: DT.gray2)),
                      ),
                      Expanded(child: Divider()),
                    ]),

                    // ── 시/도 선택 ───────────────────────────────
                    const SLabel('시·도 선택'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sidoList.map((sido) {
                        final selected = _selectedSido == sido;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedSido = selected ? null : sido;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected ? DT.primary : DT.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color:
                                    selected ? DT.primary : DT.border,
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
                                    ? DT.white
                                    : DT.text,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // ── 시/군/구 선택 ────────────────────────────
                    if (_selectedSido != null) ...[
                      SLabel('$_selectedSido 지역 선택'),
                      const SizedBox(height: 8),
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
                                color: DT.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: DT.border),
                              ),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                    fontSize: 14, color: DT.text),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 36),
                    Center(
                      child: AppButton.text(
                        label: '나중에 설정하기',
                        onTap: _goHome,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
