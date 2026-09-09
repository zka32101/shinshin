import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

// User auth state provider - listens to Firebase auth changes
final userAuthStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.authStateChanges();
});

// Current user profile provider - fetches user profile from Firestore
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(userAuthStateProvider);

  final firebaseUser = authState.when(
    data: (user) => user,
    loading: () => null,
    error: (error, _) => null,
  );

  if (firebaseUser == null) return null;

  final profile = await ref.read(userProfileProvider(firebaseUser.uid).future);
  return profile;
});

// User profile provider - fetches user data from Firestore by UID
final userProfileProvider = FutureProvider.autoDispose.family<User?, String>(
  (ref, uid) async {
    final firebaseService = ref.watch(firebaseServiceProvider);
    return firebaseService.getUserProfile(uid);
  },
);

// Anonymous sign-in provider (小学コレシリーズ共通: メール認証は使用しない)
final anonymousSignInProvider = FutureProvider.autoDispose<firebase_auth.User?>(
  (ref) async {
    final firebaseService = ref.watch(firebaseServiceProvider);
    return firebaseService.signInAnonymously();
  },
);
