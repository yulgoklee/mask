import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/location_stations.dart';
import '../../core/services/location_service.dart';
import '../../providers/providers.dart';

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
    if (widget.isOnboarding) {
      context.go('/notification_time');
    } else {
      Navigator.of(context).pop();
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
