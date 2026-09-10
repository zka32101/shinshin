import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parent_child_comparison.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final parentChildHistoryProvider = FutureProvider.autoDispose
    .family<List<ParentChildComparison>, (String, String)>(
        (ref, args) async {
  final apiService = ref.watch(apiServiceProvider);
  final (parentId, childId) = args;
  return apiService.getParentChildDialogueHistory(parentId, childId);
});

final latestParentChildComparisonProvider = FutureProvider.autoDispose
    .family<ParentChildComparison?, (String, String)>(
        (ref, args) async {
  final apiService = ref.watch(apiServiceProvider);
  final (parentId, childId) = args;
  return apiService.getLatestParentChildComparison(parentId, childId);
});
