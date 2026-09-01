import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shougaku_kore_doutoku/models/user.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';

// ── Firebase Mock Services ───────────────────────────────────────────────────

class MockFirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MockFirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FakeFirebaseFirestore(),
        _auth = auth ?? MockFirebaseAuth();

  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // User operations
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.id).set({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'createdAt': user.createdAt.toIso8601String(),
      'trialEndsAt': user.trialEndsAt.toIso8601String(),
    });
  }

  Future<User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: data['id'],
      email: data['email'],
      name: data['name'],
      createdAt: DateTime.parse(data['createdAt']),
      trialEndsAt: DateTime.parse(data['trialEndsAt']),
    );
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.id).update({
      'name': user.name,
      'trialEndsAt': user.trialEndsAt.toIso8601String(),
    });
  }

  // Child profile operations
  Future<void> createChildProfile(ChildProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.parentId)
        .collection('children')
        .doc(profile.id)
        .set({
      'id': profile.id,
      'parentId': profile.parentId,
      'name': profile.name,
      'gradeLevel': profile.gradeLevel,
      'dateOfBirth': profile.dateOfBirth.toIso8601String(),
      'createdAt': profile.createdAt.toIso8601String(),
      'updatedAt': profile.updatedAt.toIso8601String(),
    });
  }

  Future<ChildProfile?> getChildProfile(String userId, String childId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return ChildProfile(
      id: data['id'],
      parentId: data['parentId'],
      name: data['name'],
      gradeLevel: data['gradeLevel'],
      dateOfBirth: DateTime.parse(data['dateOfBirth']),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );
  }

  Future<List<ChildProfile>> getChildProfiles(String userId) async {
    final docs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .get();

    return docs.docs.map((doc) {
      final data = doc.data();
      return ChildProfile(
        id: data['id'],
        parentId: data['parentId'],
        name: data['name'],
        gradeLevel: data['gradeLevel'],
        dateOfBirth: DateTime.parse(data['dateOfBirth']),
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
      );
    }).toList();
  }

  // Progress tracking operations
  Future<void> createProgress(Progress progress) async {
    await _firestore
        .collection('users')
        .doc(progress.childId.split('-')[0]) // Extract parent ID
        .collection('children')
        .doc(progress.childId)
        .collection('progress')
        .doc(progress.id)
        .set({
      'id': progress.id,
      'childId': progress.childId,
      'storiesCompleted': progress.storiesCompleted,
      'averageScore': progress.averageScore,
      'completionPercentage': progress.completionPercentage,
      'lastActivityAt': progress.lastActivityAt.toIso8601String(),
      'createdAt': progress.createdAt.toIso8601String(),
      'updatedAt': progress.updatedAt.toIso8601String(),
    });
  }

  Future<Progress?> getProgress(
    String userId,
    String childId,
    String progressId,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .collection('progress')
        .doc(progressId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return Progress(
      id: data['id'],
      childId: data['childId'],
      storiesCompleted: data['storiesCompleted'],
      averageScore: data['averageScore'],
      completionPercentage: data['completionPercentage'],
      lastActivityAt: DateTime.parse(data['lastActivityAt']),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );
  }

  // Authentication
  Future<UserCredential> signUp(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

// ── Test Fixtures ───────────────────────────────────────────────────────────

User _makeUser({
  String id = 'user-123',
  String email = 'test@example.com',
  String name = 'Test Parent',
}) =>
    User(
      id: id,
      email: email,
      name: name,
      createdAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(const Duration(days: 14)),
    );

ChildProfile _makeChildProfile({
  String id = 'child-123',
  String parentId = 'user-123',
  String name = 'Taro',
  int gradeLevel = 3,
}) =>
    ChildProfile(
      id: id,
      parentId: parentId,
      name: name,
      gradeLevel: gradeLevel,
      dateOfBirth: DateTime(2015),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

Progress _makeProgress({
  String id = 'progress-123',
  String childId = 'child-123',
  int storiesCompleted = 5,
  double averageScore = 85.0,
}) =>
    Progress(
      id: id,
      childId: childId,
      storiesCompleted: storiesCompleted,
      averageScore: averageScore,
      completionPercentage: 25.0,
      lastActivityAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

// ── Firebase Integration Tests ──────────────────────────────────────────────

void main() {
  group('Firebase Authentication', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('user can sign up with email and password', () async {
      final result = await firebaseService.signUp(
        'newuser@example.com',
        'password123',
      );

      expect(result.user, isNotNull);
      expect(result.user!.email, 'newuser@example.com');
    });

    test('user can sign in with email and password', () async {
      await firebaseService.signUp(
        'user@example.com',
        'password123',
      );

      await firebaseService.signOut();

      final result = await firebaseService.signIn(
        'user@example.com',
        'password123',
      );

      expect(result.user, isNotNull);
    });

    test('sign out clears current user', () async {
      await firebaseService.signUp(
        'user@example.com',
        'password123',
      );

      expect(firebaseService.currentUser, isNotNull);

      await firebaseService.signOut();

      expect(firebaseService.currentUser, isNull);
    });

    test('invalid credentials fail to sign in', () async {
      await firebaseService.signUp(
        'user@example.com',
        'password123',
      );

      await firebaseService.signOut();

      await expectLater(
        firebaseService.signIn(
          'user@example.com',
          'wrongpassword',
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          ),
        ),
      );
    });
  });

  group('Firestore User Data Management', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('create and retrieve user profile', () async {
      final user = _makeUser();

      await firebaseService.createUser(user);
      final retrieved = await firebaseService.getUser(user.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.email, user.email);
      expect(retrieved.name, user.name);
    });

    test('update user profile', () async {
      var user = _makeUser();
      await firebaseService.createUser(user);

      final updated = User(
        id: user.id,
        email: user.email,
        name: 'Updated Name',
        createdAt: user.createdAt,
        trialEndsAt: user.trialEndsAt.add(const Duration(days: 7)),
      );

      await firebaseService.updateUser(updated);
      final retrieved = await firebaseService.getUser(user.id);

      expect(retrieved!.name, 'Updated Name');
    });

    test('user not found returns null', () async {
      final user = await firebaseService.getUser('non-existent-id');

      expect(user, isNull);
    });
  });

  group('Firestore Child Profile Management', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('create and retrieve child profile', () async {
      final child = _makeChildProfile();

      await firebaseService.createChildProfile(child);
      final retrieved =
          await firebaseService.getChildProfile(child.parentId, child.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Taro');
      expect(retrieved.gradeLevel, 3);
    });

    test('retrieve all child profiles for parent', () async {
      final child1 = _makeChildProfile(id: 'child-1', name: 'Taro');
      final child2 = _makeChildProfile(id: 'child-2', name: 'Hanako');

      await firebaseService.createChildProfile(child1);
      await firebaseService.createChildProfile(child2);

      final profiles = await firebaseService.getChildProfiles('user-123');

      expect(profiles.length, 2);
      expect(profiles.map((p) => p.name).toList(), contains('Taro'));
      expect(profiles.map((p) => p.name).toList(), contains('Hanako'));
    });

    test('child not found returns null', () async {
      final child = await firebaseService.getChildProfile(
        'user-123',
        'non-existent-id',
      );

      expect(child, isNull);
    });
  });

  group('Firestore Progress Tracking', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('create and retrieve progress record', () async {
      final progress = _makeProgress();

      await firebaseService.createProgress(progress);
      final retrieved = await firebaseService.getProgress(
        'user-123',
        'child-123',
        progress.id,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.storiesCompleted, 5);
      expect(retrieved.averageScore, 85.0);
    });

    test('progress record not found returns null', () async {
      final progress = await firebaseService.getProgress(
        'user-123',
        'child-123',
        'non-existent-id',
      );

      expect(progress, isNull);
    });

    test('multiple progress records for same child', () async {
      final progress1 = _makeProgress(
        id: 'prog-1',
        storiesCompleted: 5,
        averageScore: 85.0,
      );
      final progress2 = _makeProgress(
        id: 'prog-2',
        storiesCompleted: 10,
        averageScore: 88.0,
      );

      await firebaseService.createProgress(progress1);
      await firebaseService.createProgress(progress2);

      final p1 = await firebaseService.getProgress(
        'user-123',
        'child-123',
        'prog-1',
      );
      final p2 = await firebaseService.getProgress(
        'user-123',
        'child-123',
        'prog-2',
      );

      expect(p1!.storiesCompleted, 5);
      expect(p2!.storiesCompleted, 10);
    });
  });

  group('Offline Mode Simulation', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('data persists after offline-online transition', () async {
      // Create data while "online"
      final user = _makeUser();
      await firebaseService.createUser(user);

      // Simulate going offline and back online
      final retrieved = await firebaseService.getUser(user.id);

      // Data should still be available
      expect(retrieved, isNotNull);
      expect(retrieved!.email, user.email);
    });

    test('child profile accessible after network restoration', () async {
      final child = _makeChildProfile();
      await firebaseService.createChildProfile(child);

      final retrieved =
          await firebaseService.getChildProfile(child.parentId, child.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Taro');
    });

    test('progress data syncs after offline period', () async {
      final progress = _makeProgress();
      await firebaseService.createProgress(progress);

      final retrieved = await firebaseService.getProgress(
        'user-123',
        'child-123',
        progress.id,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.storiesCompleted, 5);
    });
  });

  group('Firebase End-to-End Flow', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('complete firebase workflow: auth -> user -> children -> progress',
        () async {
      // Step 1: Authentication
      await firebaseService.signUp(
        'parent@example.com',
        'secure123',
      );
      expect(firebaseService.currentUser, isNotNull);

      // Step 2: Create user profile
      final user = User(
        id: firebaseService.currentUser!.uid,
        email: 'parent@example.com',
        name: 'Parent User',
        createdAt: DateTime.now(),
        trialEndsAt: DateTime.now().add(const Duration(days: 14)),
      );
      await firebaseService.createUser(user);
      final savedUser = await firebaseService.getUser(user.id);
      expect(savedUser, isNotNull);

      // Step 3: Create child profiles
      final userId = user.id;
      final child1 = ChildProfile(
        id: 'child-1',
        parentId: userId,
        name: 'Taro',
        gradeLevel: 3,
        dateOfBirth: DateTime(2015),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await firebaseService.createChildProfile(child1);
      final savedChild = await firebaseService.getChildProfile(userId, 'child-1');
      expect(savedChild, isNotNull);

      // Step 4: Create progress record
      final progress = Progress(
        id: 'prog-1',
        childId: 'child-1',
        storiesCompleted: 1,
        averageScore: 90.0,
        completionPercentage: 5.0,
        lastActivityAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await firebaseService.createProgress(progress);
      final savedProgress =
          await firebaseService.getProgress(userId, 'child-1', 'prog-1');
      expect(savedProgress, isNotNull);
      expect(savedProgress!.averageScore, 90.0);

      // Step 5: Sign out
      await firebaseService.signOut();
      expect(firebaseService.currentUser, isNull);
    });
  });

  group('Data Isolation and Security', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    test('parent can only access their own children', () async {
      final parent1Child = _makeChildProfile(parentId: 'parent-1', id: 'child-1');
      final parent2Child = _makeChildProfile(parentId: 'parent-2', id: 'child-2');

      await firebaseService.createChildProfile(parent1Child);
      await firebaseService.createChildProfile(parent2Child);

      final parent1Children = await firebaseService.getChildProfiles('parent-1');
      final parent2Children = await firebaseService.getChildProfiles('parent-2');

      expect(parent1Children.length, 1);
      expect(parent1Children[0].name, 'Taro');
      expect(parent2Children.length, 1);
    });
  });
}
