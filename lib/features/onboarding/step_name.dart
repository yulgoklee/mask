import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 온보딩 Step 1 — 이름 입력 (선택)
class StepName extends StatefulWidget {
  final String? initialName;
  final ValueChanged<String?> onChanged;

  const StepName({
    super.key,
    this.initialName,
    required this.onChanged,
  });

  @override
  State<StepName> createState() => _StepNameState();
}

class _StepNameState extends State<StepName> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _controller.addListener(() {
      final text = _controller.text.trim();
      widget.onChanged(text.isEmpty ? null : text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '어떻게 불러드릴까요?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이름을 입력하면 더 친근하게 알림을 드려요.\n입력하지 않아도 괜찮아요.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // 이름 입력 필드
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '예: 율곡',
              hintStyle: const TextStyle(
                fontSize: 20,
                color: AppColors.textHint,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              counterStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textHint, size: 20),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged(null);
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // 미리보기
          AnimatedOpacity(
            opacity: _controller.text.trim().isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_controller.text.trim().isNotEmpty ? _controller.text.trim() : ""}님, 오늘 마스크를 챙기세요.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
