import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'subscription_service.dart';
import 'logger_service.dart';

class PaymentService {
  static const String monthlyProductId =
      'jp.petitworks.shougaku_kore_doutoku.monthly';
  static const String yearlyProductId =
      'jp.petitworks.shougaku_kore_doutoku.yearly';

  late final InAppPurchase _iap;
  late final SubscriptionService _subscriptionService;
  late final LoggerService _logger;

  bool _isAvailable = false;

  PaymentService() {
    _iap = InAppPurchase.instance;
    _subscriptionService = SubscriptionService();
    _logger = LoggerService();

    _initializeInAppPurchase();
  }

  void _initializeInAppPurchase() {
    if (Platform.isAndroid) {
      InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
    }
  }

  /// Check if in-app purchase is available
  Future<bool> isAvailable() async {
    try {
      _isAvailable = await _iap.isAvailable();
      _logger.log('IAP available: $_isAvailable');
      return _isAvailable;
    } catch (e) {
      _logger.logError('Failed to check IAP availability', error: e);
      return false;
    }
  }

  /// Get product details
  Future<ProductDetailsResponse> getProductDetails(
      List<String> productIds) async {
    try {
      final response = await _iap.queryProductDetails(productIds.toSet());
      _logger.log('Product details fetched: ${response.productDetails.length}');
      return response;
    } catch (e) {
      _logger.logError('Failed to get product details', error: e);
      rethrow;
    }
  }

  /// Purchase monthly subscription
  Future<bool> purchaseMonthly(String userId) async {
    return _purchaseProduct(userId, monthlyProductId, 'monthly');
  }

  /// Purchase yearly subscription
  Future<bool> purchaseYearly(String userId) async {
    return _purchaseProduct(userId, yearlyProductId, 'yearly');
  }

  /// Internal method to handle purchase
  Future<bool> _purchaseProduct(
    String userId,
    String productId,
    String planType,
  ) async {
    try {
      if (!_isAvailable) {
        final available = await isAvailable();
        if (!available) {
          throw Exception('In-App Purchase not available');
        }
      }

      final response = await getProductDetails([productId]);

      if (response.productDetails.isEmpty) {
        throw Exception('Product not found: $productId');
      }

      final product = response.productDetails.first;

      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      _logger.log('Purchase initiated for product: $productId');
      return true;
    } catch (e) {
      _logger.logError('Failed to purchase product: $productId', error: e);
      rethrow;
    }
  }

  /// Listen to purchase updates
  Stream<List<PurchaseDetails>> getPurchaseUpdates() {
    return _iap.purchaseStream;
  }

  /// Handle purchase results
  Future<void> handlePurchaseUpdate(
    PurchaseDetails purchaseDetails,
    String userId,
  ) async {
    try {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Determine plan type from product ID
        final planType = purchaseDetails.productID == monthlyProductId
            ? 'monthly'
            : 'yearly';

        // Verify receipt
        bool verified = false;
        if (Platform.isIOS) {
          verified = await _subscriptionService.verifyAppleReceipt(
            userId: userId,
            receipt: purchaseDetails.verificationData.localVerificationData,
          );
        } else if (Platform.isAndroid) {
          verified = await _subscriptionService.verifyGooglePlayReceipt(
            userId: userId,
            packageName: 'jp.petitworks.shougaku_kore_doutoku',
            productId: purchaseDetails.productID,
            purchaseToken: purchaseDetails.verificationData.serverVerificationData,
          );
        }

        if (verified && purchaseDetails.purchaseID != null) {
          // Update subscription in Firestore
          await _subscriptionService.activateSubscription(
            userId: userId,
            planType: planType,
            transactionId: purchaseDetails.purchaseID!,
          );

          _logger.log('Purchase completed and verified for user: $userId');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _logger.logError(
            'Purchase error for product: ${purchaseDetails.productID}',
            error: purchaseDetails.error);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _logger.log('Purchase cancelled for product: ${purchaseDetails.productID}');
      }

      // Mark purchase as processed
      try {
        await _iap.completePurchase(purchaseDetails);
      } catch (e) {
        // Purchase might already be completed, ignore error
        _logger.logError('Error completing purchase', error: e);
      }
    } catch (e) {
      _logger.logError('Failed to handle purchase update', error: e);
    }
  }

  /// Complete a purchase
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      await _iap.completePurchase(purchaseDetails);
      _logger.log(
          'Purchase completed: ${purchaseDetails.purchaseID}');
    } catch (e) {
      _logger.logError('Failed to complete purchase', error: e);
      rethrow;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      _logger.log('Purchases restored');
    } catch (e) {
      _logger.logError('Failed to restore purchases', error: e);
      rethrow;
    }
  }

  /// Get pending purchases
  Future<List<PurchaseDetails>> getPendingPurchases() async {
    try {
      final purchases = await _iap.queryPreviousPurchases();
      _logger.log('Found ${purchases.length} past purchases');
      return purchases;
    } catch (e) {
      _logger.logError('Failed to get pending purchases', error: e);
      return [];
    }
  }

  /// Check if a product is purchased
  Future<bool> isProductPurchased(String productId) async {
    try {
      final purchases = await getPendingPurchases();
      return purchases.any((purchase) =>
          purchase.productID == productId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored));
    } catch (e) {
      _logger.logError('Failed to check if product is purchased', error: e);
      return false;
    }
  }
}
