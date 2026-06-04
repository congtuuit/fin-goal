import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/app/router/routes.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/core/services/direct_client_ai_service.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _obscureApiKey = true;
  bool _isTesting = false;

  // Form State
  String _selectedProvider = 'gemini';
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  final List<String> _geminiModels = ['gemini-1.5-flash', 'gemini-1.5-pro'];
  final List<String> _openaiModels = ['gpt-4o-mini', 'gpt-4o'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = getIt<SharedPreferences>();
    setState(() {
      _selectedProvider =
          _prefs.getString(DirectClientAiService.keyProvider) ?? 'gemini';
      _apiKeyCtrl.text =
          _prefs.getString(DirectClientAiService.keyApiKey) ?? '';

      final savedModel = _prefs.getString(DirectClientAiService.keyModel) ?? '';
      if (_selectedProvider == 'gemini') {
        _modelCtrl.text =
            savedModel.isNotEmpty ? savedModel : _geminiModels.first;
      } else {
        _modelCtrl.text =
            savedModel.isNotEmpty ? savedModel : _openaiModels.first;
      }

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _prefs.setString(
          DirectClientAiService.keyProvider, _selectedProvider);
      await _prefs.setString(
          DirectClientAiService.keyApiKey, _apiKeyCtrl.text.trim());
      await _prefs.setString(
          DirectClientAiService.keyModel, _modelCtrl.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình AI thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu cấu hình: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      final service = DirectClientAiService(_prefs);
      await service.testConnection(
        _selectedProvider,
        _apiKeyCtrl.text.trim(),
        _modelCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kết nối AI thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. User Info Header Card
                  _buildUserInfoCard(user, isPremium),
                  const Gap(AppSizes.lg),

                  // 2. Upgrade Banner (if not premium)
                  if (!isPremium) ...[
                    _buildUpgradeBanner(),
                    const Gap(AppSizes.xl),
                  ],

                  // Cashflow Game Banner
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'GIÁO DỤC TÀI CHÍNH',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  _buildCashflowBanner(),

                  const Gap(AppSizes.xxl),

                  // 3. AI Settings Panel
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'CẤU HÌNH AI',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  _buildAiSettingsCard(),

                  const Gap(AppSizes.md),

                  // Các nút thao tác
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_tethering, size: 20),
                          label: const Text('Kiểm tra'),
                          onPressed:
                              _isTesting || _isLoading ? null : _testConnection,
                        ),
                      ),
                      const Gap(AppSizes.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text('Lưu'),
                          onPressed:
                              _isTesting || _isLoading ? null : _saveSettings,
                        ),
                      ),
                    ],
                  ),

                  const Gap(AppSizes.xxl),

                  // 4. Khác
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'KHÁC',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  _buildDangerZone(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard(dynamic user, bool isPremium) {
    final displayName = user?.displayName ?? 'Người dùng Offline';
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [
                  const Color(0xFF1F0C3B),
                  const Color(0xFF5F2C82)
                ] // Premium deep purple
              : [AppColors.surfaceElevatedDark, AppColors.surfaceElevatedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFF5F2C82).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: isPremium
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isPremium ? const Color(0xFFFFD700) : AppColors.primary,
              ),
            ),
          ),
          const Gap(AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPremium ? '★ PREMIUM' : 'Miễn Phí',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPremium
                          ? const Color(0xFFFFD700)
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return InkWell(
      onTap: () => context.push('/home/paywall'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: AppColors.primary, size: 36),
            const Gap(AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nâng cấp lên Premium',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16)),
                  const Gap(4),
                  Text('Mở khóa toàn bộ tính năng AI',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCashflowBanner() {
    return InkWell(
      onTap: () => context.push(AppRoutes.cashflowBoardGame),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8B57), Color(0xFF3CB371)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E8B57).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.casino, color: Colors.white, size: 36),
            const Gap(AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chơi Game Cashflow',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16)),
                  const Gap(4),
                  Text('Thoát khỏi Rat Race cùng AI Cha Giàu',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSettingsCard() {
    return Material(
      color: AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Provider Choice
          ListTile(
            leading: const Icon(Icons.psychology_outlined,
                size: 22, color: Colors.white70),
            title: Text('Nhà cung cấp',
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProvider,
                dropdownColor: AppColors.surfaceElevatedDark,
                style: Theme.of(context).textTheme.bodyMedium,
                items: const [
                  DropdownMenuItem(
                      value: 'gemini', child: Text('Google Gemini')),
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedProvider = val;
                      _modelCtrl.text = val == 'gemini'
                          ? _geminiModels.first
                          : _openaiModels.first;
                    });
                  }
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDark, indent: 56),

          // Model Selection Input
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
            child: TextFormField(
              controller: _modelCtrl,
              decoration: InputDecoration(
                labelText: 'Mô hình (Model)',
                labelStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.settings_suggest_outlined,
                    size: 20, color: Colors.white70),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDark, indent: 56),

          // API Key Input
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
            child: TextFormField(
              controller: _apiKeyCtrl,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: _selectedProvider == 'gemini'
                    ? 'Gemini API Key'
                    : 'OpenAI API Key',
                labelStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.vpn_key_outlined,
                    size: 20, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureApiKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18),
                  onPressed: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Material(
      color: AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
        title:
            const Text('Đăng xuất', style: TextStyle(color: AppColors.danger)),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surfaceElevatedDark,
              title: const Text('Xác nhận đăng xuất'),
              content: const Text(
                'Bạn sẽ đăng xuất khỏi phiên làm việc offline này. Dữ liệu kịch bản vẫn được giữ lại trên máy.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Đăng xuất',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await ref.read(authProvider.notifier).signOut();
            if (mounted) context.go(AppRoutes.login);
          }
        },
      ),
    );
  }
}
