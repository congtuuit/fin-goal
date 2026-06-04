import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fin_goal/core/constants/app_colors.dart';

class DiceWidget extends StatefulWidget {
  final int? value;
  final bool isRolling;
  final VoidCallback onTap;

  const DiceWidget({
    super.key,
    this.value,
    required this.isRolling,
    required this.onTap,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const Map<int, List<Offset>> _dotPositions = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.25, 0.25), Offset(0.75, 0.75)],
    3: [Offset(0.25, 0.25), Offset(0.5, 0.5), Offset(0.75, 0.75)],
    4: [
      Offset(0.25, 0.25),
      Offset(0.75, 0.25),
      Offset(0.25, 0.75),
      Offset(0.75, 0.75)
    ],
    5: [
      Offset(0.25, 0.25),
      Offset(0.75, 0.25),
      Offset(0.5, 0.5),
      Offset(0.25, 0.75),
      Offset(0.75, 0.75)
    ],
    6: [
      Offset(0.25, 0.2),
      Offset(0.75, 0.2),
      Offset(0.25, 0.5),
      Offset(0.75, 0.5),
      Offset(0.25, 0.8),
      Offset(0.75, 0.8)
    ],
  };

  @override
  Widget build(BuildContext context) {
    final size = 80.0;
    final displayValue = widget.value ?? 1;

    return GestureDetector(
      onTap: widget.isRolling ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _rotateAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.isRolling ? _rotateAnimation.value : 0,
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Stack(
            children: (_dotPositions[displayValue] ?? []).map((pos) {
              return Positioned(
                left: pos.dx * size - 5,
                top: pos.dy * size - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate(target: widget.isRolling ? 1 : 0).scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: 300.ms,
            ),
      ),
    );
  }
}
