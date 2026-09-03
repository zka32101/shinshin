import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/distribution_response.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final distributionProvider = FutureProvider.autoDispose
    .family<DistributionResponse, String>((ref, storyId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDistribution(storyId);
});
