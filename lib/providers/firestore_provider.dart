import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';

/// FirestoreService のシングルトン Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 現在ログイン中のユーザー UID を提供するヘルパー Provider
/// 未ログインの場合は null を返す（ゲスト扱い）
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(userAuthStateProvider).asData?.value?.uid;
});
