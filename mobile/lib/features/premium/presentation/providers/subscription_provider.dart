import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_provider.g.dart';

enum SubscriptionTier { free, premium }

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  SubscriptionTier build() {
    // Mock default state
    return SubscriptionTier.free;
  }

  void upgradeToPremium() {
    state = SubscriptionTier.premium;
  }
}

@riverpod
bool isPremiumUser(Ref ref) {
  return ref.watch(subscriptionProvider) == SubscriptionTier.premium;
}
