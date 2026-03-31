import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  final _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _searching = false;
  bool _detecting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    final results = await ref.read(airKoreaServiceProvider).searchStations(value.trim());
    if (mounted) setState(() { _suggestions = results; _searching = false; });
  }

  Future<void> _selectStation(String name) async {
    _controller.text = name;
    setState(() { _suggestions = []; _errorMsg = null; });
    await ref.read(dustRepositoryProvider).changeStation(name);
    _goHome();
  }

  Future<void> _detectLocation() async {
    setState(() { _detecting = true; _suggestions = []; _errorMsg = null; });
    final station = await ref.read(dustRepositoryProvider).detectAndSaveStation();
    if (!mounted) return;
    if (station != null) {
      _goHome();
    } else {
      setState(() {
        _detecting = false;
        _errorMsg = '위치 감지에 실패했어요. 직접 입력해주세요.';
      });
    }
  }

  void _goHome() {
    ref.invalidate(dustDataProvider);
    ref.invalidate(tomorrowForecastProvider);
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _suggestions = []),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // 아이콘
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on, color: AppColors.primary, size: 34),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '내 지역을 설정해요',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '정확한 미세먼지 정보를 위해\n내가 있는 지역을 알려주세요.',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),

                // GPS 자동 감지 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _detecting ? null : _detectLocation,
                    icon: _detecting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(_detecting ? '위치 감지 중...' : '현재 위치로 자동 감지'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 구분선
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('또는', style: TextStyle(
                        fontSize: 13, color: AppColors.textHint)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                // 검색 입력
                TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: '지역명 검색 (예: 수원, 강남구)',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),

                // 자동완성 목록
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06),
                            blurRadius: 8, offset: const Offset(0, 4))
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined,
                            color: AppColors.primary, size: 20),
                        title: Text(_suggestions[i],
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textPrimary)),
                        onTap: () => _selectStation(_suggestions[i]),
                      ),
                    ),
                  ),

                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMsg!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.error)),
                ],

                const Spacer(),

                // 나중에 설정
                Center(
                  child: TextButton(
                    onPressed: _goHome,
                    child: const Text('나중에 설정하기',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
