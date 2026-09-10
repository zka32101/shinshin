import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/revisit_schedule.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final revisitStoriesProvider = FutureProvider.autoDispose
    .family<List<RevisitStory>, String>((ref, userId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRevisitStories(userId);
});

final revisitResultProvider = FutureProvider.autoDispose
    .family<RevisitResult, (String, String)>((ref, args) async {
  final apiService = ref.watch(apiServiceProvider);
  final (revisitId, answerChoice) = args;
  return apiService.answerRevisitStory(revisitId, answerChoice);
});
