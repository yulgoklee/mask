import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/notification_setting.dart';
import '../../providers/providers.dart';

/// 위치 설정 이후 — 알림 시간 + 톤 설정 화면 (리디자인 v2)
class NotificationTimeScreen extends ConsumerWidget {
  const NotificationTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(notificationSettingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🔔', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '알림을 설정해드릴게요',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '원하는 알림만 켜두세요. 언제든 변경할 수 있어요.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── 알림 카드 목록 ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _NotifCard(
                      emoji: '🌅',
                      title: '외출 전 알림',
                      subtitle: '아침에 마스크 필요 여부를 알려드려요',
                      accentColor: const Color(0xFFF59E0B),
                      enabled: setting.morningAlertEnabled,
                      hour: setting.morningAlertHour,
                      minute: setting.morningAlertMinute,
                      onToggle: (v) => ref
                          .read(notificationSettingProvider.notifier)
                          .update(setting.copyWith(morningAlertEnabled: v)),
                      onTimeTap: () async {
                        final picked = await _showCupertinoTimePicker(
                          context,
                          hour: setting.morningAlertHour,
                          minute: setting.morningAlertMinute,
                          accentColor: const Color(0xFFF59E0B),
                        );
                        if (picked != null) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(setting.copyWith(
                                morningAlertHour: picked.hour,
                                morningAlertMinute: picked.minute,
                              ));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _NotifCard(
                      emoji: '🌙',
                      title: '전날 예보 알림',
                      subtitle: '내일 미세먼지를 미리 알려드려요',
                      accentColor: const Color(0xFF8B5CF6),
                      enabled: setting.eveningForecastEnabled,
                      hour: setting.eveningForecastHour,
                      minute: setting.eveningForecastMinute,
                      onToggle: (v) => ref
                          .read(notificationSettingProvider.notifier)
                          .update(setting.copyWith(eveningForecastEnabled: v)),
                      onTimeTap: () async {
                        final picked = await _showCupertinoTimePicker(
                          context,
                          hour: setting.eveningForecastHour,
                          minute: setting.eveningForecastMinute,
                          accentColor: const Color(0xFF8B5CF6),
                        );
                        if (picked != null) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(setting.copyWith(
                                eveningForecastHour: picked.hour,
                                eveningForecastMinute: picked.minute,
                              ));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _NotifCard(
                      emoji: '🏠',
                      title: '귀가 후 알림',
                      subtitle: '퇴근 시간대 미세먼지를 확인해드려요',
                      accentColor: const Color(0xFF10B981),
                      enabled: setting.eveningReturnEnabled,
                      hour: setting.eveningReturnHour,
                      minute: setting.eveningReturnMinute,
                      onToggle: (v) => ref
                          .read(notificationSettingProvider.notifier)
                          .update(setting.copyWith(eveningReturnEnabled: v)),
                      onTimeTap: () async {
                        final picked = await _showCupertinoTimePicker(
                          context,
                          hour: setting.eveningReturnHour,
                          minute: setting.eveningReturnMinute,
                          accentColor: const Color(0xFF10B981),
                        );
                        if (picked != null) {
                          ref
                              .read(notificationSettingProvider.notifier)
                              .update(setting.copyWith(
                                eveningReturnHour: picked.hour,
                                eveningReturnMinute: picked.minute,
                              ));
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 알림 톤 ───────────────────────────────
                    _VoiceSection(setting: setting, ref: ref),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── 하단 버튼 영역 ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.6),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _SimulationButton(setting: setting),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(profileRepositoryProvider)
                              .completeOnboarding();
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushReplacementNamed('/permission');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '설정 완료  →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Cupertino 드럼롤 시간 선택 바텀 시트
// ══════════════════════════════════════════════════════════════

/// 앱 톤앤매너에 맞는 Cupertino 드럼롤 시간 선택기를 보여주고
/// 선택된 [TimeOfDay]를 반환. 취소 시 null 반환.
Future<TimeOfDay?> _showCupertinoTimePicker(
  BuildContext context, {
  required int hour,
  required int minute,
  required Color accentColor,
}) async {
  // 초기 상태
  int selectedPeriod = hour < 12 ? 0 : 1; // 0=오전, 1=오후
  int selectedHour = hour % 12 == 0 ? 12 : hour % 12; // 1~12
  int selectedMinute = minute; // 0~59

  final result = await showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _CupertinoTimePickerSheet(
        initialPeriod: selectedPeriod,
        initialHour: selectedHour,
        initialMinute: selectedMinute,
        accentColor: accentColor,
      );
    },
  );

  return result;
}

// ──────────────────────────────────────────────────────────────
//  드럼롤 시트 위젯
// ──────────────────────────────────────────────────────────────

class _CupertinoTimePickerSheet extends StatefulWidget {
  final int initialPeriod;
  final int initialHour;
  final int initialMinute;
  final Color accentColor;

  const _CupertinoTimePickerSheet({
    required this.initialPeriod,
    required this.initialHour,
    required this.initialMinute,
    required this.accentColor,
  });

  @override
  State<_CupertinoTimePickerSheet> createState() =>
      _CupertinoTimePickerSheetState();
}

class _CupertinoTimePickerSheetState
    extends State<_CupertinoTimePickerSheet> {
  late int _period;
  late int _hour;   // 1~12
  late int _minute; // 0~59

  late final FixedExtentScrollController _periodCtrl;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _hour   = widget.initialHour;   // 1~12
    _minute = widget.initialMinute;

    _periodCtrl = FixedExtentScrollController(initialItem: _period);
    _hourCtrl   = FixedExtentScrollController(initialItem: _hour - 1); // 0-based
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    // 12시간 → 24시간 변환
    int h = _hour % 12; // 12시 → 0
    if (_period == 1) h += 12; // 오후
    return TimeOfDay(hour: h, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 핸들 ─────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── 헤더 ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  '알림 시각',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(_result),
                  child: Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 16,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 드럼롤 ────────────────────────────────────────
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 선택 영역 하이라이트
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                ),
                // 세 개의 피커 열
                Row(
                  children: [
                    // 오전/오후
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker(
                        scrollController: _periodCtrl,
                        itemExtent: 44,
                        onSelectedItemChanged: (i) =>
                            setState(() => _period = i),
                        selectionOverlay: const SizedBox.shrink(),
                        children: ['오전', '오후']
                            .map((s) => _PickerItem(s, accent))
                            .toList(),
                      ),
                    ),
                    // 시
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker(
                        scrollController: _hourCtrl,
                        itemExtent: 44,
                        onSelectedItemChanged: (i) =>
                            setState(() => _hour = i + 1),
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          12,
                          (i) => _PickerItem('${i + 1}시', accent),
                        ),
                      ),
                    ),
                    // 분
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker(
                        scrollController: _minuteCtrl,
                        itemExtent: 44,
                        onSelectedItemChanged: (i) =>
                            setState(() => _minute = i),
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          60,
                          (i) => _PickerItem(
                              '${i.toString().padLeft(2, '0')}분', accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 현재 선택값 미리보기 ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _period == 0 ? '오전' : '오후',
                  style: TextStyle(
                    fontSize: 14,
                    color: accent.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_hour시 ${_minute.toString().padLeft(2, '0')}분',
                  style: TextStyle(
                    fontSize: 22,
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── 하단 안전 영역 ────────────────────────────────
          SizedBox(
              height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// 드럼롤 각 항목 위젯
class _PickerItem extends StatelessWidget {
  final String text;

  const _PickerItem(this.text, [Color? accentColor]);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  알림 카드 (토글 + 시간 표시 확장)
// ══════════════════════════════════════════════════════════════

class _NotifCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _NotifCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    required this.onTimeTap,
  });

  String get _periodStr => hour < 12 ? '오전' : '오후';

  int get _displayHour {
    if (hour == 0) return 12;
    if (hour > 12) return hour - 12;
    return hour;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: enabled
            ? accentColor.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled ? accentColor.withValues(alpha: 0.4) : AppColors.divider,
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── 상단: 아이콘 + 텍스트 + 토글 ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: enabled
                        ? accentColor.withValues(alpha: 0.12)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 제목 + 부제목
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 토글
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: enabled,
                    onChanged: onToggle,
                    activeThumbColor: accentColor,
                    activeTrackColor: accentColor.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          // ── 시간 선택 영역 (활성 시만) ───────────────────────
          if (enabled) ...[
            Divider(
              height: 1,
              color: accentColor.withValues(alpha: 0.2),
              indent: 16,
              endIndent: 16,
            ),
            GestureDetector(
              onTap: onTimeTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '알림 시각',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // 시간 표시 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_periodStr ',
                            style: TextStyle(
                              fontSize: 12,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  알림 톤 섹션
// ══════════════════════════════════════════════════════════════

class _VoiceSection extends StatelessWidget {
  final NotificationSetting setting;
  final WidgetRef ref;

  const _VoiceSection({required this.setting, required this.ref});

  @override
  Widget build(BuildContext context) {
    const voices = [
      NotificationVoice.friendlyVoice,
      NotificationVoice.analyticalVoice,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '알림 문체',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Row(
          children: voices.map((v) {
            final selected = setting.notificationVoice == v;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: v == NotificationVoice.friendlyVoice ? 6 : 0,
                  left: v == NotificationVoice.analyticalVoice ? 6 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(notificationSettingProvider.notifier)
                        .update(setting.copyWith(notificationVoice: v));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.07)
                          : AppColors.surface,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          v.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          v.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.7)
                                : AppColors.textHint,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  알림 시뮬레이션 버튼
// ══════════════════════════════════════════════════════════════

class _SimulationButton extends ConsumerStatefulWidget {
  final NotificationSetting setting;

  const _SimulationButton({required this.setting});

  @override
  ConsumerState<_SimulationButton> createState() => _SimulationButtonState();
}

class _SimulationButtonState extends ConsumerState<_SimulationButton> {
  bool _loading = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: (_loading || _sent) ? null : _simulate,
        style: OutlinedButton.styleFrom(
          foregroundColor: _sent ? AppColors.success : AppColors.primary,
          side: BorderSide(
            color: _sent
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              Icon(
                _sent
                    ? Icons.check_circle_outline
                    : Icons.notifications_active_outlined,
                size: 18,
              ),
            const SizedBox(width: 8),
            Text(
              _sent
                  ? '알림을 보냈어요!'
                  : _loading
                      ? '전송 중...'
                      : '알림 미리 받아보기',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulate() async {
    setState(() => _loading = true);

    // 알림 권한 요청 (온보딩 중 신규 사용자는 아직 권한이 없음)
    final permStatus = await Permission.notification.request();

    if (!mounted) return;

    // 권한 거부 시 — 안내 스낵바 표시 후 종료
    if (permStatus.isDenied || permStatus.isPermanentlyDenied) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('알림 권한이 필요해요. 설정 앱에서 허용해주세요.'),
          action: permStatus.isPermanentlyDenied
              ? const SnackBarAction(
                  label: '설정 열기',
                  onPressed: openAppSettings,
                )
              : null,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      await service.showSimulationNotification(
        voice: widget.setting.notificationVoice.value,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _loading = false;
        _sent = true;
      });
    }
  }
}
