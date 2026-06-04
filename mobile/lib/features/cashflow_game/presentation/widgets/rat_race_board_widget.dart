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
    final height = size * 0.75; // 8x6 aspect ratio -> height = width * 6/8

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        children: [
          // Center background
          Center(
            child: Container(
              width: size * 0.65,
              height: height * 0.55,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.borderDark.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🐭', style: TextStyle(fontSize: size * 0.1)),
                  const SizedBox(height: 8),
                  Text(
                    'RAT RACE',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: size * 0.05,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 24 Board spaces
          ...List.generate(boardSize, (i) => _buildSpace(i, size, height)),

          // Player Avatar
          _PlayerAvatar(currentPosition: currentPosition, boardWidth: size, boardHeight: height),
        ],
      ),
    );
  }

  Widget _buildSpace(int index, double boardWidth, double boardHeight) {
    final space = ratRaceBoard[index];
    final grid = _getGridCoordinate(index);
    
    final cellWidth = boardWidth / 8;
    final cellHeight = boardHeight / 6;
    
    final cx = (grid.x + 0.5) * cellWidth;
    final cy = (grid.y + 0.5) * cellHeight;
    final boxSize = cellWidth * 0.8; // 80% of cell

    final color = _spaceColor(space);
    final icon = _spaceIcon(space);
    final isCurrentPosition = index == currentPosition;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: cx - boxSize / 2,
      top: cy - boxSize / 2,
      child: Container(
        width: isCurrentPosition ? boxSize * 1.15 : boxSize,
        height: isCurrentPosition ? boxSize * 1.15 : boxSize,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isCurrentPosition ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(boxSize * 0.25),
          border: Border.all(
            color: color.withValues(alpha: isCurrentPosition ? 1.0 : 0.5),
            width: isCurrentPosition ? 2.5 : 1.5,
          ),
          boxShadow: isCurrentPosition ? [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ] : [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(icon, style: TextStyle(fontSize: boxSize * (isCurrentPosition ? 0.5 : 0.45))),
        ),
      ),
    );
  }

  static Point<double> _getGridCoordinate(int index) {
    if (index <= 7) return Point(index.toDouble(), 0);
    if (index <= 12) return Point(7, (index - 7).toDouble());
    if (index <= 19) return Point((19 - index).toDouble(), 5);
    return Point(0, (24 - index).toDouble());
  }

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
  final double boardWidth;
  final double boardHeight;

  const _PlayerAvatar({
    required this.currentPosition,
    required this.boardWidth,
    required this.boardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final grid = RatRaceBoardWidget._getGridCoordinate(currentPosition);
    final cellWidth = boardWidth / 8;
    final cellHeight = boardHeight / 6;
    
    final cx = (grid.x + 0.5) * cellWidth;
    final cy = (grid.y + 0.5) * cellHeight;
    final avatarSize = cellWidth * 0.6; // Slightly smaller than space box

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
              style: TextStyle(fontSize: avatarSize * 0.6)),
        ),
      ),
    );
  }
}
