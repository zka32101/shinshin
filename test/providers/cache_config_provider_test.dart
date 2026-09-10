import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/providers/cache_config_provider.dart';

void main() {
  group('Cache Config Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    test('default CacheConfig has correct defaults', () {
      final config = const CacheConfig();
      expect(config.ttlSeconds, equals(300)); // 5 minutes
      expect(config.maxInstances, equals(100));
      expect(config.keepAlive, equals(false));
    });

    test('frequentAccess config has correct settings', () {
      expect(CacheConfig.frequentAccess.ttlSeconds, equals(600)); // 10 minutes
      expect(CacheConfig.frequentAccess.maxInstances, equals(50));
      expect(CacheConfig.frequentAccess.keepAlive, isTrue);
    });

    test('periodicallyChanging config has correct settings', () {
      expect(CacheConfig.periodicallyChanging.ttlSeconds, equals(300)); // 5 minutes
      expect(CacheConfig.periodicallyChanging.maxInstances, equals(30));
      expect(CacheConfig.periodicallyChanging.keepAlive, isFalse);
    });

    test('rarelyChanging config has correct settings', () {
      expect(CacheConfig.rarelyChanging.ttlSeconds, equals(3600)); // 1 hour
      expect(CacheConfig.rarelyChanging.maxInstances, equals(20));
      expect(CacheConfig.rarelyChanging.keepAlive, isTrue);
    });

    test('userSpecific config has correct settings', () {
      expect(CacheConfig.userSpecific.ttlSeconds, equals(120)); // 2 minutes
      expect(CacheConfig.userSpecific.maxInstances, equals(50));
      expect(CacheConfig.userSpecific.keepAlive, isTrue);
    });

    test('networkOptimized config has correct settings', () {
      expect(CacheConfig.networkOptimized.ttlSeconds, equals(600)); // 10 minutes
      expect(CacheConfig.networkOptimized.maxInstances, equals(20));
      expect(CacheConfig.networkOptimized.keepAlive, isFalse);
    });

    test('cacheConfigProvider returns default config', () {
      final config = container.read(cacheConfigProvider);
      expect(config.ttlSeconds, equals(300));
      expect(config.maxInstances, equals(100));
      expect(config.keepAlive, isFalse);
    });

    test('storyDataCacheConfigProvider returns frequentAccess config', () {
      final config = container.read(storyDataCacheConfigProvider);
      expect(config.ttlSeconds, equals(600));
      expect(config.maxInstances, equals(50));
      expect(config.keepAlive, isTrue);
    });

    test('reportDataCacheConfigProvider returns periodicallyChanging config', () {
      final config = container.read(reportDataCacheConfigProvider);
      expect(config.ttlSeconds, equals(300));
      expect(config.maxInstances, equals(30));
      expect(config.keepAlive, isFalse);
    });

    test('badgeDataCacheConfigProvider returns rarelyChanging config', () {
      final config = container.read(badgeDataCacheConfigProvider);
      expect(config.ttlSeconds, equals(3600));
      expect(config.maxInstances, equals(20));
      expect(config.keepAlive, isTrue);
    });

    test('userDataCacheConfigProvider returns userSpecific config', () {
      final config = container.read(userDataCacheConfigProvider);
      expect(config.ttlSeconds, equals(120));
      expect(config.maxInstances, equals(50));
      expect(config.keepAlive, isTrue);
    });

    test('custom CacheConfig can be created with custom values', () {
      final customConfig = const CacheConfig(
        ttlSeconds: 900,
        maxInstances: 75,
        keepAlive: true,
      );

      expect(customConfig.ttlSeconds, equals(900));
      expect(customConfig.maxInstances, equals(75));
      expect(customConfig.keepAlive, isTrue);
    });

    test('TTL values are reasonable for different use cases', () {
      // frequentAccess should be longer than userSpecific
      expect(CacheConfig.frequentAccess.ttlSeconds,
          greaterThan(CacheConfig.userSpecific.ttlSeconds));

      // rarelyChanging should be much longer than others
      expect(CacheConfig.rarelyChanging.ttlSeconds,
          greaterThan(CacheConfig.frequentAccess.ttlSeconds));
      expect(CacheConfig.rarelyChanging.ttlSeconds,
          greaterThan(CacheConfig.periodicallyChanging.ttlSeconds));
    });

    test('maxInstances are appropriate for each strategy', () {
      // frequentAccess should have higher limit
      expect(CacheConfig.frequentAccess.maxInstances,
          greaterThanOrEqualTo(CacheConfig.networkOptimized.maxInstances));

      // networkOptimized should be lower to reduce bandwidth
      expect(CacheConfig.networkOptimized.maxInstances,
          lessThan(CacheConfig.userSpecific.maxInstances));
    });
  });
}
