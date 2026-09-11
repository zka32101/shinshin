import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kindness_mission.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final currentKindnessMissionProvider = FutureProvider.autoDispose
    .family<KindnessMission, String>((ref, userId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCurrentMission(userId);
});

final kindnessMapProvider = FutureProvider.autoDispose
    .family<KindnessMap, (String, String)>((ref, args) async {
  final apiService = ref.watch(apiServiceProvider);
  final (userId, month) = args;
  return apiService.getKindnessMap(userId, month);
});
