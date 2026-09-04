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

/// Custom exceptions for Firebase operations
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, [this.code]);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => message;
}

class FirebaseService {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  final LoggerService _logger = LoggerService();

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
    // Validate input
    final emailError = validateEmail(email);
    if (emailError != null) {
      throw ValidationException(emailError);
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.log('User signed in: $email');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _logger.logError('Sign in failed for email: $email', error: e);
      throw AuthException(
        'Sign in failed: ${e.message}',
        e.code,
      );
    } catch (e) {
      _logger.logError('Unexpected error during sign in', error: e);
      rethrow;
    }
  }

  Future<User?> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    // Validate input
    final emailError = validateEmail(email);
    if (emailError != null) {
      throw ValidationException(emailError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      throw ValidationException(passwordError);
    }

    final displayNameError = validateDisplayName(displayName);
    if (displayNameError != null) {
      throw ValidationException(displayNameError);
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('User creation returned null');
      }

      await credential.user!.updateDisplayName(displayName);
      _logger.log('User registered successfully: $email');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _logger.logError('Registration failed for email: $email', error: e);
      throw AuthException(
        'Registration failed: ${e.message}',
        e.code,
      );
    } catch (e) {
      _logger.logError('Unexpected error during registration', error: e);
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
    // Validate input
    final emailError = validateEmail(email);
    if (emailError != null) {
      throw ValidationException(emailError);
    }

    final displayNameError = validateDisplayName(displayName);
    if (displayNameError != null) {
      throw ValidationException(displayNameError);
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'childrenIds': childrenIds,
        'role': 'parent',
        'subscription': {
          'plan': 'free',
          'status': 'active',
          'startDate': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Initialize trial for new user
      final subscriptionService = SubscriptionService();
      await subscriptionService.initializeTrialForNewUser(uid);

      _logger.log('User profile created and trial initialized: $uid');
    } catch (e) {
      _logger.logError('Failed to save user profile', error: e);
      rethrow;
    }
  }

  Future<app_models.User?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        _logger.log('User profile not found: $uid');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        _logger.logError('User document exists but has no data: $uid', error: null);
        return null;
      }

      final subData = data['subscription'] as Map<String, dynamic>? ?? {};

      return app_models.User(
        uid: uid,
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String? ?? '',
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
      _logger.logError('Failed to get user profile: $uid', error: e);
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
      if (!doc.exists) {
        throw Exception('Story not found: $storyId');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Story document exists but has no data: $storyId');
      }

      return Story.fromJson({...data, 'id': doc.id});
    } catch (e) {
      _logger.logError('Failed to fetch story: $storyId', error: e);
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
      if (!doc.exists) {
        throw Exception('Quiz session not found: $sessionId');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Quiz session document exists but has no data: $sessionId');
      }

      return QuizSession.fromJson({...data, 'id': doc.id});
    } catch (e) {
      _logger.logError('Failed to fetch quiz session: $sessionId', error: e);
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
      if (!doc.exists) {
        throw Exception('Child profile not found: $childId');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Child profile document exists but has no data: $childId');
      }

      return ChildProfile.fromJson({...data, 'id': doc.id});
    } catch (e) {
      _logger.logError('Failed to fetch child profile: $childId', error: e);
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

  // ========================================================
  // Validation Functions
  // ========================================================

  /// Validates email format
  String? validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validates password strength
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates display name
  String? validateDisplayName(String displayName) {
    if (displayName.isEmpty) {
      return 'Display name cannot be empty';
    }
    if (displayName.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (displayName.length > 100) {
      return 'Display name must be less than 100 characters';
    }
    return null;
  }

  // ========================================================
  // Parental Consent Methods (COPPA Compliance)
  // ========================================================

  /// Saves parental consent to Firestore for audit trail
  Future<void> saveParentalConsent({
    required String parentUid,
    required String childEmail,
    required Map<String, bool> consentData,
    String privacyPolicyVersion = '1.0',
  }) async {
    try {
      final consentId =
          _firestore.collection('parental_consents').doc().id;

      await _firestore.collection('parental_consents').doc(consentId).set({
        'id': consentId,
        'parentUid': parentUid,
        'childEmail': childEmail,
        'consentedAt': FieldValue.serverTimestamp(),
        'privacyPolicyVersion': privacyPolicyVersion,
        'consentTo': {
          'dataProcessing': consentData['dataProcessing'] ?? false,
          'thirdPartySharing': consentData['thirdPartySharing'] ?? false,
          'analyticsTracking': consentData['analyticsTracking'] ?? false,
        },
      });

      _logger.log(
        'Parental consent saved successfully for parent: $parentUid, child: $childEmail',
      );
    } catch (e) {
      _logger.logError('Failed to save parental consent', error: e);
      rethrow;
    }
  }

  /// Revokes parental consent (for COPPA compliance - parent can revoke anytime)
  Future<void> revokeParentalConsent(String consentId) async {
    try {
      await _firestore
          .collection('parental_consents')
          .doc(consentId)
          .update({
        'revokedAt': FieldValue.serverTimestamp(),
      });

      _logger.log('Parental consent revoked: $consentId');
    } catch (e) {
      _logger.logError('Failed to revoke parental consent', error: e);
      rethrow;
    }
  }

  /// Fetches parental consent records for a parent
  Future<List<Map<String, dynamic>>> getParentalConsents(
      String parentUid) async {
    try {
      final snapshot = await _firestore
          .collection('parental_consents')
          .where('parentUid', isEqualTo: parentUid)
          .where('revokedAt', isNull: true)
          .get();

      _logger
          .log('Fetched ${snapshot.docs.length} active consents for parent');
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.logError('Failed to fetch parental consents', error: e);
      rethrow;
    }
  }
}
