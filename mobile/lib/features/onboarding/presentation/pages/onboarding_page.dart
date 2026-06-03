import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/core/utils/validators.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/features/profile/domain/entities/financial_profile.dart';
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = false;

  // Form inputs
  final _ageCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _salaryDateCtrl = TextEditingController();

  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());
  final _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    _pageController.dispose();
    _ageCtrl.dispose();
    _incomeCtrl.dispose();
    _expenseCtrl.dispose();
    _savingsCtrl.dispose();
    _salaryDateCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKeys[_currentIndex].currentState?.validate() ?? false) {
      if (_currentIndex < 4) {
        FocusScope.of(context).unfocus(); // Unfocus before animating
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) {
          if (mounted) _focusNodes[_currentIndex].requestFocus();
        });
        setState(() => _currentIndex++);
      } else {
        _submit();
      }
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      FocusScope.of(context).unfocus(); // Unfocus before animating
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) _focusNodes[_currentIndex].requestFocus();
      });
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submit() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final profile = FinancialProfile(
      userId: userId,
      age: int.parse(_ageCtrl.text.trim()),
      monthlyIncome: CurrencyFormatter.parse(_incomeCtrl.text) ?? 0,
      fixedExpenses: CurrencyFormatter.parse(_expenseCtrl.text) ?? 0,
      currentSavings: CurrencyFormatter.parse(_savingsCtrl.text) ?? 0,
      salaryDate: int.parse(_salaryDateCtrl.text.trim()),
    );

    final error = await ref.read(profileProvider.notifier).createProfile(profile);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
        );
      } else {
        // Success — router will handle redirect based on state change
        context.go('/home/goal-selection');
      }
    }
  }

  Widget _buildCurrencyInput(
    TextEditingController controller,
    String label,
    String hint,
    String? Function(String?) validator,
    FocusNode focusNode,
  ) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: '₫',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      validator: validator,
      onChanged: (value) {
        // Format as user types (naive formatting for UX)
        final parsed = CurrencyFormatter.parse(value);
        if (parsed != null) {
          final formatted = CurrencyFormatter.formatInput(parsed);
          if (formatted != value) {
            controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
      onFieldSubmitted: (_) => _nextPage(),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentIndex > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage)
            : null,
        title: Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 4,
                decoration: BoxDecoration(
                  color: index <= _currentIndex ? AppColors.primary : AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  // Step 1: Age
                  _buildStep(
                    index: 0,
                    title: 'Chào bạn 👋\nBạn năm nay bao nhiêu tuổi?',
                    subtitle: 'Giúp ứng dụng tính toán các mốc thời gian phù hợp.',
                    child: TextFormField(
                      controller: _ageCtrl,
                      focusNode: _focusNodes[0],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '25',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      validator: Validators.age,
                      onFieldSubmitted: (_) => _nextPage(),
                    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms),
                  ),

                  // Step 2: Income
                  _buildStep(
                    index: 1,
                    title: 'Thu nhập hàng tháng của bạn?',
                    subtitle: 'Tổng thu nhập từ lương và các nguồn cố định khác.',
                    child: _buildCurrencyInput(
                      _incomeCtrl,
                      '',
                      '20.000.000',
                      Validators.income,
                      _focusNodes[1],
                    ),
                  ),

                  // Step 3: Expenses
                  _buildStep(
                    index: 2,
                    title: 'Chi phí cố định mỗi tháng?',
                    subtitle: 'Tiền thuê nhà, ăn uống cơ bản, trả góp...',
                    child: _buildCurrencyInput(
                      _expenseCtrl,
                      '',
                      '10.000.000',
                      (v) => Validators.expenses(v, income: CurrencyFormatter.parse(_incomeCtrl.text) ?? 0),
                      _focusNodes[2],
                    ),
                  ),

                  // Step 4: Savings
                  _buildStep(
                    index: 3,
                    title: 'Bạn đang có bao nhiêu tiền tiết kiệm?',
                    subtitle: 'Để trống nếu bạn mới bắt đầu.',
                    child: _buildCurrencyInput(
                      _savingsCtrl,
                      '',
                      '50.000.000',
                      Validators.savings,
                      _focusNodes[3],
                    ),
                  ),

                  // Step 5: Salary Date
                  _buildStep(
                    index: 4,
                    title: 'Ngày nhận lương hàng tháng?',
                    subtitle: 'Để ứng dụng nhắc nhở bạn cập nhật tình hình tiết kiệm.',
                    child: TextFormField(
                      controller: _salaryDateCtrl,
                      focusNode: _focusNodes[4],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '5',
                        suffixText: 'hàng tháng',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      validator: Validators.salaryDate,
                      onFieldSubmitted: (_) => _nextPage(),
                    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_currentIndex == 4 ? 'Hoàn tất' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required int index,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
      child: Form(
        key: _formKeys[index],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(AppSizes.xl),
            Text(title, style: Theme.of(context).textTheme.headlineMedium)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.05),
            const Gap(AppSizes.sm),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideX(begin: -0.05),
            const Gap(AppSizes.xxl),
            child,
          ],
        ),
      ),
    );
  }
}
