import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';
import 'package:fin_goal/features/cashflow_game/engine/board_engine.dart';

class RatRaceBoardWidget extends StatelessWidget {
  final int currentPosition;
  final double size;

  const RatRaceBoardWidget({
    super.key,
    required this.currentPosition,
    this.size = 320.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Center background
          Center(
            child: Container(
              width: size * 0.60,
              height: size * 0.60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevatedDark.withValues(alpha: 0.6),
                border: Border.all(
                    color: AppColors.borderDark.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🐭', style: TextStyle(fontSize: size * 0.12)),
                  Text(
                    'RAT RACE',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: size * 0.055,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 24 Board spaces
          ...List.generate(boardSize, (i) => _buildSpace(i, size)),

          // Player Avatar
          _PlayerAvatar(currentPosition: currentPosition, boardSize: size),
        ],
      ),
    );
  }

  Widget _buildSpace(int index, double boardSize) {
    final space = ratRaceBoard[index];
    final angle = _angleFor(index);
    final radius = boardSize / 2 - boardSize * 0.085;

    final cx = (boardSize / 2) + radius * cos(angle);
    final cy = (boardSize / 2) + radius * sin(angle);
    final boxSize = boardSize * 0.13;

    final color = _spaceColor(space);
    final icon = _spaceIcon(space);
    final isCurrentPosition = index == 0; // Start/GO

    return Positioned(
      left: cx - boxSize / 2,
      top: cy - boxSize / 2,
      child: Transform.rotate(
        angle: angle + pi / 2,
        child: Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isCurrentPosition ? 0.4 : 0.15),
            borderRadius: BorderRadius.circular(boxSize * 0.25),
            border: Border.all(
              color: color.withValues(alpha: isCurrentPosition ? 0.9 : 0.5),
              width: isCurrentPosition ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(icon, style: TextStyle(fontSize: boxSize * 0.48)),
          ),
        ),
      ),
    );
  }

  static double _angleFor(int index) =>
      -pi / 2 + (index * (2 * pi / boardSize));

  static Color _spaceColor(BoardSpaceType type) => switch (type) {
        BoardSpaceType.paycheck => Colors.amber,
        BoardSpaceType.opportunity => Colors.green,
        BoardSpaceType.doodad => Colors.red,
        BoardSpaceType.market => Colors.blue,
        BoardSpaceType.baby => Colors.purple,
        BoardSpaceType.downsize => Colors.deepPurple,
        BoardSpaceType.charity => Colors.pink,
      };

  static String _spaceIcon(BoardSpaceType type) => switch (type) {
        BoardSpaceType.paycheck => '💰',
        BoardSpaceType.opportunity => '⭐',
        BoardSpaceType.doodad => '🛒',
        BoardSpaceType.market => '📈',
        BoardSpaceType.baby => '👶',
        BoardSpaceType.downsize => '❌',
        BoardSpaceType.charity => '❤️',
      };
}

// ── Player Avatar ────────────────────────────────────────────────────────────
class _PlayerAvatar extends StatelessWidget {
  final int currentPosition;
  final double boardSize;

  const _PlayerAvatar({
    required this.currentPosition,
    required this.boardSize,
  });

  @override
  Widget build(BuildContext context) {
    final angle = -pi / 2 + (currentPosition * (2 * pi / boardSize));
    final radius = boardSize / 2 - boardSize * 0.085;
    final cx = (boardSize / 2) + radius * cos(angle);
    final cy = (boardSize / 2) + radius * sin(angle);
    final avatarSize = boardSize * 0.09;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      left: cx - avatarSize / 2,
      top: cy - avatarSize / 2,
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text('😊',
              style: TextStyle(fontSize: avatarSize * 0.55)),
        ),
      ),
    );
  }
}
