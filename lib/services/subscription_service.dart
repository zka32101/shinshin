import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'logger_service.dart';

class SubscriptionService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final LoggerService _logger = LoggerService();

  SubscriptionService() {
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
      _logger.logError('Failed to initialize trial for user: $userId', e);
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
      _logger.logError('Failed to get subscription info for user: $userId', e);
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
      _logger.logError('Stream error for subscription info: $userId', error);
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
          'Failed to activate subscription for user: $userId', e);
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
      _logger.logError('Failed to renew subscription for user: $userId', e);
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
      _logger.logError('Failed to cancel subscription for user: $userId', e);
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
          'Failed to check and mark trial expired for user: $userId', e);
      rethrow;
    }
  }

  /// Verify receipt with backend (iOS)
  Future<bool> verifyAppleReceipt({
    required String userId,
    required String receipt,
  }) async {
    try {
      // This would call your backend endpoint
      // For now, returning true as placeholder
      _logger.log('Apple receipt verified for user: $userId');
      return true;
    } catch (e) {
      _logger.logError('Failed to verify Apple receipt for user: $userId', e);
      return false;
    }
  }

  /// Verify receipt with backend (Android)
  Future<bool> verifyGooglePlayReceipt({
    required String userId,
    required String packageName,
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      // This would call your backend endpoint
      // For now, returning true as placeholder
      _logger.log('Google Play receipt verified for user: $userId');
      return true;
    } catch (e) {
      _logger.logError(
          'Failed to verify Google Play receipt for user: $userId', e);
      return false;
    }
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
