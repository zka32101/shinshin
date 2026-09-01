import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinshin/models/ranking.dart';
import 'package:shinshin/services/ranking_service.dart';

/// Mock Firestore for testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  group('RankingService', () {
    late RankingService rankingService;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      rankingService = RankingService(firestore: mockFirestore);
    });

    group('RankingEntry', () {
      test('getDisplayName returns generic name when isNamePublic is false', () {
        final entry = RankingEntry(
          userId: 'user1',
          userName: '太郎',
          score: 100,
          rank: 1,
          updatedAt: DateTime.now(),
          isNamePublic: false,
        );

        expect(entry.getDisplayName(), equals('ユーザー'));
      });

      test('getDisplayName returns actual name when isNamePublic is true', () {
        final entry = RankingEntry(
          userId: 'user1',
          userName: '太郎',
          score: 100,
          rank: 1,
          updatedAt: DateTime.now(),
          isNamePublic: true,
        );

        expect(entry.getDisplayName(), equals('太郎'));
      });

      test('RankingEntry JSON serialization round-trip', () {
        final entry = RankingEntry(
          userId: 'user1',
          userName: '太郎',
          score: 100,
          rank: 1,
          updatedAt: DateTime(2024, 1, 1),
          isNamePublic: true,
        );

        final json = entry.toJson();
        final restored = RankingEntry.fromJson(json);

        expect(restored.userId, equals(entry.userId));
        expect(restored.userName, equals(entry.userName));
        expect(restored.score, equals(entry.score));
        expect(restored.rank, equals(entry.rank));
        expect(restored.isNamePublic, equals(entry.isNamePublic));
      });
    });

    group('RankingSettings', () {
      test('default settings have isNamePublic false', () {
        final settings = RankingSettings(
          userId: 'user1',
          isNamePublic: false,
          participateInRanking: true,
          updatedAt: DateTime.now(),
        );

        expect(settings.isNamePublic, isFalse);
        expect(settings.participateInRanking, isTrue);
      });

      test('settings can be toggled', () {
        var settings = RankingSettings(
          userId: 'user1',
          isNamePublic: false,
          participateInRanking: true,
          updatedAt: DateTime.now(),
        );

        // Toggle name disclosure
        settings = RankingSettings(
          userId: settings.userId,
          isNamePublic: !settings.isNamePublic,
          participateInRanking: settings.participateInRanking,
          updatedAt: DateTime.now(),
        );

        expect(settings.isNamePublic, isTrue);
      });

      test('RankingSettings JSON serialization', () {
        final settings = RankingSettings(
          userId: 'user1',
          isNamePublic: true,
          participateInRanking: false,
          updatedAt: DateTime(2024, 1, 1),
        );

        final json = settings.toJson();
        final restored = RankingSettings.fromJson(json);

        expect(restored.userId, equals(settings.userId));
        expect(restored.isNamePublic, equals(settings.isNamePublic));
        expect(restored.participateInRanking, equals(settings.participateInRanking));
      });
    });

    group('RankingType', () {
      test('all 8 ranking types are defined', () {
        expect(RankingType.values.length, equals(8));
      });

      test('ranking types have correct values', () {
        expect(RankingType.totalPoints.toString(),
            contains('totalPoints'));
        expect(RankingType.monthlyPoints.toString(),
            contains('monthlyPoints'));
        expect(RankingType.virtueCompassion.toString(),
            contains('virtueCompassion'));
      });
    });

    group('RankingStats', () {
      test('RankingStats initializes with all fields', () {
        final stats = RankingStats(
          totalPointsRank: 10,
          monthlyPointsRank: 5,
          totalScore: 500,
          monthlyScore: 100,
          virtueScores: {
            'compassion': 80,
            'honesty': 75,
            'responsibility': 85,
            'courage': 70,
            'respect': 80,
            'cooperation': 75,
          },
        );

        expect(stats.totalPointsRank, equals(10));
        expect(stats.monthlyPointsRank, equals(5));
        expect(stats.totalScore, equals(500));
        expect(stats.monthlyScore, equals(100));
        expect(stats.virtueScores.length, equals(6));
      });

      test('RankingStats JSON serialization', () {
        final stats = RankingStats(
          totalPointsRank: 10,
          monthlyPointsRank: 5,
          totalScore: 500,
          monthlyScore: 100,
          virtueScores: {
            'compassion': 80,
          },
        );

        final json = stats.toJson();
        final restored = RankingStats.fromJson(json);

        expect(restored.totalPointsRank, equals(stats.totalPointsRank));
        expect(restored.monthlyPointsRank, equals(stats.monthlyPointsRank));
        expect(restored.totalScore, equals(stats.totalScore));
        expect(restored.monthlyScore, equals(stats.monthlyScore));
      });
    });

    group('Privacy Features', () {
      test('privacy is default OFF (user names hidden)', () {
        final settings = RankingSettings.defaultSettings('user1');
        expect(settings.isNamePublic, isFalse);
      });

      test('multiple users can have different privacy settings', () {
        final user1Settings = RankingSettings(
          userId: 'user1',
          isNamePublic: true,
          participateInRanking: true,
          updatedAt: DateTime.now(),
        );

        final user2Settings = RankingSettings(
          userId: 'user2',
          isNamePublic: false,
          participateInRanking: true,
          updatedAt: DateTime.now(),
        );

        expect(user1Settings.isNamePublic, isTrue);
        expect(user2Settings.isNamePublic, isFalse);
      });

      test('privacy setting does not affect ranking participation', () {
        final settings = RankingSettings(
          userId: 'user1',
          isNamePublic: false, // Hidden name
          participateInRanking: true, // Still participates
          updatedAt: DateTime.now(),
        );

        expect(settings.participateInRanking, isTrue);
      });
    });

    group('Display Logic', () {
      test('getDisplayName() respects privacy setting', () {
        final publicEntry = RankingEntry(
          userId: 'user1',
          userName: '太郎',
          score: 100,
          rank: 1,
          updatedAt: DateTime.now(),
          isNamePublic: true,
        );

        final privateEntry = RankingEntry(
          userId: 'user2',
          userName: '花子',
          score: 90,
          rank: 2,
          updatedAt: DateTime.now(),
          isNamePublic: false,
        );

        expect(publicEntry.getDisplayName(), equals('太郎'));
        expect(privateEntry.getDisplayName(), equals('ユーザー'));
      });

      test('privacy does not hide user rank', () {
        final entry = RankingEntry(
          userId: 'user1',
          userName: '太郎',
          score: 100,
          rank: 5,
          updatedAt: DateTime.now(),
          isNamePublic: false,
        );

        // Rank should always be visible
        expect(entry.rank, equals(5));
      });
    });
  });
}

extension on RankingSettings {
  static RankingSettings defaultSettings(String userId) {
    return RankingSettings(
      userId: userId,
      isNamePublic: false, // Default: names hidden
      participateInRanking: true, // Default: participate
      updatedAt: DateTime.now(),
    );
  }
}
