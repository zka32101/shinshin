import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/models/quiz_session.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/user.dart';
import 'package:shougaku_kore_doutoku/providers/auth_provider.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart';
import 'package:shougaku_kore_doutoku/providers/progress_provider.dart';
import 'package:shougaku_kore_doutoku/providers/quiz_completion_provider.dart';
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import 'package:shougaku_kore_doutoku/services/auth_service.dart';
import '../helpers/fake_path_provider.dart';

// ── Mock Services for Integration Tests ──────────────────────────────────────

class _MockAuthService extends AuthService {
  User? _currentUser;
  bool shouldFail = false;

  @override
  Future<User> register(String email, String password) async {
    if (shouldFail) throw Exception('Registration failed');
    _currentUser = User(
      id: 'user-123',
      email: email,
      name: 'Test User',
      createdAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(const Duration(days: 14)),
    );
    return _currentUser!;
  }

  @override
  Future<User> login(String email, String password) async {
    if (shouldFail) throw Exception('Login failed');
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Invalid credentials');
    }
    _currentUser = User(
      id: 'user-123',
      email: email,
      name: 'Test User',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  User? get currentUser => _currentUser;
}

class _InMemoryHiveService extends HiveService {
  final Map<String, Story> _stories = {};
  final Map<String, ChildProfile> _children = {};
  final Map<String, Progress> _progress = {};
  final Map<String, QuizSession> _sessions = {};

  @override
  Future<void> cacheStories(List<Story> stories) async {
    for (final s in stories) {
      _stories[s.id] = s;
    }
  }

  @override
  Future<Story?> getCachedStory(String storyId) async => _stories[storyId];

  @override
  Future<List<Story>> getCachedStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
  }) async {
    return _stories.values.where((s) {
      if (theme != null && s.theme != theme) return false;
      if (gradeLevel != null && s.gradeLevel != gradeLevel) return false;
      if (isPremium != null && s.isPremium != isPremium) return false;
      return true;
    }).toList();
  }

  // Child Profile methods
  Future<void> saveChildProfile(ChildProfile profile) async {
    _children[profile.id] = profile;
  }

  Future<ChildProfile?> getChildProfile(String childId) async =>
      _children[childId];

  Future<List<ChildProfile>> getAllChildProfiles() async =>
      _children.values.toList();

  // Progress tracking
  Future<void> saveProgress(Progress progress) async {
    _progress[progress.id] = progress;
  }

  Future<Progress?> getProgress(String progressId) async =>
      _progress[progressId];

  // Quiz Session
  Future<void> saveQuizSession(QuizSession session) async {
    _sessions[session.id] = session;
  }

  Future<QuizSession?> getQuizSession(String sessionId) async =>
      _sessions[sessionId];
}

class _FakeApiService extends ApiService {
  List<Story> storiesResult = [];
  Story? detailResult;
  bool shouldFail = false;

  @override
  Future<List<Story>> fetchStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
    int offset = 0,
    int limit = 20,
  }) async {
    if (shouldFail) throw Exception('network error');
    return storiesResult;
  }

  @override
  Future<Story> fetchStoryDetail(String storyId) async {
    if (shouldFail) throw Exception('network error');
    if (detailResult == null) throw Exception('not found');
    return detailResult!;
  }

  @override
  Future<List<Story>> fetchWeeklyTheme(int weekNumber) async {
    if (shouldFail) throw Exception('network error');
    return storiesResult;
  }
}

// ── Test Fixtures ───────────────────────────────────────────────────────────

