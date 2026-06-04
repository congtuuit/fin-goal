import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider để kiểm tra xem user đã nâng cấp gói Premium (tắt quảng cáo) chưa.
// Hiện tại mặc định là false để test quảng cáo. 
// Sau này có thể link với Supabase hoặc RevenueCat.
final isPremiumProvider = Provider<bool>((ref) {
  return false; 
});

// Cờ bật/tắt toàn bộ quảng cáo trên hệ thống (Sẵn sàng kết nối Remote Config)
class GlobalAdsEnabled extends Notifier<bool> {
  @override
  bool build() => true;
  
  void setEnabled(bool value) => state = value;
}

final globalAdsEnabledProvider = NotifierProvider<GlobalAdsEnabled, bool>(GlobalAdsEnabled.new);

// Provider quyết định có hiển thị quảng cáo hay không
final showAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  final isGlobalEnabled = ref.watch(globalAdsEnabledProvider);
  
  return isGlobalEnabled && !isPremium;
});
