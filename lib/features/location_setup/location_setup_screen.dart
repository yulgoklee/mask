import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/design_tokens.dart';
import '../../core/constants/location_stations.dart';
import '../../core/services/location_service.dart';
import '../../features/settings/widgets/settings_drill_header.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../onboarding/widgets/onboarding_background.dart';
import '../onboarding/widgets/onboarding_hero.dart';

// ── 상태 열거 ────────────────────────────────────────────────────────

enum LocationPhase { detecting, manual }

// ── 화면 ────────────────────────────────────────────────────────────

class LocationSetupScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;
  const LocationSetupScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<LocationSetupScreen> createState() =>
      _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  LocationPhase _phase = LocationPhase.detecting;
  String? _errorMsg;
  bool _settingsAction = false; // 영구 거절·서비스 꺼짐 시 "설정 열기" 표시
  String? _selectedSido;
  bool _saving = false; // 중복 탭 방지

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _detectLocation();
      });
    });
  }

  // ── GPS 자동 감지 ───────────────────────────────────────────────

  Future<void> _detectLocation() async {
    if (!mounted) return;
    setState(() {
      _phase = LocationPhase.detecting;
      _errorMsg = null;
      _settingsAction = false;
    });

    final result =
        await ref.read(dustRepositoryProvider).detectAndSaveStation();
    if (!mounted) return;

    if (result.isSuccess) {
      _goHome();
      return;
    }

    // 실패 분기
    String msg;
    bool settingsAction = false;
    switch (result.error) {
      case LocationError.serviceDisabled:
        msg = 'GPS가 꺼져 있어요.\n위치 서비스를 켜주시면 자동으로 찾아요.';
        settingsAction = true;
      case LocationError.permissionDeniedForever:
        msg = '위치 권한을 끄셨어요.\n설정에서 켜주시면 돼요.';
        settingsAction = true;
      case LocationError.permissionDenied:
        msg = '위치 권한이 필요해요.\n아래에서 지역을 직접 고를 수 있어요.';
      case LocationError.timeout:
        msg = '위치를 찾는 데 시간이 걸려요.\n직접 지역을 고를 수 있어요.';
      default:
        msg = '위치 감지에 실패했어요.\n아래에서 지역을 직접 골라주세요.';
    }

    setState(() {
      _phase = LocationPhase.manual;
      _errorMsg = msg;
      _settingsAction = settingsAction;
    });
  }

  // ── 홈 이동 ────────────────────────────────────────────────────

  void _goHome() {
    ref.invalidate(dustDataProvider);
    ref.invalidate(tomorrowForecastProvider);
    if (widget.isOnboarding) {
      context.go('/notification_time', extra: true);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── T2. 종로구 폴백 (치명적 버그 수정) ──────────────────────────

  Future<void> _goHomeWithFallback() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(dustRepositoryProvider).changeStation('종로구');
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

  Future<void> _selectStation(String apiStationName) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(dustRepositoryProvider).changeStation(apiStationName);
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

  void _openSettings() {
    ref.read(locationServiceProvider).openAppSettings();
  }

  // ── 빌드 ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── 상단 헤더 (isOnboarding 분기) ──
              if (widget.isOnboarding)
                _buildOnboardingTopBar()
              else
                SettingsDrillHeader(
                  title: '위치 설정',
                  onBack: () => context.pop(),
                ),

              // ── 본문 (AnimatedSwitcher) ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _phase == LocationPhase.detecting
                      ? const _DetectingView(key: ValueKey('detecting'))
                      : _ManualView(
                          key: const ValueKey('manual'),
                          errorMsg: _errorMsg,
                          settingsAction: _settingsAction,
                          selectedSido: _selectedSido,
                          onSidoChanged: (sido) =>
                              setState(() => _selectedSido = sido),
                          onStationSelected: _selectStation,
                          onRetryGps: _detectLocation,
                          onOpenSettings: _openSettings,
                        ),
                ),
              ),

              // ── 하단 CTA (isOnboarding && manual 시) ──
              if (widget.isOnboarding && _phase == LocationPhase.manual)
                _BottomCta(saving: _saving, onTap: _goHomeWithFallback),
            ],
          ),
        ),
      ),
    );
  }

  // ── T4. 온보딩 전용 상단 바 ────────────────────────────────────

  Widget _buildOnboardingTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: DT.text,
            ),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const Text(
            '거의 다 왔어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DT.gray,
            ),
          ),
        ],
      ),
    );
  }
}