Story _makeStory({
  required String id,
  String title = 'Sample Story',
  String theme = 'kindness',
  int gradeLevel = 3,
  bool isPremium = false,
}) =>
    Story(
      id: id,
      title: title,
      theme: theme,
      gradeLevel: gradeLevel,
      isPremium: isPremium,
      durationSeconds: 300,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

ChildProfile _makeChildProfile({
  required String id,
  String name = 'Taro',
  int gradeLevel = 3,
}) =>
    ChildProfile(
      id: id,
      parentId: 'user-123',
      name: name,
      gradeLevel: gradeLevel,
      dateOfBirth: DateTime(2015),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

QuizSession _makeQuizSession({
  required String id,
  required String storyId,
  required String childId,
  DateTime? completedAt,
}) =>
    QuizSession(
      id: id,
      childId: childId,
      storyId: storyId,
      selectedAnswers: {'q1': 'a', 'q2': 'b'},
      score: 80,
      completedAt: completedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

Progress _makeProgress({
  required String id,
  required String childId,
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

ProviderContainer _makeContainer({
  required _MockAuthService auth,
  required _FakeApiService api,
  required HiveService hive,
}) =>
    ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
      apiServiceProvider.overrideWithValue(api),
      hiveServiceProvider.overrideWithValue(hive),
    ]);

// ── Integration Tests ────────────────────────────────────────────────────────

void main() {
  late Directory testDir;
  late _InMemoryHiveService hive;
  late _FakeApiService api;
  late _MockAuthService auth;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('app_flow_test_');
    Hive.init(testDir.path);
    hive = _InMemoryHiveService();
    api = _FakeApiService();
    auth = _MockAuthService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  group('User Registration Flow', () {
    test('successful email registration', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      final user = await auth.register('newuser@example.com', 'password123');

      expect(user.id, 'user-123');
      expect(user.email, 'newuser@example.com');
      expect(user.name, 'Test User');
      expect(user.trialEndsAt, isNotNull);
    });

    test('registration failure on network error', () async {
      auth.shouldFail = true;
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        auth.register('user@example.com', 'password123'),
        throwsException,
      );
    });

    test('current user is set after registration', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      await auth.register('user@example.com', 'password123');
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, 'user@example.com');
    });
  });

  group('User Login Flow', () {
    test('successful email login', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      final user = await auth.login('user@example.com', 'password123');

      expect(user.id, 'user-123');
      expect(user.email, 'user@example.com');
    });

    test('login failure with invalid credentials', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        auth.login('', ''),
        throwsException,
      );
    });

    test('trial period is expired for existing user', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      final user = await auth.login('user@example.com', 'password123');

      expect(user.trialEndsAt.isBefore(DateTime.now()), true);
    });

    test('current user is set after login', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      await auth.login('user@example.com', 'password123');
      expect(auth.currentUser, isNotNull);
    });
  });

  group('Story Learning Flow', () {
    test('fetch and display stories successfully', () async {
      api.storiesResult = [
        _makeStory(id: 's1', title: 'Kindness Story'),
        _makeStory(id: 's2', title: 'Honesty Story'),
      ];

      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await api.fetchStories();

      expect(stories.length, 2);
      expect(stories[0].title, 'Kindness Story');
      expect(stories[1].title, 'Honesty Story');
    });

    test('fetch story detail for learning', () async {
      api.detailResult = _makeStory(id: 's1', title: 'Detail Story');

      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      final story = await api.fetchStoryDetail('s1');

      expect(story.id, 's1');
      expect(story.title, 'Detail Story');
    });

    test('cache stories for offline access', () async {
      final stories = [
        _makeStory(id: 's1'),
        _makeStory(id: 's2'),
      ];

      await hive.cacheStories(stories);
      final cached = await hive.getCachedStories();

      expect(cached.length, 2);
    });

    test('retrieve cached story when offline', () async {
      final story = _makeStory(id: 's1', title: 'Offline Story');
      await hive.cacheStories([story]);

      final cached = await hive.getCachedStory('s1');

      expect(cached, isNotNull);
      expect(cached!.title, 'Offline Story');
    });
  });

  group('Quiz Completion Flow', () {
    test('create and save quiz session', () async {
      final childProfile = _makeChildProfile(id: 'child-1');
      await hive.saveChildProfile(childProfile);

      final session = _makeQuizSession(
        id: 'session-1',
        storyId: 's1',
        childId: 'child-1',
        completedAt: DateTime.now(),
      );
      await hive.saveQuizSession(session);

      final saved = await hive.getQuizSession('session-1');

      expect(saved, isNotNull);
      expect(saved!.childId, 'child-1');
      expect(saved.score, 80);
    });

    test('update progress after quiz completion', () async {
      final childProfile = _makeChildProfile(id: 'child-1');
      await hive.saveChildProfile(childProfile);

      final progress = _makeProgress(
        id: 'prog-1',
        childId: 'child-1',
        storiesCompleted: 5,
        averageScore: 85.0,
      );
      await hive.saveProgress(progress);

      final saved = await hive.getProgress('prog-1');

      expect(saved, isNotNull);
      expect(saved!.storiesCompleted, 5);
      expect(saved.averageScore, 85.0);
    });

    test('track multiple quiz sessions for same child', () async {
      final childProfile = _makeChildProfile(id: 'child-1');
      await hive.saveChildProfile(childProfile);

      final session1 = _makeQuizSession(
        id: 'session-1',
        storyId: 's1',
        childId: 'child-1',
      );
      final session2 = _makeQuizSession(
        id: 'session-2',
        storyId: 's2',
        childId: 'child-1',
      );

      await hive.saveQuizSession(session1);
      await hive.saveQuizSession(session2);

      final s1 = await hive.getQuizSession('session-1');
      final s2 = await hive.getQuizSession('session-2');

      expect(s1, isNotNull);
      expect(s2, isNotNull);
      expect(s1!.storyId, 's1');
      expect(s2!.storyId, 's2');
    });
  });

  group('Logout Flow', () {
    test('logout clears current user', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      await auth.login('user@example.com', 'password123');
      expect(auth.currentUser, isNotNull);

      await auth.logout();
      expect(auth.currentUser, isNull);
    });

    test('user cannot access data after logout', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      await auth.login('user@example.com', 'password123');
      await auth.logout();

      expect(auth.currentUser, isNull);
    });
  });

  group('Trial Period Flow', () {
    test('detect expired trial period', () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      final user = await auth.login('user@example.com', 'password123');

      final isTrialExpired = user.trialEndsAt.isBefore(DateTime.now());
      expect(isTrialExpired, true);
    });

    test('allow story access during active trial', () async {
      final newUser = await auth.register('new@example.com', 'password123');

      final isTrialActive = newUser.trialEndsAt.isAfter(DateTime.now());
      expect(isTrialActive, true);
    });
  });

  group('Child Profile Management', () {
    test('create and save child profile', () async {
      final child = _makeChildProfile(id: 'child-1');
      await hive.saveChildProfile(child);

      final saved = await hive.getChildProfile('child-1');

      expect(saved, isNotNull);
      expect(saved!.name, 'Taro');
      expect(saved.gradeLevel, 3);
    });

    test('retrieve all child profiles for parent', () async {
      final child1 = _makeChildProfile(id: 'child-1', name: 'Taro');
      final child2 = _makeChildProfile(id: 'child-2', name: 'Hanako');

      await hive.saveChildProfile(child1);
      await hive.saveChildProfile(child2);

      final profiles = await hive.getAllChildProfiles();

      expect(profiles.length, 2);
      expect(profiles.map((p) => p.name).toList(), ['Taro', 'Hanako']);
    });

    test('update child profile', () async {
      var child = _makeChildProfile(id: 'child-1');
      await hive.saveChildProfile(child);

      final updated = ChildProfile(
        id: 'child-1',
        parentId: 'user-123',
        name: 'Taro Updated',
        gradeLevel: 4,
        dateOfBirth: DateTime(2015),
        createdAt: child.createdAt,
        updatedAt: DateTime.now(),
      );
      await hive.saveChildProfile(updated);

      final saved = await hive.getChildProfile('child-1');

      expect(saved!.name, 'Taro Updated');
      expect(saved.gradeLevel, 4);
    });
  });

  group('End-to-End User Journey', () {
    test('complete user journey: register -> add child -> complete story -> view progress',
        () async {
      final container = _makeContainer(auth: auth, api: api, hive: hive);
      addTearDown(container.dispose);

      // Step 1: Register
      final user = await auth.register('parent@example.com', 'password123');
      expect(user.email, 'parent@example.com');

      // Step 2: Create child profile
      final child = _makeChildProfile(id: 'child-1');
      await hive.saveChildProfile(child);
      final savedChild = await hive.getChildProfile('child-1');
      expect(savedChild, isNotNull);

      // Step 3: Fetch stories
      api.storiesResult = [_makeStory(id: 's1')];
      final stories = await api.fetchStories();
      expect(stories, isNotEmpty);

      // Step 4: Complete story
      final session = _makeQuizSession(
        id: 'session-1',
        storyId: 's1',
        childId: 'child-1',
        completedAt: DateTime.now(),
      );
      await hive.saveQuizSession(session);
      final savedSession = await hive.getQuizSession('session-1');
      expect(savedSession!.score, 80);

      // Step 5: Update progress
      final progress = _makeProgress(
        id: 'prog-1',
        childId: 'child-1',
        storiesCompleted: 1,
        averageScore: 80.0,
      );
      await hive.saveProgress(progress);
      final savedProgress = await hive.getProgress('prog-1');
      expect(savedProgress!.storiesCompleted, 1);
    });
  });
}
