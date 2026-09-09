import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'logger_service.dart';

class SubscriptionService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final ApiService _apiService;
  final LoggerService _logger = LoggerService();

  SubscriptionService({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  /// Initialize trial for a new user
  Future<void> initializeTrialForNewUser(String userId) async {
    try {
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 14));

      final subscription = SubscriptionInfo(
        plan: 'trial',
        status: 'trial',
        trialStartDate: now,
        trialEndDate: trialEndDate,
        planType: null,
        lastPaymentDate: null,
        autoRenewalEnabled: true,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('info')
          .set({
        'status': subscription.status,
        'plan': subscription.plan,
        'trialStartDate': Timestamp.fromDate(subscription.trialStartDate!),
        'trialEndDate': Timestamp.fromDate(trialEndDate),
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'planType': null,
        'lastPaymentDate': null,
        'autoRenewalEnabled': true,
      });

      _logger.log('Trial initialized for user: $userId');
    } catch (e) {
      _logger.logError('Failed to initialize trial for user: $userId', error: e);
      rethrow;
    }
  }

  /// Get subscription info for current user
  Future<SubscriptionInfo?> getSubscriptionInfo(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('info')
          .get();

      if (!doc.exists) {
        return null;
      }

      return _subscriptionFromFirestore(doc.data()!);
    } catch (e) {
      _logger.logError('Failed to get subscription info for user: $userId', error: e);
      rethrow;
    }
  }

  /// Stream subscription info (for real-time updates)
  Stream<SubscriptionInfo?> subscriptionInfoStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('info')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return _subscriptionFromFirestore(snapshot.data()!);
    }).handleError((error) {
      _logger.logError('Stream error for subscription info: $userId', error: error);
    });
  }

  /// Update subscription to active state after purchase
  Future<void> activateSubscription({
    required String userId,
    required String planType, // 'monthly' or 'yearly'
    required String transactionId,
  }) async {
    try {
      final now = DateTime.now();
      final subscriptionEndDate = planType == 'yearly'
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('info')
          .update({
        'status': 'active',
        'plan': planType == 'yearly' ? 'yearly' : 'monthly',
        'planType': planType,
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
        'lastPaymentDate': Timestamp.fromDate(now),
        'autoRenewalEnabled': true,
        'transactionId': transactionId,
      });

      _logger.log('Subscription activated for user: $userId, plan: $planType');
    } catch (e) {
      _logger.logError(
          'Failed to activate subscription for user: $userId', error: e);
      rethrow;
    }
  }

  /// Renew subscription (extends the end date)
  Future<void> renewSubscription({
    required String userId,
    required String planType,
    required String transactionId,
  }) async {
    try {
      final currentSub = await getSubscriptionInfo(userId);
      if (currentSub == null) {
        throw Exception('Subscription not found');
      }

      final now = DateTime.now();
      final newEndDate = planType == 'yearly'
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('info')
          .update({
        'subscriptionEndDate': Timestamp.fromDate(newEndDate),
        'lastPaymentDate': Timestamp.fromDate(now),
        'transactionId': transactionId,
      });

      _logger.log('Subscription renewed for user: $userId');
    } catch (e) {
      _logger.logError('Failed to renew subscription for user: $userId', error: e);
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('info')
          .update({
        'status': 'cancelled',
        'autoRenewalEnabled': false,
      });

      _logger.log('Subscription cancelled for user: $userId');
    } catch (e) {
      _logger.logError('Failed to cancel subscription for user: $userId', error: e);
      rethrow;
    }
  }

  /// Check if trial has expired and mark as expired if needed
  Future<void> checkAndMarkTrialExpired(String userId) async {
    try {
      final sub = await getSubscriptionInfo(userId);
      if (sub == null) {
        _logger.log('No subscription found for user: $userId');
        return;
      }

      if (!sub.isInTrial) {
        _logger.log('User is not in trial: $userId');
        return;
      }

      // Safely check daysRemainingInTrial (it should be non-null if isInTrial is true)
      final daysRemaining = sub.daysRemainingInTrial;
      if (daysRemaining == null || daysRemaining <= 0) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('subscription')
            .doc('info')
            .update({
          'status': 'expired',
        });

        _logger.log('Trial marked as expired for user: $userId');
      }
    } catch (e) {
      _logger.logError(
          'Failed to check and mark trial expired for user: $userId', error: e);
      rethrow;
    }
  }

  /// Verify a StoreKit2 transaction with the backend (iOS).
  ///
  /// [transactionId] is the App Store transaction identifier
  /// (`PurchaseDetails.purchaseID` from the `in_app_purchase` package),
  /// which the backend looks up via the App Store Server API.
  /// On success, the backend-verified subscription state (plan/expiry) is
  /// written to Firestore so the client's cached subscription reflects only
  /// server-verified data — the app never trusts a client-reported "verified"
  /// flag on its own.
  Future<bool> verifyAppleReceipt({
    required String userId,
    required String productId,
    required String transactionId,
  }) async {
    try {
      final result = await _apiService.verifyApplePurchase(
        productId: productId,
        transactionId: transactionId,
      );

      final verified = result['verified'] == true && result['isPremium'] == true;
      if (verified) {
        await _applyVerifiedSubscription(userId: userId, result: result);
        _logger.log('Apple receipt verified for user: $userId');
      } else {
        _logger.log('Apple receipt verification did not grant premium for user: $userId');
      }
      return verified;
    } catch (e) {
      _logger.logError('Failed to verify Apple receipt for user: $userId', error: e);
      return false;
    }
  }

  /// Verify a Google Play purchase token with the backend (Android).
  ///
  /// The backend calls the Google Play Developer API
  /// (`purchases.subscriptions.get`) with a service account and only then
  /// marks the subscription active — the app never trusts the client's own
  /// "verified" claim.
  Future<bool> verifyGooglePlayReceipt({
    required String userId,
    required String packageName,
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      final result = await _apiService.verifyGooglePlayPurchase(
        productId: productId,
        purchaseToken: purchaseToken,
        packageName: packageName,
      );

      final verified = result['verified'] == true && result['isPremium'] == true;
      if (verified) {
        await _applyVerifiedSubscription(userId: userId, result: result);
        _logger.log('Google Play receipt verified for user: $userId');
      } else {
        _logger.log('Google Play receipt verification did not grant premium for user: $userId');
      }
      return verified;
    } catch (e) {
      _logger.logError(
          'Failed to verify Google Play receipt for user: $userId', error: e);
      return false;
    }
  }

  /// Writes the backend-verified subscription state to Firestore.
  /// Only ever called with data returned by the backend's purchase
  /// verification endpoints — never with client-supplied values.
  Future<void> _applyVerifiedSubscription({
    required String userId,
    required Map<String, dynamic> result,
  }) async {
    final planType = result['planType'] as String? ?? 'monthly';
    final transactionId = result['transactionId'] as String? ?? '';
    final expiresAtRaw = result['expiresAt'] as String?;
    final now = DateTime.now();
    final subscriptionEndDate =
        expiresAtRaw != null ? DateTime.parse(expiresAtRaw) : now.add(const Duration(days: 30));

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('info')
        .set({
      'status': 'active',
      'plan': planType,
      'planType': planType,
      'subscriptionStartDate': Timestamp.fromDate(now),
      'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
      'lastPaymentDate': Timestamp.fromDate(now),
      'autoRenewalEnabled': true,
      'transactionId': transactionId,
    }, SetOptions(merge: true));
  }

  /// Helper: Convert Firestore document to SubscriptionInfo
  SubscriptionInfo _subscriptionFromFirestore(Map<String, dynamic> data) {
    return SubscriptionInfo(
      status: data['status'] ?? 'trial',
      plan: data['plan'] ?? 'trial',
      trialStartDate: data['trialStartDate'] != null
          ? (data['trialStartDate'] as Timestamp).toDate()
          : null,
      trialEndDate: data['trialEndDate'] != null
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
      subscriptionStartDate: data['subscriptionStartDate'] != null
          ? (data['subscriptionStartDate'] as Timestamp).toDate()
          : null,
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? (data['subscriptionEndDate'] as Timestamp).toDate()
          : null,
      planType: data['planType'],
      lastPaymentDate: data['lastPaymentDate'] != null
          ? (data['lastPaymentDate'] as Timestamp).toDate()
          : null,
      autoRenewalEnabled: data['autoRenewalEnabled'] ?? true,
    );
  }
}
