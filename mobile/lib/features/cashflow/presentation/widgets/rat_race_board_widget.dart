import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/features/cashflow/domain/entities/board_space.dart';

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
          // Background Center
          Center(
            child: Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevatedDark.withValues(alpha: 0.5),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'RAT RACE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Icon(Icons.pets, color: AppColors.primary.withValues(alpha: 0.5), size: 48),
                ],
              ),
            ),
          ),
          
          // Vẽ 24 ô cờ
          ...List.generate(24, (index) => _buildSpace(index)),
          
          // Vẽ avatar người chơi (Con chuột/người)
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildSpace(int index) {
    final space = ratRaceBoard[index];
    final angle = _getAngle(index);
    final radius = size / 2 - 24; // 24 is half of space size
    
    // Tính toán vị trí x, y từ tâm
    final x = (size / 2) + radius * cos(angle) - 20; // 20 is half width of space box
    final y = (size / 2) + radius * sin(angle) - 20;

    Color color;
    IconData icon;

    switch (space) {
      case SpaceType.paycheck:
        color = Colors.amber;
        icon = Icons.attach_money;
        break;
      case SpaceType.opportunity:
        color = Colors.green;
        icon = Icons.star;
        break;
      case SpaceType.doodad:
        color = Colors.red;
        icon = Icons.shopping_cart;
        break;
      case SpaceType.market:
        color = Colors.blue;
        icon = Icons.trending_up;
        break;
      case SpaceType.baby:
        color = Colors.purple;
        icon = Icons.child_care;
        break;
      case SpaceType.downsize:
        color = Colors.deepPurple;
        icon = Icons.work_off;
        break;
      case SpaceType.charity:
        color = Colors.pink;
        icon = Icons.favorite;
        break;
    }

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle + pi / 2, // Hướng mặt vào tâm
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 4,
              )
            ],
          ),
          child: Center(
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final angle = _getAngle(currentPosition);
    final radius = size / 2 - 24;
    
    // Tính toán vị trí x, y từ tâm
    final x = (size / 2) + radius * cos(angle) - 15; 
    final y = (size / 2) + radius * sin(angle) - 15;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutBack,
      left: x,
      top: y,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Center(
          child: Text('🐭', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  double _getAngle(int index) {
    // 24 ô, mỗi ô cách nhau 360/24 = 15 độ (pi/12 radian)
    // Bắt đầu từ ô 0 ở vị trí 12h (trên cùng) -> góc -pi/2
    return -pi / 2 + (index * (2 * pi / 24));
  }
}
