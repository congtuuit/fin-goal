import 'package:flutter/material.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:gap/gap.dart';

class LegalPage extends StatelessWidget {
  final String title;

  const LegalPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập nhật lần cuối: 20/06/2026',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const Gap(AppSizes.lg),
            Text(
              '1. Điều khoản chung',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(AppSizes.sm),
            Text(
              'Bằng việc tải xuống hoặc sử dụng ứng dụng, các điều khoản này sẽ tự động áp dụng cho bạn. Bạn nên đảm bảo rằng bạn đã đọc kỹ chúng trước khi sử dụng ứng dụng.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(AppSizes.md),
            Text(
              '2. Quyền riêng tư',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(AppSizes.sm),
            Text(
              'Financial Goals cam kết bảo vệ quyền riêng tư của bạn. Mọi dữ liệu tài chính bạn nhập vào ứng dụng chỉ được lưu trữ cho mục đích tính toán mô phỏng và không được bán cho bất kỳ bên thứ ba nào.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(AppSizes.md),
            Text(
              '3. Tuyên bố miễn trừ trách nhiệm',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(AppSizes.sm),
            Text(
              'Mọi số liệu mô phỏng trong ứng dụng chỉ mang tính chất tham khảo dựa trên giả định (Lạm phát, Lãi suất). Đây KHÔNG phải là lời khuyên đầu tư tài chính. Bạn tự chịu trách nhiệm với các quyết định đầu tư thực tế của mình.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(AppSizes.xl),
          ],
        ),
      ),
    );
  }
}
