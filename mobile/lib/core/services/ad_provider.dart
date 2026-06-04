import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider để kiểm tra xem user đã nâng cấp gói Premium (tắt quảng cáo) chưa.
// Hiện tại mặc định là false để test quảng cáo. 
// Sau này có thể link với Supabase hoặc RevenueCat.
final isPremiumProvider = Provider<bool>((ref) {
  return false; 
});

// Provider quyết định có hiển thị quảng cáo hay không
final showAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  return !isPremium;
});
