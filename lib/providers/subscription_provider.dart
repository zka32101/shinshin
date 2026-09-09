// Subscription Provider
// Phase 4.2: RevenueCat-based subscription state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';
import '../utils/constants.dart';

// ─── Subscription Status Provider ───────────────────────────────────────────
// Notifier for subscription state

class SubscriptionNotifier extends StateNotifier<AsyncValue<bool>> {
  final RevenueCatService _revenueCat;

  SubscriptionNotifier(this._revenueCat) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _revenueCat.initialize();
      final isSubscribed = await _revenueCat.isSubscribed();
      state = AsyncValue.data(isSubscribed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Purchase subscription
  Future<void> purchaseSubscription() async {
    try {
      final offerings = await _revenueCat.getOfferings();
      if (offerings == null || offerings.isEmpty) {
        throw Exception('No offerings available');
      }

      // Get the monthly package (adjust logic if multiple packages)
      final monthlyPackage = offerings.firstWhere(
        (pkg) =>
            pkg.identifier.contains(AppConstants.subscriptionProductId) ||
            pkg.packageType == PackageType.monthly,
        orElse: () => offerings.first,
      );

      state = const AsyncValue.loading();
      final success = await _revenueCat.purchaseSubscription(
        package: monthlyPackage,
      );

      if (success) {
        state = const AsyncValue.data(true);
      } else {
        throw Exception('Purchase failed');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      state = const AsyncValue.loading();
      final success = await _revenueCat.restorePurchases();
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    try {
      final isSubscribed = await _revenueCat.isSubscribed();
      state = AsyncValue.data(isSubscribed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Subscription status provider (watch this in UI)
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<bool>>((ref) {
  final revenueCat = RevenueCatService();
  return SubscriptionNotifier(revenueCat);
});

// ─── Subscription Details Provider ─────────────────────────────────────────

class SubscriptionDetailsNotifier
    extends StateNotifier<AsyncValue<SubscriptionDetails>> {
  final RevenueCatService _revenueCat;

  SubscriptionDetailsNotifier(this._revenueCat)
      : super(const AsyncValue.loading()) {
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final offerings = await _revenueCat.getOfferings();
      if (offerings == null || offerings.isEmpty) {
        throw Exception('No offerings available');
      }

      final monthlyPackage = offerings.firstWhere(
        (pkg) => pkg.packageType == PackageType.monthly,
        orElse: () => offerings.first,
      );

      final expirationDate = await _revenueCat.getSubscriptionExpirationDate();
      final isSubscribed = await _revenueCat.isSubscribed();

      state = AsyncValue.data(
        SubscriptionDetails(
          packageId: monthlyPackage.identifier,
          price: monthlyPackage.storeProduct.priceString,
          localizedPrice: monthlyPackage.storeProduct.priceString,
          currencyCode: monthlyPackage.storeProduct.currencyCode ?? 'JPY',
          expirationDate: expirationDate,
          isActive: isSubscribed,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _loadDetails();
}

/// Subscription details provider
final subscriptionDetailsProvider = StateNotifierProvider<
    SubscriptionDetailsNotifier,
    AsyncValue<SubscriptionDetails>>((ref) {
  final revenueCat = RevenueCatService();
  return SubscriptionDetailsNotifier(revenueCat);
});

// ─── Models ────────────────────────────────────────────────────────────────

class SubscriptionDetails {
  final String packageId;
  final String price;
  final String localizedPrice;
  final String currencyCode;
  final DateTime? expirationDate;
  final bool isActive;

  SubscriptionDetails({
    required this.packageId,
    required this.price,
    required this.localizedPrice,
    required this.currencyCode,
    required this.expirationDate,
    required this.isActive,
  });

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  String get expirationText {
    if (expirationDate == null) return '未取得';
    return '${expirationDate!.year}年${expirationDate!.month}月${expirationDate!.day}日';
  }
}
