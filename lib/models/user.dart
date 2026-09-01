import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String uid;
  final String email;
  final String displayName;
  final List<String> childrenIds;
  final String role; // "parent"
  final SubscriptionInfo subscription;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.childrenIds,
    this.role = "parent",
    required this.subscription,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class SubscriptionInfo {
  final String plan; // "free" | "plus_980" | "trial" | "monthly" | "yearly"
  final String status; // "trial" | "active" | "expired" | "cancelled"
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final String? planType; // "monthly" | "yearly"
  final DateTime? lastPaymentDate;
  final bool autoRenewalEnabled;
  final DateTime? startDate; // Legacy field for backward compatibility
  final DateTime? renewalDate; // Legacy field for backward compatibility

  SubscriptionInfo({
    required this.plan,
    required this.status,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.planType,
    this.lastPaymentDate,
    this.autoRenewalEnabled = true,
    this.startDate,
    this.renewalDate,
  });

  /// Returns the number of days remaining in trial (null if not in trial)
  int? get daysRemainingInTrial {
    if (status != 'trial' || trialEndDate == null) return null;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }

  /// Returns true if user is currently in trial
  bool get isInTrial {
    if (status != 'trial') return false;
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Returns true if user has active subscription
  bool get hasActiveSubscription {
    if (status != 'active') return false;
    if (subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(subscriptionEndDate!);
  }

  /// Returns true if user has either trial or active subscription
  bool get hasAccess {
    return isInTrial || hasActiveSubscription;
  }

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionInfoToJson(this);
}
