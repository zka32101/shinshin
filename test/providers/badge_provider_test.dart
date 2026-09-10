import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/expect.dart' show greaterThan;
import 'package:mockito/mockito.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/badge_provider.dart';
import 'package:shougaku_kore_doutoku/providers/progress_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart';
import '../helpers/fake_hive_service.dart';

void main() {
  group('Badge Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(FakeHiveService()),
        ],
      );
    });

    test('earnedBadgesProvider returns empty list when no stories completed', () async {
      final provider = container.listen<AsyncValue<List<EarnedBadge>>>(
        earnedBadgesProvider('test_child'),
        (previous, next) {},
      );

      final state = container.read(earnedBadgesProvider('test_child'));
      expect(state, isA<AsyncLoading>());
    });

    test('badgeProgressProvider returns zero progress for unearned badges', () async {
      final provider = container.listen<AsyncValue<Map<String, double>>>(
        badgeProgressProvider('test_child'),
        (previous, next) {},
      );

      final state = container.read(badgeProgressProvider('test_child'));
      expect(state, isA<AsyncLoading>());
    });

    test('totalEarnedBadgesCountProvider returns 0 initially', () async {
      final provider = container.listen<AsyncValue<int>>(
        totalEarnedBadgesCountProvider('test_child'),
        (previous, next) {},
      );

      final state = container.read(totalEarnedBadgesCountProvider('test_child'));
      expect(state, isA<AsyncLoading>());
    });

    test('totalAvailableBadgesCountProvider returns correct count', () {
      final count = container.read(totalAvailableBadgesCountProvider);
      expect(count, equals(kDoutokuBadges.length));
      expect(count, greaterThan(0));
    });

    test('badgeCompletionRateProvider returns 0.0 initially', () async {
      final provider = container.listen<AsyncValue<double>>(
        badgeCompletionRateProvider('test_child'),
        (previous, next) {},
      );

      final state = container.read(badgeCompletionRateProvider('test_child'));
      expect(state, isA<AsyncLoading>());
    });

    test('badge definitions are correctly configured', () {
      expect(kDoutokuBadges, isNotEmpty);

      // Check structure of badges
      for (final badge in kDoutokuBadges) {
        expect(badge.id, isNotEmpty);
        expect(badge.name, isNotEmpty);
        expect(badge.emoji, isNotEmpty);
        expect(badge.theme, isNotEmpty);
        expect(badge.requiredCompletions, greaterThan(0));
      }
    });

    test('findBadge returns correct badge', () {
      final badge = findBadge('kindness_1');
      expect(badge, isNotNull);
      expect(badge!.name, equals('やさしい心'));
      expect(badge.theme, equals('kindness'));
    });

    test('findBadge returns null for non-existent badge', () {
      final badge = findBadge('non_existent_badge');
      expect(badge, isNull);
    });

    test('EarnedBadge can be serialized and deserialized', () {
      final original = EarnedBadge(
        badgeId: 'test_badge',
        earnedAt: DateTime(2024, 1, 15),
      );

      final json = original.toJson();
      final deserialized = EarnedBadge.fromJson(json);

      expect(deserialized.badgeId, equals(original.badgeId));
      expect(deserialized.earnedAt.year, equals(original.earnedAt.year));
      expect(deserialized.earnedAt.month, equals(original.earnedAt.month));
      expect(deserialized.earnedAt.day, equals(original.earnedAt.day));
    });

    test('Badge themes are valid', () {
      final validThemes = {'kindness', 'honesty', 'courage', 'respect', 'cooperation', 'responsibility', 'all'};

      for (final badge in kDoutokuBadges) {
        expect(validThemes.contains(badge.theme), isTrue,
          reason: 'Invalid theme "${badge.theme}" in badge ${badge.id}');
      }
    });
  });
}
