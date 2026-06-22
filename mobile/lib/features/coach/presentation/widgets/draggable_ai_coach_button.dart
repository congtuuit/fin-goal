import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/coach/presentation/widgets/ai_coach_card.dart';

/// A premium floating AI Assistant button that can be dragged freely.
///
/// Features:
/// - Smooth draggable physics using GestureDetector.
/// - Elastic snap-to-edge behavior when released.
/// - Glowing gradient styling matching the AI Coach theme.
/// - Clicking opens a gorgeous modal bottom sheet displaying the [AiCoachCard].
class DraggableAiCoachButton extends ConsumerStatefulWidget {
  final Goal goal;

  const DraggableAiCoachButton({
    super.key,
    required this.goal,
  });

  @override
  ConsumerState<DraggableAiCoachButton> createState() =>
      _DraggableAiCoachButtonState();
}

class _DraggableAiCoachButtonState extends ConsumerState<DraggableAiCoachButton> {
  // The dimensions of the floating button
  static const double _buttonSize = 46.0;

  // Track position offsets
  late Offset _position;
  bool _isInitialized = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Initialize position at bottom-right on first layout
    if (!_isInitialized) {
      _position = Offset(
        size.width - _buttonSize - 16.0,
        size.height - _buttonSize - padding.bottom - 100.0,
      );
      _isInitialized = true;
    }

    // Safety margins to keep the button fully within view boundaries
    final double minX = 16.0;
    final double maxX = size.width - _buttonSize - 16.0;
    final double minY = padding.top + 16.0;
    final double maxY = size.height - padding.bottom - _buttonSize - 16.0;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(minX, maxX),
              (_position.dy + details.delta.dy).clamp(minY, maxY),
            );
          });
        },
        onPanEnd: (_) {
          // Determine nearest edge and snap to it
          final screenWidth = size.width;
          final double targetX = (_position.dx + _buttonSize / 2 < screenWidth / 2)
              ? minX // Snap to left margin
              : maxX; // Snap to right margin

          setState(() {
            _isDragging = false;
            _position = Offset(targetX, _position.dy);
          });
        },
        onTap: () => _openCoachSheet(context),
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating glow indicator or pulse could go here
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
              // Glowing badge
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCoachSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handlebar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(8),
                // The actual AI Coach Card (pinned bottom and sides)
                AiCoachCard(
                  goal: widget.goal,
                  autoFetch: true,
                  isBottomSheet: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
