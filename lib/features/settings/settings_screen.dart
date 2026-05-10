import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/design_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_providers.dart';
import 'widgets/s_cap.dart';
import 'widgets/s_dnd_child.dart';
import 'widgets/s_label.dart';
import 'widgets/s_item.dart';
import 'widgets/s_switch.dart';
import 'widgets/s_ext_icon.dart';

const _kPrivacyPolicyUrl = 'https://yulgoklee.github.io/mask/';
const _kHelpUrl = 'https://yulgoklee.github.io/mask/';
const _kContactEmail = 'mailto:leeyulgok96@gmail.com';
const _kGpsEnabledKey = 'gps_enabled';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _version;
  bool _gpsEnabled = true;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = '${info.version} (${info.buildNumber})';
        });
      }
    });
    _loadGpsPref();
  }

  Future<void> _loadGpsPref() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getBool(_kGpsEnabledKey) ?? true;
    if (mounted) setState(() => _gpsEnabled = val);
  }

  Future<void> _setGpsEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kGpsEnabledKey, val);
    if (mounted) setState(() => _gpsEnabled = val);
  }

  static Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String _fmtHour(int h) {
    final period = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display시';
  }

  // ── 알림 시간 포맷 ──────────────────────────────────────────

  String _fmtTime(int h, int m) {
    final period = h < 12 ? '오전' : '오후';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final dm = m == 0 ? '00분' : '$m분';
    return '$period $dh시 $dm';
  }

  // ── 캐시 삭제 다이얼로그 ────────────────────────────────────

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('저장된 AQI 기록을 삭제해요. 알림 기록은 유지돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final db = ref.read(localDatabaseProvider);
      await db.clearAqiRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AQI 캐시를 삭제했어요.')),
        );
      }
    }
  }

  // ── 데이터 초기화 다이얼로그 ───────────────────────────────

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text(
            '모든 설정, 건강 정보, 알림 기록이 삭제돼요.\n재설치와 동일한 상태가 돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: DT.danger),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final prefs = ref.read(sharedPreferencesProvider);
      final db = ref.read(localDatabaseProvider);
      await prefs.clear();
      await db.resetAll();
      if (mounted) {
        context.go('/splash');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifSetting = ref.watch(notificationSettingProvider);
    final notifNotifier = ref.read(notificationSettingProvider.notifier);

    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 back 버튼 (설정은 탭 밖 화면) ────────────
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: DT.background,
                border: Border(
                  bottom: BorderSide(color: DT.text.withValues(alpha: 0.06)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 44,
                      height: 52,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                          color: DT.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 본문 (스크롤) ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SCap(),

                    // ── 알림 ─────────────────────────────────
                    const SLabel('알림'),
                    SItem(
                      label: '외출 전 알림 시간',
                      value: notifSetting.morningAlertEnabled
                          ? _fmtTime(notifSetting.morningAlertHour,
                              notifSetting.morningAlertMinute)
                          : '꺼짐',
                      onClick: () => context.push('/notification_time'),
                    ),
                    SItem(
                      label: '전날 예보 알림 시간',
                      value: notifSetting.eveningForecastEnabled
                          ? _fmtTime(notifSetting.eveningForecastHour,
                              notifSetting.eveningForecastMinute)
                          : '꺼짐',
                      onClick: () => context.push('/notification_time'),
                    ),
                    SItem(
                      label: '귀가 후 알림 시간',
                      value: notifSetting.eveningReturnEnabled
                          ? _fmtTime(notifSetting.eveningReturnHour,
                              notifSetting.eveningReturnMinute)
                          : '꺼짐',
                      onClick: () => context.push('/notification_time'),
                    ),
                    SItem(
                      label: '실시간 경보',
                      trailing: SSwitch(
                        value: notifSetting.realtimeAlertEnabled,
                        onChange: (v) {
                          notifNotifier.update(
                            notifSetting.copyWith(realtimeAlertEnabled: v),
                          );
                        },
                      ),
                    ),
                    SItem(
                      label: '방해 금지 시간',
                      trailing: SSwitch(
                        value: notifSetting.quietHoursEnabled,
                        onChange: (v) {
                          notifNotifier.update(
                            notifSetting.copyWith(quietHoursEnabled: v),
                          );
                        },
                      ),
                    ),
                    // 방해 금지 시간 펼침 — quietHoursEnabled 시 자식 2개 표시
                    if (notifSetting.quietHoursEnabled) ...[
                      SDndChild(
                        child: SItem(
                          label: '시작 시간',
                          value: _fmtHour(notifSetting.quietHoursStartHour),
                          onClick: () => context.push('/notification_time'),
                        ),
                      ),
                      SDndChild(
                        child: SItem(
                          label: '종료 시간',
                          value: _fmtHour(notifSetting.quietHoursEndHour),
                          onClick: () => context.push('/notification_time'),
                          last: true,
                        ),
                      ),
                    ],
                    SItem(
                      label: '알림 미리 받아보기',
                      onClick: () => context.push('/notification_time'),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 진단 ─────────────────────────────────
                    const SLabel('진단'),
                    SItem(
                      label: '건강 정보 수정',
                      onClick: () => context.push('/profile/edit'),
                    ),
                    SItem(
                      label: '재진단 받기',
                      onClick: () => context.push('/onboarding?rediag=true'),
                    ),
                    SItem(
                      label: '결과지 다시 보기',
                      onClick: () => context.push('/diagnosis_result'),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 위치 ─────────────────────────────────
                    const SLabel('위치'),
                    SItem(
                      label: '위치 설정',
                      onClick: () =>
                          context.push('/location_setup', extra: false),
                    ),
                    SItem(
                      label: 'GPS 사용',
                      trailing: SSwitch(
                        value: _gpsEnabled,
                        onChange: _setGpsEnabled,
                      ),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 데이터 ───────────────────────────────
                    const SLabel('데이터'),
                    SItem(
                      label: '캐시 삭제',
                      onClick: _showClearCacheDialog,
                    ),
                    SItem(
                      label: '데이터 초기화',
                      onClick: _showResetDialog,
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 투명성 ───────────────────────────────
                    const SLabel('투명성'),
                    SItem(
                      label: '참고 자료·가이드라인',
                      onClick: () =>
                          context.push('/settings/transparency/sources'),
                    ),
                    SItem(
                      label: '데이터 처리 방식 (T_final)',
                      onClick: () =>
                          context.push('/settings/transparency/calculation'),
                    ),
                    SItem(
                      label: '한계와 책임',
                      onClick: () =>
                          context.push('/settings/transparency/limits'),
                    ),
                    SItem(
                      label: '의료도구 면책',
                      onClick: () =>
                          context.push('/settings/transparency/disclaimer'),
                      last: true,
                    ),
                    const Divider(height: 1, color: DT.border),

                    // ── 앱 정보 ──────────────────────────────
                    const SLabel('앱 정보'),
                    SItem(
                      label: '버전 정보',
                      value: _version ?? '',
                    ),
                    SItem(
                      label: '개인정보처리방침',
                      trailing: const SExtIcon(),
                      onClick: () => _launch(_kPrivacyPolicyUrl),
                    ),
                    SItem(
                      label: '이용약관',
                      trailing: const SExtIcon(),
                      onClick: () => _launch(_kPrivacyPolicyUrl),
                    ),
                    SItem(
                      label: '오픈소스 라이선스',
                      onClick: () => showLicensePage(context: context),
                    ),
                    SItem(
                      label: '도움말',
                      trailing: const SExtIcon(),
                      onClick: () => _launch(_kHelpUrl),
                    ),
                    SItem(
                      label: '문의',
                      trailing: const SExtIcon(),
                      onClick: () => _launch(_kContactEmail),
                      last: true,
                    ),

                    const SizedBox(height: 36),
                    const Text(
                      '내 몸에 맞는 미세먼지 알림',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: DT.gray2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
