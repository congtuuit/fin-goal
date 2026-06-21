import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/app/router/routes.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.auto_awesome,
      'title': 'Trợ lý Tài chính AI',
      'description': 'Lên kế hoạch và kiểm soát chi tiêu thông minh hơn bao giờ hết.',
      'color': AppColors.primary,
    },
    {
      'icon': Icons.timeline,
      'title': 'Cỗ Máy Thời Gian',
      'description': 'Mô phỏng các quyết định tài chính của bạn trong 5-10 năm tới.',
      'color': AppColors.warning,
    },
    {
      'icon': Icons.shield_outlined,
      'title': 'Riêng Tư Tuyệt Đối',
      'description': 'Không bắt buộc tạo tài khoản. Mọi dữ liệu an toàn trên máy bạn.',
      'color': AppColors.success,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.backgroundDark, AppColors.surfaceDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () {
                      ref.read(hasSeenWelcomeProvider.notifier).setSeen();
                      context.go(AppRoutes.login);
                    },
                    child: Text('Bỏ qua', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: (slide['color'] as Color).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide['icon'],
                                size: 80,
                                color: slide['color'],
                              ),
                            ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                            const Gap(AppSizes.xxl),
                            Text(
                              slide['title'],
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                            const Gap(AppSizes.lg),
                            Text(
                              slide['description'],
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Indicators & Next Button
                Padding(
                  padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index ? AppColors.primary : AppColors.borderDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      // Next/Start Button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIndex < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            ref.read(hasSeenWelcomeProvider.notifier).setSeen();
                            context.go(AppRoutes.login);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentIndex == _slides.length - 1 ? 'Bắt đầu' : 'Tiếp theo',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Gap(8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSizes.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