// ── T5. Detecting 뷰 (상태 A) ────────────────────────────────────

class _DetectingView extends StatelessWidget {
  const _DetectingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          OnboardingHero(
            main: '내 동네를\n찾고 있어요',
            sub: '잠시만 기다려주세요',
            heroSize: 48,
          ),
          SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.location_on_outlined, size: 40, color: DT.primary),
                SizedBox(height: 20),
                SpinKitThreeBounce(size: 24, color: DT.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── T6. Manual 뷰 (상태 B) ───────────────────────────────────────

class _ManualView extends StatelessWidget {
  final String? errorMsg;
  final bool settingsAction;
  final String? selectedSido;
  final ValueChanged<String?> onSidoChanged;
  final ValueChanged<String> onStationSelected;
  final VoidCallback onRetryGps;
  final VoidCallback onOpenSettings;

  const _ManualView({
    super.key,
    required this.errorMsg,
    required this.settingsAction,
    required this.selectedSido,
    required this.onSidoChanged,
    required this.onStationSelected,
    required this.onRetryGps,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHero(
            main: '내 동네를\n직접 골라주세요',
            heroSize: 48,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Icon(Icons.location_on_outlined, size: 40, color: DT.primary),
          ),
          const SizedBox(height: 20),

          // ── 거절 사유 ──
          if (errorMsg != null) ...[
            Text(
              errorMsg!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DT.danger,
                height: 1.5,
              ),
            ),
            if (settingsAction) ...[
              const SizedBox(height: 8),
              AppButton.secondary(label: '설정 열기', onTap: onOpenSettings),
            ],
            const SizedBox(height: 20),
          ],

          // ── GPS 재시도 ──
          AppButton.secondary(
            label: '내 위치로 찾기',
            leading: const Icon(Icons.my_location, size: 18, color: DT.primary),
            onTap: onRetryGps,
          ),
          const SizedBox(height: 24),

          // ── 구분선 ──
          const Row(
            children: [
              Expanded(child: Divider(color: DT.border, height: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '또는 지역 직접 선택',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DT.gray,
                  ),
                ),
              ),
              Expanded(child: Divider(color: DT.border, height: 1)),
            ],
          ),
          const SizedBox(height: 20),

          // ── 시·도 선택 ──
          const Text(
            '시·도 선택',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DT.gray,
            ),
          ),
          const SizedBox(height: 12),
          _SidoChips(selected: selectedSido, onChanged: onSidoChanged),

          // ── 구·군 선택 ──
          if (selectedSido != null) ...[
            const SizedBox(height: 24),
            Text(
              '$selectedSido 지역 선택',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DT.gray,
              ),
            ),
            const SizedBox(height: 12),
            _GuChips(sido: selectedSido!, onSelected: onStationSelected),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── T7. 시·도 칩 ─────────────────────────────────────────────────

class _SidoChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SidoChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: locationSidoList.map((sido) {
        final isSelected = selected == sido;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : sido),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? DT.primary : DT.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? DT.primary : DT.border,
              ),
            ),
            child: Text(
              sido,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? DT.white : DT.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── T8. 구·군 칩 ─────────────────────────────────────────────────

class _GuChips extends StatelessWidget {
  final String sido;
  final ValueChanged<String> onSelected;

  const _GuChips({required this.sido, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final stations = locationRegionStations[sido] ?? {};

    if (stations.isEmpty) {
      return const Text(
        '이 지역은 측정소가 없어요',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: DT.gray2,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stations.entries.map((e) {
        return GestureDetector(
          onTap: () => onSelected(e.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: DT.white,
              border: Border.all(color: DT.border, width: 1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              e.key,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: DT.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── T9. 하단 CTA ─────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;

  const _BottomCta({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.text(
            label: '나중에 설정하기',
            onTap: saving ? null : onTap,
          ),
          const SizedBox(height: 4),
          const Text(
            '서울 종로구로 시작해요',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: DT.gray2,
            ),
          ),
        ],
      ),
    );
  }
}
