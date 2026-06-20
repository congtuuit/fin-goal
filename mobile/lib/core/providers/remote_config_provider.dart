import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_provider.g.dart';

class RemoteConfig {
  final bool enableAds;
  final String adBannerId;
  final String adInterstitialId;
  final bool maintenanceMode;

  const RemoteConfig({
    this.enableAds = false,
    this.adBannerId = '',
    this.adInterstitialId = '',
    this.maintenanceMode = false,
  });
}

@riverpod
class RemoteConfigNotifier extends _$RemoteConfigNotifier {
  @override
  RemoteConfig build() {
    // In the future, this will fetch from Supabase `app_config` table.
    // For now, it returns the default configuration (ads disabled).
    return const RemoteConfig(
      enableAds: false, 
      adBannerId: '',
      adInterstitialId: '',
      maintenanceMode: false,
    );
  }

  Future<void> fetchConfig() async {
    // Mock implementation
    // final response = await supabase.from('app_config').select().single();
    // state = RemoteConfig(enableAds: response['enable_ads'], ...);
    state = const RemoteConfig(
      enableAds: false,
    );
  }
}
