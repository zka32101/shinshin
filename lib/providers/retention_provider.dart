import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final retentionProvider = StateNotifierProvider<RetentionNotifier, RetentionData>((ref) {
  return RetentionNotifier();
});

class RetentionNotifier extends StateNotifier<RetentionData> {
  RetentionNotifier() : super(const RetentionData(lastLoginDate: null, offboardDays: 0, bonusCoins: 0, hasReceivedBonus: false)) {
    _initializeRetention();
  }

  Future<void> _initializeRetention() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login');
    if (lastLogin != null) {
      final lastDate = DateTime.parse(lastLogin);
      final offboardDays = DateTime.now().difference(lastDate).inDays;
      int bonusCoins = offboardDays >= 1 && offboardDays <= 7 ? 50 + (offboardDays * 10) : offboardDays > 7 ? 200 : 0;
      state = RetentionData(lastLoginDate: lastDate, offboardDays: offboardDays, bonusCoins: bonusCoins, hasReceivedBonus: prefs.getBool('retention_bonus_received') ?? false);
    }
  }

  Future<void> claimBonus() async {
    if (!state.hasReceivedBonus && state.bonusCoins > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('retention_bonus_received', true);
      state = state.copyWith(hasReceivedBonus: true);
    }
  }
}

class RetentionData {
  final DateTime? lastLoginDate;
  final int offboardDays;
  final int bonusCoins;
  final bool hasReceivedBonus;

  const RetentionData({required this.lastLoginDate, required this.offboardDays, required this.bonusCoins, required this.hasReceivedBonus});

  RetentionData copyWith({bool? hasReceivedBonus}) => RetentionData(lastLoginDate: lastLoginDate, offboardDays: offboardDays, bonusCoins: bonusCoins, hasReceivedBonus: hasReceivedBonus ?? this.hasReceivedBonus);
}
