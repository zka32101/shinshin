// RevenueCat Integration Service
// Phase 4.2: Subscription & In-App Purchase Management

import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();

  factory RevenueCatService() {
    return _instance;
  }

  RevenueCatService._internal();

  bool _isInitialized = false;
  final _subscriptionStatusController = StreamController<bool>.broadcast();

  /// Stream of subscription status changes
  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set API key
      await Purchases.configure(
        PurchasesConfiguration(AppConstants.revenueCatApiKey),
      );

      _isInitialized = true;

      // Listen to subscription changes
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      if (kDebugMode) {
        print('[RevenueCat] SDK initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[RevenueCat] Initialization error: $e');
      }
      rethrow;
    }
  }

  /// Check if user has active premium subscription
  Future<bool> isSubscribed() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive = customerInfo.entitlements.active
          .containsKey(AppConstants.premiumEntitlementId);

      if (kDebugMode) {
        print('[RevenueCat] Subscription check: $isActive');
      }

      return isActive;
    } catch (e) {
      if (kDebugMode) {
        print('[RevatureCat] Error checking subscription: $e');
      }
      return false;
    }
  }

  /// Get available offerings (subscription plans)
  Future<List<Package>?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages;
    } catch (e) {
      if (kDebugMode) {
        print('[RevenueCat] Error fetching offerings: $e');
      }
      return null;
    }
  }

  /// Purchase subscription
  Future<bool> purchaseSubscription({
    required Package package,
  }) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isActive = customerInfo.entitlements.active
          .containsKey(AppConstants.premiumEntitlementId);

      if (kDebugMode) {
        print('[RevenueCat] Purchase successful. Active: $isActive');
      }

      _subscriptionStatusController.add(isActive);
      return isActive;
    } on PurchaseException catch (e) {
      if (kDebugMode) {
        print('[RevenueCat] Purchase error: ${e.message}');
      }
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive = customerInfo.entitlements.active
          .containsKey(AppConstants.premiumEntitlementId);

      if (kDebugMode) {
        print('[RevenueCat] Restore successful. Active: $isActive');
      }

      _subscriptionStatusController.add(isActive);
      return isActive;
    } catch (e) {
      if (kDebugMode) {
        print('[RevenueCat] Restore error: $e');
      }
      return false;
    }
  }

  /// Get subscription expiration date
  Future<DateTime?> getSubscriptionExpirationDate() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final expirationDate = customerInfo.entitlements.active
          .values
          .firstOrNull
          ?.expirationDate;
      return expirationDate;
    } catch (e) {
      if (kDebugMode) {
        print('[RevenueCat] Error fetching expiration date: $e');
      }
      return null;
    }
  }

  /// Listen to customer info updates (subscription changes, etc.)
  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    final isActive = customerInfo.entitlements.active
        .containsKey(AppConstants.premiumEntitlementId);
    _subscriptionStatusController.add(isActive);

    if (kDebugMode) {
      print('[RevenueCat] Customer info updated. Active: $isActive');
    }
  }

  /// Clean up resources
  void dispose() {
    _subscriptionStatusController.close();
  }
}
