import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';
import 'package:fin_goal/features/cashflow_game/engine/board_engine.dart';

class FastTrackBoardWidget extends StatelessWidget {
  final int currentPosition;
  final double size;

  const FastTrackBoardWidget({
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
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚀', style: TextStyle(fontSize: size * 0.1)),
                  const SizedBox(height: 8),
                  Text(
                    'FAST TRACK',
                    style: TextStyle(
                      color: Colors.amber,
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
          ...List.generate(fastTrackBoardSize, (i) => _buildSpace(i, size, height)),

          // Player Avatar
          _PlayerAvatar(currentPosition: currentPosition, boardWidth: size, boardHeight: height),
        ],
      ),
    );
  }

  Widget _buildSpace(int index, double boardWidth, double boardHeight) {
    final space = fastTrackBoard[index];
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
          color: color.withValues(alpha: isCurrentPosition ? 0.4 : 0.2),
          borderRadius: BorderRadius.circular(boxSize * 0.25),
          border: Border.all(
            color: color.withValues(alpha: isCurrentPosition ? 1.0 : 0.6),
            width: isCurrentPosition ? 2.5 : 1.5,
          ),
          boxShadow: isCurrentPosition ? [
            BoxShadow(
              color: color.withValues(alpha: 0.7),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ] : [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 5,
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
        BoardSpaceType.fastTrackCashflowDay => Colors.purpleAccent,
        BoardSpaceType.fastTrackBusiness => Colors.amber,
        BoardSpaceType.fastTrackDream => Colors.pinkAccent,
        BoardSpaceType.fastTrackAudit => Colors.redAccent,
        BoardSpaceType.charity => Colors.pink,
        _ => Colors.grey,
      };

  static String _spaceIcon(BoardSpaceType type) => switch (type) {
        BoardSpaceType.fastTrackCashflowDay => '💸',
        BoardSpaceType.fastTrackBusiness => '🏢',
        BoardSpaceType.fastTrackDream => '⭐',
        BoardSpaceType.fastTrackAudit => '⚖️',
        BoardSpaceType.charity => '❤️',
        _ => '❓',
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
    final grid = FastTrackBoardWidget._getGridCoordinate(currentPosition);
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
              color: Colors.amber.withValues(alpha: 0.8),
              blurRadius: 15,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text('😎',
              style: TextStyle(fontSize: avatarSize * 0.6)),
        ),
      ),
    );
  }
}
