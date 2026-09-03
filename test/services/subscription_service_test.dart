import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/services/subscription_service.dart';
import 'package:shougaku_kore_doutoku/models/user.dart';

// Generate mocks with: flutter pub run build_runner build
// Note: For production, use proper Firebase mocking library

void main() {
  group('SubscriptionService', () {
    late SubscriptionService subscriptionService;

    setUp(() {
      subscriptionService = SubscriptionService();
    });

    test('SubscriptionInfo.isInTrial returns true when trial is active', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 7));

      final subscription = SubscriptionInfo(
        status: 'trial',
        plan: 'trial',
        trialStartDate: now,
        trialEndDate: futureDate,
        autoRenewalEnabled: true,
      );

      expect(subscription.isInTrial, isTrue);
      expect(subscription.hasAccess, isTrue);
    });

    test('SubscriptionInfo.isInTrial returns false when trial is expired', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));

      final subscription = SubscriptionInfo(
        status: 'trial',
        plan: 'trial',
        trialStartDate: now.subtract(const Duration(days: 14)),
        trialEndDate: pastDate,
        autoRenewalEnabled: true,
      );

      expect(subscription.isInTrial, isFalse);
      expect(subscription.hasAccess, isFalse);
    });

    test('SubscriptionInfo.daysRemainingInTrial returns correct value', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 7));

      final subscription = SubscriptionInfo(
        status: 'trial',
        plan: 'trial',
        trialStartDate: now,
        trialEndDate: futureDate,
        autoRenewalEnabled: true,
      );

      final daysRemaining = subscription.daysRemainingInTrial;
      expect(daysRemaining, 7);
    });

    test('SubscriptionInfo.hasActiveSubscription returns true for active subscription',
        () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 30));

      final subscription = SubscriptionInfo(
        status: 'active',
        plan: 'monthly',
        subscriptionStartDate: now,
        subscriptionEndDate: futureDate,
        planType: 'monthly',
        autoRenewalEnabled: true,
      );

      expect(subscription.hasActiveSubscription, isTrue);
      expect(subscription.hasAccess, isTrue);
    });

    test('SubscriptionInfo.hasActiveSubscription returns false for expired subscription',
        () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));

      final subscription = SubscriptionInfo(
        status: 'expired',
        plan: 'monthly',
        subscriptionStartDate: now.subtract(const Duration(days: 30)),
        subscriptionEndDate: pastDate,
        planType: 'monthly',
        autoRenewalEnabled: false,
      );

      expect(subscription.hasActiveSubscription, isFalse);
      expect(subscription.hasAccess, isFalse);
    });

    test('SubscriptionInfo JSON serialization works correctly', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 14));

      final subscription = SubscriptionInfo(
        status: 'trial',
        plan: 'trial',
        trialStartDate: now,
        trialEndDate: futureDate,
        autoRenewalEnabled: true,
      );

      final json = subscription.toJson();
      expect(json['status'], 'trial');
      expect(json['plan'], 'trial');
      expect(json['autoRenewalEnabled'], isTrue);
    });

    test('SubscriptionInfo JSON deserialization works correctly', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 14));

      final json = {
        'status': 'trial',
        'plan': 'trial',
        'trialStartDate': now,
        'trialEndDate': futureDate,
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'planType': null,
        'lastPaymentDate': null,
        'autoRenewalEnabled': true,
      };

      final subscription = SubscriptionInfo.fromJson(json);
      expect(subscription.status, 'trial');
      expect(subscription.plan, 'trial');
      expect(subscription.autoRenewalEnabled, isTrue);
    });
  });
}
