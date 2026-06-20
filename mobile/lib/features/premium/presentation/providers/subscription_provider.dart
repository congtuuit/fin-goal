import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';

part 'subscription_provider.g.dart';

enum SubscriptionTier { free, pro, premium }

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  SubscriptionTier build() {
    // Mock default state
    return SubscriptionTier.free;
  }

  void upgradeToPro() {
    state = SubscriptionTier.pro;
  }

  void upgradeToPremium() {
    state = SubscriptionTier.premium;
  }
}

@riverpod
bool isPremiumUser(Ref ref) {
  return ref.watch(subscriptionProvider) == SubscriptionTier.premium;
}

@riverpod
int totalAllowedGoals(Ref ref) {
  final tier = ref.watch(subscriptionProvider);
  final profileState = ref.watch(profileProvider);
  
  int baseLimit = (tier == SubscriptionTier.premium || tier == SubscriptionTier.pro) ? 10 : 2;
  
  int extraSlots = 0;
  if (profileState is ProfileLoaded && profileState.profile != null) {
    extraSlots = profileState.profile!.purchasedGoalSlots
        .where((expiry) => expiry.isAfter(DateTime.now()))
        .length;
  }
  
  return baseLimit + extraSlots;
}

@riverpod
bool canCreateNewGoal(Ref ref, int currentActiveGoals) {
  if (currentActiveGoals >= 10) return false;
  
  int totalAllowed = ref.watch(totalAllowedGoalsProvider);
  return currentActiveGoals < totalAllowed;
}

@riverpod
int getGoalSlotPrice(Ref ref, int currentActiveGoals) {
  return 39000;
}
