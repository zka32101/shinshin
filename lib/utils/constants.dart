// Application Constants
// Phase 4.2: RevenueCat Configuration
// Phase 4.7: Unified RevenueCat Configuration via shared_core

class AppConstants {
  // RevenueCat Configuration (Phase 4.7: Moved to shared_core SubscriptionConfig)
  // - revenueCatApiKey: Use SubscriptionConfig.apiKey
  // - subscriptionProductId: Use SubscriptionConfig.monthlyProductId / annualProductId
  // - premiumEntitlementId: Use SubscriptionConfig.premiumEntitlementId

  // Feature Flags
  static const bool adsFreeWithSubscription = true;
  static const bool unlimitedQuizzesWithSubscription = true;

  // Pricing (for display - matches SubscriptionConfig.monthlyPrice)
  static const String monthlyPrice = '¥300';
  static const int trialDays = 7;

  // App info
  static const String appName = '小学コレ！道徳';
  static const String appVersion = '1.0.0';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String storiesCollection = 'stories';
  static const String progressCollection = 'progress';
}
