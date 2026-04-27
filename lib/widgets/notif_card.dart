import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_tokens.dart';

// ══════════════════════════════════════════════════════════════
//  공용 알림 카드 위젯
// ══════════════════════════════════════════════════════════════

/// 알림 설정 카드 (토글 + 시간 표시 확장).
///
/// [onTimeTap]이 null이면 시간 선택 섹션을 표시하지 않는다 (실시간 경보 등).
/// [exampleText]가 null이면 예제 텍스트를 표시하지 않는다.
class NotifCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTimeTap;
  final String? exampleText;

  const NotifCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    this.onTimeTap,
    this.exampleText,
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

          // ── 시간 선택 영역 (활성 + onTimeTap 있을 때만) ──────
          if (enabled && onTimeTap != null) ...[
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
                padding: EdgeInsets.fromLTRB(16, 14, 16, exampleText != null ? 14 : 16),
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

          // ── 예제 텍스트 (활성 + exampleText 있을 때만) ────────
          if (enabled && exampleText != null) ...[
            if (onTimeTap == null)
              Divider(
                height: 1,
                color: accentColor.withValues(alpha: 0.2),
                indent: 16,
                endIndent: 16,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  exampleText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
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
//  Cupertino 드럼롤 시간 선택 바텀 시트
// ══════════════════════════════════════════════════════════════

/// 앱 톤앤매너에 맞는 Cupertino 드럼롤 시간 선택기를 보여주고
/// 선택된 [TimeOfDay]를 반환. 취소 시 null 반환.
Future<TimeOfDay?> showCupertinoTimePicker(
  BuildContext context, {
  required int hour,
  required int minute,
  required Color accentColor,
}) async {
  final int selectedPeriod = hour < 12 ? 0 : 1;
  final int selectedHour = hour % 12 == 0 ? 12 : hour % 12;
  final int selectedMinute = minute;

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
    _hour   = widget.initialHour;
    _minute = widget.initialMinute;

    _periodCtrl = FixedExtentScrollController(initialItem: _period);
    _hourCtrl   = FixedExtentScrollController(initialItem: _hour - 1);
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
    int h = _hour % 12;
    if (_period == 1) h += 12;
    return TimeOfDay(hour: h, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
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
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenH),
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
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker(
                        scrollController: _periodCtrl,
                        itemExtent: 44,
                        onSelectedItemChanged: (i) =>
                            setState(() => _period = i),
                        selectionOverlay: const SizedBox.shrink(),
                        children: ['오전', '오후']
                            .map((s) => _PickerItem(s))
                            .toList(),
                      ),
                    ),
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
                          (i) => _PickerItem('${i + 1}시'),
                        ),
                      ),
                    ),
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
                              '${i.toString().padLeft(2, '0')}분'),
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

          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  final String text;

  const _PickerItem(this.text);

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
