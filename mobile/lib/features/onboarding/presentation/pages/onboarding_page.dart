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
import 'package:fin_goal/app/router/routes.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentIndex = 0;
  final int _totalPages = 6;
  bool _isLoading = false;

  String _selectedGoal = '';

  // Form inputs
  final _ageCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _salaryDateCtrl = TextEditingController();

  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  final _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    _pageController.dispose();
    _ageCtrl.dispose();
    _incomeCtrl.dispose();
    _expenseCtrl.dispose();
    _salaryDateCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    bool canProceed = true;
    if (_currentIndex >= 1 && _currentIndex <= 4) {
      canProceed =
          _formKeys[_currentIndex - 1].currentState?.validate() ?? false;
    }

    if (canProceed) {
      if (_currentIndex < _totalPages - 1) {
        FocusScope.of(context).unfocus();
        _pageController
            .nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        )
            .then((_) {
          if (mounted && _currentIndex >= 1 && _currentIndex <= 4) {
            _focusNodes[_currentIndex - 1].requestFocus();
          }
        });
        setState(() => _currentIndex++);
      }
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      FocusScope.of(context).unfocus();
      _pageController
          .previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      )
          .then((_) {
        if (mounted && _currentIndex >= 1 && _currentIndex <= 4) {
          _focusNodes[_currentIndex - 1].requestFocus();
        }
      });
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitAndGoToGame() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final profile = FinancialProfile(
      userId: userId,
      age: int.tryParse(_ageCtrl.text.trim()) ?? 25,
      monthlyIncome: CurrencyFormatter.parse(_incomeCtrl.text) ?? 0,
      fixedExpenses: CurrencyFormatter.parse(_expenseCtrl.text) ?? 0,
      salaryDate: int.tryParse(_salaryDateCtrl.text.trim()) ?? 5,
    );

    final error =
        await ref.read(profileProvider.notifier).createProfile(profile);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.message), backgroundColor: AppColors.danger),
        );
      } else {
        context.go(AppRoutes.cashflowBoardGame);
      }
    }
  }

  int _calculateFireAge() {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 25;
    final income = CurrencyFormatter.parse(_incomeCtrl.text) ?? 0;
    final expense = CurrencyFormatter.parse(_expenseCtrl.text) ?? 0;

    final monthlySavings = income - expense;
    if (monthlySavings <= 0) return 99;

    final fireNumber = expense * 12 * 25;
    final monthsToFire = fireNumber / monthlySavings;
    final yearsToFire = (monthsToFire / 12).ceil();

    return age + yearsToFire;
  }

  Widget _buildCurrencyInput(
    TextEditingController controller,
    String hint,
    String? Function(String?) validator,
    FocusNode focusNode,
  ) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: '₫',
        suffixStyle: const TextStyle(fontSize: 24, color: AppColors.textMuted),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      validator: validator,
      onChanged: (value) {
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
    )
        .animate()
        .fadeIn()
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildSuggestionChip(String label, int value, TextEditingController controller) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.surfaceDark,
      side: const BorderSide(color: AppColors.borderDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      onPressed: () {
        final formatted = CurrencyFormatter.formatInput(value);
        setState(() {
          controller.text = formatted;
          controller.selection = TextSelection.collapsed(offset: formatted.length);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressWidth =
        MediaQuery.of(context).size.width * (_currentIndex / (_totalPages - 1));

    return Scaffold(
      appBar: AppBar(
        leading: _currentIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: _prevPage)
            : null,
        title: Text(
          'Tạo Nhân Vật',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.textMuted),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Stack(
            children: [
              Container(
                  height: 4,
                  width: double.infinity,
                  color: AppColors.borderDark),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                width: progressWidth,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0: Hook
                  _buildHookStep(),

                  // Step 1: Age
                  _buildFormStep(
                    index: 1,
                    title: 'Độ tuổi nhân vật?',
                    subtitle: 'Hành trình của bạn bắt đầu ở mốc thời gian nào?',
                    child: TextFormField(
                      controller: _ageCtrl,
                      focusNode: _focusNodes[0],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                      decoration: const InputDecoration(
                        hintText: '25',
                        suffixText: 'tuổi',
                        border: InputBorder.none,
                      ),
                      validator: Validators.age,
                      onFieldSubmitted: (_) => _nextPage(),
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ),

                  // Step 2: Income
                  _buildFormStep(
                    index: 2,
                    title: 'Chỉ số Thu Nhập',
                    subtitle:
                        'Mỗi tháng nhân vật của bạn tạo ra dòng tiền dương bao nhiêu?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrencyInput(
                          _incomeCtrl,
                          '20.000.000',
                          Validators.income,
                          _focusNodes[1],
                        ),
                        const Gap(AppSizes.md),
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: [
                            _buildSuggestionChip('Cơ bản (~7M)', 7000000, _incomeCtrl),
                            _buildSuggestionChip('Văn phòng (~15M)', 15000000, _incomeCtrl),
                            _buildSuggestionChip('Chuyên gia (~30M)', 30000000, _incomeCtrl),
                          ],
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),

                  // Step 3: Expenses
                  _buildFormStep(
                    index: 3,
                    title: 'Chi Phí Sinh Hoạt',
                    subtitle:
                        'Mỗi tháng bạn cần chi tiêu tối thiểu bao nhiêu để duy trì cuộc sống?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrencyInput(
                          _expenseCtrl,
                          '10.000.000',
                          (v) => Validators.expenses(v,
                              income:
                                  CurrencyFormatter.parse(_incomeCtrl.text) ?? 0),
                          _focusNodes[2],
                        ),
                        const Gap(AppSizes.md),
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: [
                            _buildSuggestionChip('Tiết kiệm (~4M)', 4000000, _expenseCtrl),
                            _buildSuggestionChip('Trung bình (~8M)', 8000000, _expenseCtrl),
                            _buildSuggestionChip('Thoải mái (~15M)', 15000000, _expenseCtrl),
                          ],
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),

                  // Step 4: Salary Date
                  _buildFormStep(
                    index: 4,
                    title: 'Chu kỳ hồi máu (Lương)',
                    subtitle:
                        'Ngày nào trong tháng nhân vật sẽ nhận được tiếp viện?',
                    child: TextFormField(
                      controller: _salaryDateCtrl,
                      focusNode: _focusNodes[3],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                      decoration: const InputDecoration(
                        hintText: '5',
                        suffixText: 'hàng tháng',
                        border: InputBorder.none,
                      ),
                      validator: Validators.salaryDate,
                      onFieldSubmitted: (_) => _nextPage(),
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ),

                  // Step 5: The Shock Effect
                  _buildShockStep(),
                ],
              ),
            ),
            if (_currentIndex > 0 && _currentIndex < _totalPages - 1)
              Padding(
                padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: const Text('Tiếp tục'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep({
    required int index,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
      child: Form(
        key: _formKeys[index - 1],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(AppSizes.xl),
              Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.05),
              const Gap(AppSizes.sm),
              Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textMuted))
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideX(begin: -0.05),
              const Gap(AppSizes.xxl),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHookStep() {
    final goals = [
      {'id': 'fire', 'title': 'Nghỉ hưu sớm trước 40 tuổi', 'icon': '🔥'},
      {'id': 'debt', 'title': 'Thoát khỏi vòng xoáy nợ nần', 'icon': '⚔️'},
      {'id': 'house', 'title': 'Mua nhà, mua xe tự do', 'icon': '🏡'},
    ];

    return Padding(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(AppSizes.xl),
              Text('Mục tiêu lớn nhất của bạn lúc này là gì?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold))
                  .animate()
                  .fadeIn()
                  .slideY(begin: -0.1),
              const Gap(AppSizes.xxl),
              ...goals.map((g) {
                final isSelected = _selectedGoal == g['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedGoal = g['id']!);
                      Future.delayed(
                          const Duration(milliseconds: 300), _nextPage);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderDark,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(g['icon']!,
                              style: const TextStyle(fontSize: 28)),
                          const Gap(AppSizes.md),
                          Expanded(
                            child: Text(
                              g['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (goals.indexOf(g) * 100).ms)
                      .slideX(begin: 0.1),
                );
              }),
            ],
          ),
        ));
  }

  Widget _buildShockStep() {
    final fireAge = _calculateFireAge();
    final isNever = fireAge >= 99;

    return Padding(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Gap(AppSizes.xl),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNever
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                ),
                child: Text(
                  isNever ? '💀' : '😱',
                  style: const TextStyle(fontSize: 64),
                ),
              ).animate().scale(
                  delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
              const Gap(AppSizes.xl),
              Text(
                'Phân Tích Dữ Liệu',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.textMuted),
              ).animate().fadeIn(delay: 600.ms),
              const Gap(AppSizes.md),
              Text(
                isNever
                    ? 'Với chỉ số hiện tại, bạn sẽ không bao giờ đạt được Tự Do Tài Chính!'
                    : 'Dựa trên chỉ số hiện tại, nếu không có gì thay đổi, bạn sẽ Tự Do Tài Chính vào năm...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ).animate().fadeIn(delay: 1000.ms),
              if (!isNever) ...[
                const Gap(AppSizes.lg),
                Text(
                  '$fireAge TUỔI',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: fireAge > 50 ? AppColors.danger : AppColors.success,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1800.ms)
                    .scale(curve: Curves.elasticOut),
              ],
              const Gap(AppSizes.xxl),
              const Gap(AppSizes.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAndGoToGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Tìm Lối Thoát',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 2500.ms).slideY(begin: 0.5),
            ],
          ),
        ));
  }
}
