import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/progress.dart';
import '../models/user.dart' as app_models;
import '../models/story.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/child_profile.dart';
import 'subscription_service.dart';
import 'logger_service.dart';

class FirebaseService {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  FirebaseService() {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  Future<void> enableEmulator() async {
    try {
      await _auth.useAuthEmulator('localhost', 9099);
      _firestore.useFirestoreEmulator('localhost', 8080);
    } catch (e) {
      // Already enabled or not available
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<User?> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> saveUserProfile(
    String uid,
    String email,
    String displayName,
    List<String> childrenIds,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'childrenIds': childrenIds,
        'role': 'parent',
        'subscription': {
          'plan': 'free',
          'status': 'active',
          'startDate': DateTime.now().toIso8601String(),
        },
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Initialize trial for new user
      final subscriptionService = SubscriptionService();
      await subscriptionService.initializeTrialForNewUser(uid);

      LoggerService().log('User profile created and trial initialized: $uid');
    } catch (e) {
      LoggerService().logError('Failed to save user profile', e);
      rethrow;
    }
  }

  Future<app_models.User?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final subData = data['subscription'] as Map<String, dynamic>? ?? {};

      return app_models.User(
        uid: uid,
        email: data['email'] as String,
        displayName: data['displayName'] as String,
        childrenIds: List<String>.from(data['childrenIds'] as List? ?? []),
        role: data['role'] as String? ?? 'parent',
        subscription: app_models.SubscriptionInfo(
          plan: subData['plan'] as String? ?? 'free',
          status: subData['status'] as String? ?? 'active',
          startDate: subData['startDate'] != null
              ? DateTime.parse(subData['startDate'] as String)
              : null,
          renewalDate: subData['renewalDate'] != null
              ? DateTime.parse(subData['renewalDate'] as String)
              : null,
        ),
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'] as String)
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? DateTime.parse(data['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveProgress(Progress progress) async {
    await _firestore
        .collection('progress')
        .doc(progress.id)
        .set(progress.toJson());
  }

  Future<List<Progress>> fetchProgress(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection('progress')
          .where('childId', isEqualTo: childId)
          .get();

      return querySnapshot.docs
          .map((doc) => Progress.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Progress>> subscribeToProgressUpdates(String childId) {
    return _firestore
        .collection('progress')
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => Progress.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Story methods
  Future<List<Story>> fetchStories() async {
    try {
      final querySnapshot =
          await _firestore.collection('stories').orderBy('createdAt').get();

      return querySnapshot.docs
          .map((doc) => Story.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Story>> subscribeToStories() {
    return _firestore
        .collection('stories')
        .orderBy('createdAt')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => Story.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<Story> fetchStory(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();
      if (!doc.exists) throw Exception('Story not found');

      return Story.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      rethrow;
    }
  }

  // Question methods
  Future<List<Question>> fetchQuestions(String storyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('storyId', isEqualTo: storyId)
          .orderBy('questionNumber')
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // QuizSession methods
  Future<void> saveQuizSession(QuizSession session) async {
    try {
      await _firestore
          .collection('quiz_sessions')
          .doc(session.id)
          .set(session.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<QuizSession> fetchQuizSession(String sessionId) async {
    try {
      final doc =
          await _firestore.collection('quiz_sessions').doc(sessionId).get();
      if (!doc.exists) throw Exception('Quiz session not found');

      return QuizSession.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizSession>> fetchQuizSessions(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_sessions')
          .where('childId', isEqualTo: childId)
          .orderBy('startedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizSession.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ChildProfile methods
  Future<void> saveChildProfile(ChildProfile profile) async {
    try {
      await _firestore
          .collection('child_profiles')
          .doc(profile.id)
          .set(profile.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateChildProfile(ChildProfile profile) async {
    try {
      await _firestore
          .collection('child_profiles')
          .doc(profile.id)
          .update(profile.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteChildProfile(String childId) async {
    try {
      await _firestore.collection('child_profiles').doc(childId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<ChildProfile> fetchChildProfile(String childId) async {
    try {
      final doc =
          await _firestore.collection('child_profiles').doc(childId).get();
      if (!doc.exists) throw Exception('Child profile not found');

      return ChildProfile.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChildProfile>> fetchChildProfiles(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('child_profiles')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChildProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
