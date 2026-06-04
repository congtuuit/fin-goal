import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';

class GameGuideDialog extends StatelessWidget {
  const GameGuideDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const GameGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.amber),
                    Gap(AppSizes.sm),
                    Text(
                      'Hướng Dẫn & Thuật Ngữ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Gap(AppSizes.sm),
            const Divider(color: AppColors.borderDark),
            const Gap(AppSizes.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('🎯 Mục Tiêu Trò Chơi'),
                    _buildText('Thoát khỏi vòng lặp "Đi làm - Trả nợ" (Rat Race) để đạt Tự Do Tài Chính.'),
                    _buildHighlight('Điều kiện thắng: Thu Nhập Thụ Động > Tổng Chi Phí hàng tháng.'),
                    
                    const Gap(AppSizes.lg),
                    
                    _buildSectionTitle('📚 Từ Điển Thuật Ngữ'),
                    _buildTermItem('Tài Sản (Asset)', 'Những thứ đẻ ra tiền và bỏ vào túi bạn dù bạn không làm việc (Cổ phiếu, BĐS cho thuê, Doanh nghiệp).', AppColors.success),
                    _buildTermItem('Tiêu Sản (Liability)', 'Những thứ liên tục móc tiền từ túi bạn mỗi tháng (Trả góp điện thoại, xe sang, vay tiêu dùng).', AppColors.danger),
                    _buildTermItem('Thu Nhập Thụ Động', 'Dòng tiền chảy vào túi bạn từ Tài Sản. Chìa khóa để chiến thắng trò chơi.', Colors.amber),
                    _buildTermItem('Dòng Tiền (Cashflow)', 'Số tiền thực tế bạn bỏ túi mỗi tháng.\nDòng Tiền = Tổng Thu Nhập - Tổng Chi Phí.', Colors.blueAccent),
                    
                    const Gap(AppSizes.lg),

                    _buildSectionTitle('🎲 Ý Nghĩa Các Ô Bàn Cờ'),
                    _buildSpaceItem('💰', 'Nhận Lương', 'Nhận Dòng Tiền hàng tháng. Bạn sẽ nhận được tiền ngay khi xúc xắc lăn ngang qua ô này.'),
                    _buildSpaceItem('⭐', 'Cơ Hội (Opportunity)', 'Mua/Bán Tài Sản. Tùy số tiền mặt đang có mà bạn chọn Cơ hội nhỏ (Dưới \$5,000) hay Cơ hội lớn.'),
                    _buildSpaceItem('🛒', 'Tiêu Sản (Doodad)', 'Bắt buộc chi tiền cho những khoản tiêu xài ngẫu nhiên. Làm giảm tiền mặt và đôi khi tăng nợ trả góp.'),
                    _buildSpaceItem('📈', 'Thị Trường (Market)', 'Nơi bạn có thể bán Tài Sản (Cổ phiếu, BĐS) với giá cao/thấp tùy theo biến động kinh tế.'),
                    _buildSpaceItem('👶', 'Em Bé (Baby)', 'Có thêm thành viên mới, tăng 10% chi phí sinh hoạt hàng tháng (Tối đa 3 con).'),
                    _buildSpaceItem('❌', 'Mất Việc (Downsize)', 'Bị sa thải. Mất số tiền bằng 1 tháng Tổng Chi Phí và bị treo giò mất 2 lượt chơi.'),
                    _buildSpaceItem('❤️', 'Từ Thiện (Charity)', 'Đóng góp 10% Tổng Thu Nhập để được phép xúc xắc thêm vòng này.'),
                    
                    const Gap(AppSizes.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
      ),
    );
  }

  Widget _buildHighlight(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      margin: const EdgeInsets.only(top: AppSizes.xs, bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTermItem(String term, String definition, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('▪ $term', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const Gap(2),
          Text(definition, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSpaceItem(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const Gap(AppSizes.xs),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
