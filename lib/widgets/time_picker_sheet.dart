import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_tokens.dart';
import '../core/constants/design_tokens.dart';

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
        color: DT.background,
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
              color: DT.text.withValues(alpha: 0.12),
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
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      color: DT.gray2,
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
                    color: DT.text,
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
          color: DT.text,
        ),
      ),
    );
  }
}
