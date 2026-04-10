import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/temporary_state.dart';
import '../../data/models/today_situation.dart';
import '../../providers/providers.dart';

class MyStateScreen extends ConsumerWidget {
  const MyStateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporaryStates = ref.watch(temporaryStatesProvider);
    final todaySituation = ref.watch(todaySituationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '내 현재 상태',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── 안내 문구 ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛡️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '현재 상태를 알려주시면 나에게 맞는\n마스크 기준을 적용해 드려요.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 오늘의 상황 (Tier 3) ──────────────────────────
          _SectionHeader(
            title: '오늘의 상황',
            subtitle: '오늘 하루만 적용돼요',
          ),
          const SizedBox(height: 10),
          ...TodaySituationType.values.map((type) {
            final isActive = todaySituation?.isActive == true &&
                todaySituation?.type == type;
            return _TodaySituationTile(
              type: type,
              isActive: isActive,
              onToggle: (active) async {
                if (active) {
                  await ref
                      .read(todaySituationProvider.notifier)
                      .set(type);
                } else {
                  await ref
                      .read(todaySituationProvider.notifier)
                      .clear();
                }
              },
            );
          }),
          const SizedBox(height: 28),

          // ── 기간 상태 (Tier 2) ────────────────────────────
          _SectionHeader(
            title: '기간 상태',
            subtitle: '만료일까지 자동으로 기준이 달라져요',
          ),
          const SizedBox(height: 10),

          // 활성 기간 상태 목록
          if (temporaryStates.isNotEmpty) ...[
            ...temporaryStates.map((state) => _ActiveStateTile(
                  state: state,
                  onRemove: () async {
                    await ref
                        .read(temporaryStatesProvider.notifier)
                        .remove(state.type);
                  },
                )),
            const SizedBox(height: 12),
          ],

          // 추가 가능한 상태 목록
          ...TemporaryStateType.values
              .where((t) =>
                  !temporaryStates.any((s) => s.type == t && s.isActive))
              .map((type) => _AddStateTile(
                    type: type,
                    onAdd: () => _showAddStateSheet(context, ref, type),
                  )),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAddStateSheet(
      BuildContext context, WidgetRef ref, TemporaryStateType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStateSheet(type: type, ref: ref),
    );
  }
}

// ── 섹션 헤더 ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── 오늘의 상황 타일 ───────────────────────────────────────

class _TodaySituationTile extends StatelessWidget {
  final TodaySituationType type;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _TodaySituationTile({
    required this.type,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          type.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          type.description,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: onToggle,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }
}

// ── 활성 기간 상태 타일 ────────────────────────────────────

class _ActiveStateTile extends StatelessWidget {
  final TemporaryState state;
  final VoidCallback onRemove;

  const _ActiveStateTile({required this.state, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final expiryText = state.expiryDate != null
        ? '${state.expiryDate!.month}/${state.expiryDate!.day}까지'
        : '수동 해제 전까지';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.primary, size: 18),
        ),
        title: Text(
          state.type.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.schedule, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              expiryText,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
          onPressed: () => _confirmRemove(context),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('상태 해제'),
        content: Text('${state.type.label} 상태를 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── 추가 가능한 상태 타일 ──────────────────────────────────

class _AddStateTile extends StatelessWidget {
  final TemporaryStateType type;
  final VoidCallback onAdd;

  const _AddStateTile({required this.type, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          type.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          type.description,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: GestureDetector(
          onTap: onAdd,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '추가',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 기간 상태 추가 바텀시트 ────────────────────────────────

class _AddStateSheet extends ConsumerStatefulWidget {
  final TemporaryStateType type;
  final WidgetRef ref;

  const _AddStateSheet({required this.type, required this.ref});

  @override
  ConsumerState<_AddStateSheet> createState() => _AddStateSheetState();
}

class _AddStateSheetState extends ConsumerState<_AddStateSheet> {
  DateTime? _expiryDate;
  bool _noExpiry = false;

  @override
  void initState() {
    super.initState();
    // 피부 시술 후 → 기본 7일
    if (widget.type == TemporaryStateType.skinProcedureRecovery) {
      _expiryDate = DateTime.now().add(const Duration(days: 7));
    }
    // 면역저하 → 기본 만료일 없음
    if (widget.type == TemporaryStateType.immunoSuppressed) {
      _noExpiry = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 타이틀
          Text(
            widget.type.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.type.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // 만료일 설정
          if (!_noExpiry) ...[
            const Text(
              '언제까지 적용할까요?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _expiryDate != null
                          ? '${_expiryDate!.year}년 ${_expiryDate!.month}월 ${_expiryDate!.day}일'
                          : '만료일 선택 (선택사항)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _expiryDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 만료일 없음 토글
          Row(
            children: [
              Checkbox(
                value: _noExpiry,
                onChanged: (v) => setState(() {
                  _noExpiry = v ?? false;
                  if (_noExpiry) _expiryDate = null;
                }),
                activeColor: AppColors.primary,
              ),
              const Text(
                '만료일 없이 유지 (수동으로 해제)',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 추가 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '적용하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    final state = TemporaryState(
      type: widget.type,
      startDate: DateTime.now(),
      expiryDate: _noExpiry ? null : _expiryDate,
    );
    await ref.read(temporaryStatesProvider.notifier).add(state);
    if (mounted) Navigator.pop(context);
  }
}
