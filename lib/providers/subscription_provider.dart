import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/subscription_service.dart';
import '../services/payment_service.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

// Service providers
final subscriptionServiceProvider = Provider((ref) {
  return SubscriptionService();
});

final paymentServiceProvider = Provider((ref) {
  return PaymentService();
});

// Get subscription info stream for current user
final subscriptionInfoProvider = StreamProvider.autoDispose((ref) async* {
  final auth = ref.watch(authProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    yield null;
    return;
  }

  yield* subscriptionService.subscriptionInfoStream(userId);
});

// Check if IAP is available
final iapAvailableProvider = FutureProvider.autoDispose((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.isAvailable();
});

// Get product details for monthly subscription
final monthlyProductProvider = FutureProvider.autoDispose((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  final response = await paymentService
      .getProductDetails([PaymentService.monthlyProductId]);
  if (response.productDetails.isNotEmpty) {
    return response.productDetails.first;
  }
  return null;
});

// Get product details for yearly subscription
final yearlyProductProvider = FutureProvider.autoDispose((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  final response = await paymentService
      .getProductDetails([PaymentService.yearlyProductId]);
  if (response.productDetails.isNotEmpty) {
    return response.productDetails.first;
  }
  return null;
});

// Check if has active trial
final isInTrialProvider = FutureProvider.autoDispose((ref) async {
  final subscription = await ref.watch(subscriptionInfoProvider.future);
  return subscription?.isInTrial ?? false;
});

// Check if has active subscription
final hasActiveSubscriptionProvider = FutureProvider.autoDispose((ref) async {
  final subscription = await ref.watch(subscriptionInfoProvider.future);
  return subscription?.hasActiveSubscription ?? false;
});

// Check if has access (either trial or subscription)
final hasAccessProvider = FutureProvider.autoDispose((ref) async {
  final subscription = await ref.watch(subscriptionInfoProvider.future);
  return subscription?.hasAccess ?? false;
});

// Get days remaining in trial
final daysRemainingInTrialProvider = FutureProvider.autoDispose((ref) async {
  final subscription = await ref.watch(subscriptionInfoProvider.future);
  return subscription?.daysRemainingInTrial;
});

// Purchase monthly subscription
final purchaseMonthlyProvider = FutureProvider.autoDispose((ref) async {
  final auth = ref.watch(authProvider);
  final paymentService = ref.watch(paymentServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    await paymentService.purchaseMonthly(userId);
    // Invalidate subscription info to refresh
    ref.invalidate(subscriptionInfoProvider);
    return true;
  } catch (e) {
    rethrow;
  }
});

// Purchase yearly subscription
final purchaseYearlyProvider = FutureProvider.autoDispose((ref) async {
  final auth = ref.watch(authProvider);
  final paymentService = ref.watch(paymentServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    await paymentService.purchaseYearly(userId);
    // Invalidate subscription info to refresh
    ref.invalidate(subscriptionInfoProvider);
    return true;
  } catch (e) {
    rethrow;
  }
});

// Cancel subscription
final cancelSubscriptionProvider = FutureProvider.autoDispose((ref) async {
  final auth = ref.watch(authProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    await subscriptionService.cancelSubscription(userId);
    // Invalidate subscription info to refresh
    ref.invalidate(subscriptionInfoProvider);
    return true;
  } catch (e) {
    rethrow;
  }
});

// Listen to purchase updates
final purchaseUpdateStreamProvider = StreamProvider.autoDispose((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPurchaseUpdates();
});

// Check if monthly product is purchased
final isMonthlyPurchasedProvider = FutureProvider.autoDispose((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.isProductPurchased(
      PaymentService.monthlyProductId);
});

// Check if yearly product is purchased
final isYearlyPurchasedProvider = FutureProvider.autoDispose((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.isProductPurchased(
      PaymentService.yearlyProductId);
});

// Restore purchases
final restorePurchasesProvider = FutureProvider.autoDispose((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  final auth = ref.watch(authProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    await paymentService.restorePurchases();
    // Invalidate subscription info to refresh
    ref.invalidate(subscriptionInfoProvider);
    return true;
  } catch (e) {
    rethrow;
  }
});
