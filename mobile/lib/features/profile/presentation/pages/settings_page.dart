import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/direct_client_ai_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _obscureApiKey = true;

  // Form State
  String _selectedProvider = 'gemini';
  final _apiKeyCtrl = TextEditingController();
  String _selectedModel = 'gemini-1.5-flash';

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
      _selectedProvider = _prefs.getString(DirectClientAiService.keyProvider) ?? 'gemini';
      _apiKeyCtrl.text = _prefs.getString(DirectClientAiService.keyApiKey) ?? '';
      
      final savedModel = _prefs.getString(DirectClientAiService.keyModel) ?? '';
      if (_selectedProvider == 'gemini') {
        _selectedModel = _geminiModels.contains(savedModel) ? savedModel : _geminiModels.first;
      } else {
        _selectedModel = _openaiModels.contains(savedModel) ? savedModel : _openaiModels.first;
      }
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _prefs.setString(DirectClientAiService.keyProvider, _selectedProvider);
      await _prefs.setString(DirectClientAiService.keyApiKey, _apiKeyCtrl.text.trim());
      await _prefs.setString(DirectClientAiService.keyModel, _selectedModel);

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

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Hồ sơ'),
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
                  _buildUserInfoCard(user),
                  const Gap(AppSizes.xl),

                  // 2. AI Settings Panel
                  Text(
                    'Cấu hình AI (Mô phỏng What-If)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const Gap(AppSizes.md),
                  _buildAiSettingsCard(),
                  const Gap(AppSizes.xxl),

                  // 3. Action Buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu cấu hình'),
                    onPressed: _saveSettings,
                  ),
                  const Gap(AppSizes.md),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất khỏi thiết bị'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
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
                              child: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (mounted) context.go(AppRoutes.login);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard(dynamic user) {
    final displayName = user?.displayName ?? 'Người dùng Offline';
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const Gap(AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Gap(4),
                const Text(
                  'Chế độ: Offline-first (Lưu trữ cục bộ)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Choice
          const Text('Chọn nhà cung cấp AI', style: TextStyle(fontWeight: FontWeight.w500)),
          const Gap(AppSizes.xs),
          DropdownButtonFormField<String>(
            value: _selectedProvider,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.psychology_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'gemini', child: Text('Google Gemini (Khuyên dùng)')),
              DropdownMenuItem(value: 'openai', child: Text('OpenAI (ChatGPT)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedProvider = val;
                  // Reset model mặc định tương ứng với provider
                  _selectedModel = val == 'gemini' ? _geminiModels.first : _openaiModels.first;
                });
              }
            },
          ),
          const Gap(AppSizes.lg),

          // API Key Input
          const Text('Nhập API Key cá nhân của bạn', style: TextStyle(fontWeight: FontWeight.w500)),
          const Gap(AppSizes.xs),
          TextFormField(
            controller: _apiKeyCtrl,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              labelText: _selectedProvider == 'gemini' ? 'Gemini API Key' : 'OpenAI API Key',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
              hintText: _selectedProvider == 'gemini' ? 'AIzaSy...' : 'sk-...',
            ),
          ),
          const Gap(AppSizes.lg),

          // Model Selection
          const Text('Chọn mô hình (Model)', style: TextStyle(fontWeight: FontWeight.w500)),
          const Gap(AppSizes.xs),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.settings_suggest_outlined),
            ),
            items: (_selectedProvider == 'gemini' ? _geminiModels : _openaiModels)
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedModel = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
