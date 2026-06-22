import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/services/ai_prompt_builder.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/coach/presentation/providers/coach_provider.dart';

/// The AI Financial Coach card widget.
///
/// Displays AI-generated advice for a given [goal].
/// Features:
/// - Shimmer skeleton while loading.
/// - Elegant gradient header with AI Coach branding.
/// - Cached advice indicator with refresh button.
/// - Error / No-API-Key fallback state (no crash).
/// - Coach tone selector (encouraging / analytical / strict).
class AiCoachCard extends ConsumerStatefulWidget {
  final Goal goal;
  final bool autoFetch;
  final bool isBottomSheet;

  const AiCoachCard({
    super.key,
    required this.goal,
    this.autoFetch = true,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<AiCoachCard> createState() => _AiCoachCardState();
}

class _AiCoachCardState extends ConsumerState<AiCoachCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    if (widget.autoFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final tone = ref.read(coachToneProvider);
          ref
              .read(goalCoachProvider(widget.goal.id).notifier)
              .fetchAdvice(widget.goal, tone: tone);
        }
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adviceAsync = ref.watch(goalCoachProvider(widget.goal.id));
    final tone = ref.watch(coachToneProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        ),
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl))
            : BorderRadius.circular(AppSizes.radiusXl),
        border: widget.isBottomSheet
            ? Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                right: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
              )
            : Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1,
              ),
        boxShadow: widget.isBottomSheet
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(tone),

          // ── Content ───────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.lg,
              0,
              AppSizes.lg,
              widget.isBottomSheet
                  ? AppSizes.lg + MediaQuery.of(context).padding.bottom
                  : AppSizes.lg,
            ),
            child: adviceAsync.when(
              data: (advice) {
                if (advice == null) {
                  return _buildIdleState(tone);
                }
                return _buildAdviceContent(advice, tone);
              },
              loading: _buildShimmerLoading,
              error: (error, _) => _buildErrorState(error.toString(), tone),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(CoachTone tone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.md,
        AppSizes.md,
      ),
      child: Row(
        children: [
          // Sparkles icon with glow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const Gap(AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Financial Coach',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _toneName(tone),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Tone selector
          _buildToneChipRow(tone),
        ],
      ),
    );
  }

  Widget _buildToneChipRow(CoachTone currentTone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: CoachTone.values.map((t) {
        final isSelected = t == currentTone;
        return GestureDetector(
          onTap: () => ref.read(coachToneProvider.notifier).setTone(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight.withValues(alpha: 0.6)
                    : AppColors.borderDark,
              ),
            ),
            child: Center(
              child: Text(
                _toneEmoji(t),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Idle state (before first fetch)
  // ---------------------------------------------------------------------------

  Widget _buildIdleState(CoachTone tone) {
    return Column(
      children: [
        const Text(
          'Nhấn để nhận phân tích AI về tiến độ mục tiêu của bạn.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const Gap(AppSizes.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Phân tích ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            onPressed: () {
              ref
                  .read(goalCoachProvider(widget.goal.id).notifier)
                  .fetchAdvice(widget.goal, tone: tone);
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Advice content
  // ---------------------------------------------------------------------------

  Widget _buildAdviceContent(dynamic advice, CoachTone tone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Advice text
        Text(
          advice.adviceText as String,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const Gap(AppSizes.md),
        // Footer: timestamp + refresh
        Row(
          children: [
            Icon(
              advice.isFromCache as bool
                  ? Icons.access_time_outlined
                  : Icons.check_circle_outline,
              size: 12,
              color: AppColors.textMuted,
            ),
            const Gap(4),
            Text(
              '${advice.isFromCache as bool ? "Cache · " : ""}Phân tích lúc ${advice.formattedTime}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref
                  .read(goalCoachProvider(widget.goal.id).notifier)
                  .refresh(widget.goal, tone: tone),
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh,
                    size: 13,
                    color: AppColors.primaryLight,
                  ),
                  const Gap(3),
                  const Text(
                    'Làm mới',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer loading
  // ---------------------------------------------------------------------------

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerLine(width: double.infinity, shimmerValue: shimmerValue),
            const Gap(8),
            _shimmerLine(width: double.infinity, shimmerValue: shimmerValue),
            const Gap(8),
            _shimmerLine(width: 200, shimmerValue: shimmerValue),
            const Gap(16),
            _shimmerLine(width: 120, shimmerValue: shimmerValue, height: 10),
          ],
        );
      },
    );
  }

  Widget _shimmerLine({
    required double width,
    required double shimmerValue,
    double height = 14,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surfaceElevatedDark,
            AppColors.borderDark.withValues(alpha: 0.8),
            AppColors.surfaceElevatedDark,
          ],
          stops: [
            (shimmerValue - 0.3).clamp(0.0, 1.0),
            shimmerValue.clamp(0.0, 1.0),
            (shimmerValue + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String error, CoachTone tone) {
    // User-friendly error detection
    final isNoApiKey = error.contains('API Key') || error.contains('chưa được cấu hình');
    final isNetworkError = error.contains('kết nối') || error.contains('SocketException');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isNoApiKey ? Icons.vpn_key_outlined : Icons.wifi_off_rounded,
              color: AppColors.warning,
              size: 18,
            ),
            const Gap(8),
            Expanded(
              child: Text(
                isNoApiKey
                    ? 'Cần cấu hình API Key AI trong Cài đặt để dùng tính năng này.'
                    : isNetworkError
                        ? 'Không kết nối được AI. Kiểm tra lại mạng và thử lại.'
                        : 'Có lỗi xảy ra khi lấy phân tích AI.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const Gap(AppSizes.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            onPressed: () => ref
                .read(goalCoachProvider(widget.goal.id).notifier)
                .fetchAdvice(widget.goal, tone: tone),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _toneName(CoachTone tone) => switch (tone) {
        CoachTone.encouraging => 'Chế độ: Ân cần · Động viên',
        CoachTone.analytical => 'Chế độ: Phân tích · Dữ liệu',
        CoachTone.strict => 'Chế độ: Nghiêm khắc · Thúc đẩy',
      };

  String _toneEmoji(CoachTone tone) => switch (tone) {
        CoachTone.encouraging => '😊',
        CoachTone.analytical => '📊',
        CoachTone.strict => '💪',
      };
}
