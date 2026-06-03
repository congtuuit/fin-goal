import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final String title;
  final String price;

  const PaymentPage({
    super.key,
    required this.title,
    required this.price,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isLoading = false;

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);
    
    // Giả lập thời gian chờ xác thực giao dịch
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    ref.read(subscriptionProvider.notifier).upgradeToPremium();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanh toán thành công! Tài khoản đã lên PRO.'),
        backgroundColor: AppColors.success,
      ),
    );
    
    // Đóng trang Payment và trang Paywall để về Dashboard
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Gap(AppSizes.xl),
                      // Box thông tin đơn hàng
                      Container(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevatedDark,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Đơn hàng', style: Theme.of(context).textTheme.bodySmall),
                                const Gap(4),
                                Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                            Text(
                              widget.price,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.05),
                      
                      const Gap(AppSizes.xxl),
                      
                      // QR Code Mockup
                      Container(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        decoration: BoxDecoration(
                          color: Colors.white, // Nền trắng để QR dễ quét
                          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.qr_code_2,
                              size: 200,
                              color: Colors.black87,
                            ),
                            const Gap(AppSizes.md),
                            Text(
                              'Quét mã QR bằng ứng dụng\nngân hàng hoặc ví điện tử',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                      
                      const Gap(AppSizes.xxl),
                      
                      // Hướng dẫn thêm
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.success, size: 20),
                          const Gap(AppSizes.sm),
                          Text(
                            'Thanh toán an toàn & bảo mật',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),
              
              // Nút bấm cố định ở dưới cùng
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Tôi đã thanh toán', style: TextStyle(fontSize: 16)),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
