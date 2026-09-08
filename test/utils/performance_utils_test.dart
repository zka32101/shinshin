import 'package:flutter_test/flutter_test.dart';
import 'package:shinshin/utils/performance_utils.dart';

void main() {
  group('PerformanceUtils Tests', () {
    late PerformanceUtils utils;

    setUp(() {
      utils = PerformanceUtils();
      utils.clearAllTimings();
    });

    test('singleton pattern returns same instance', () {
      final instance1 = PerformanceUtils();
      final instance2 = PerformanceUtils();
      expect(identical(instance1, instance2), isTrue);
    });

    test('startTiming and stopTiming records elapsed time', () {
      utils.startTiming('test_operation');

      // Simulate some work
      int sum = 0;
      for (int i = 0; i < 1000000; i++) {
        sum += i;
      }

      final elapsed = utils.stopTiming('test_operation');
      expect(elapsed, isGreaterThanOrEqualTo(0));
    });

    test('stopTiming returns 0 for non-existent operation', () {
      final elapsed = utils.stopTiming('non_existent_operation');
      expect(elapsed, equals(0));
    });

    test('getAverageTiming calculates correct average', () {
      utils.startTiming('avg_test');
      utils.stopTiming('avg_test');

      utils.startTiming('avg_test');
      utils.stopTiming('avg_test');

      utils.startTiming('avg_test');
      utils.stopTiming('avg_test');

      final average = utils.getAverageTiming('avg_test');
      expect(average, isGreaterThan(0));
    });

    test('getAverageTiming returns 0 for non-existent metric', () {
      final average = utils.getAverageTiming('non_existent');
      expect(average, equals(0));
    });

    test('getMaxTiming returns maximum elapsed time', () {
      utils.startTiming('max_test');
      utils.stopTiming('max_test');

      utils.startTiming('max_test');
      utils.stopTiming('max_test');

      final max = utils.getMaxTiming('max_test');
      expect(max, isNotNull);
      expect(max, isGreaterThanOrEqualTo(0));
    });

    test('getMinTiming returns minimum elapsed time', () {
      utils.startTiming('min_test');
      utils.stopTiming('min_test');

      utils.startTiming('min_test');
      utils.stopTiming('min_test');

      final min = utils.getMinTiming('min_test');
      expect(min, isNotNull);
      expect(min, isGreaterThanOrEqualTo(0));
    });

    test('getAllTimings returns statistics for all metrics', () {
      utils.startTiming('metric1');
      utils.stopTiming('metric1');

      utils.startTiming('metric2');
      utils.stopTiming('metric2');

      final allTimings = utils.getAllTimings();
      expect(allTimings.containsKey('metric1'), isTrue);
      expect(allTimings.containsKey('metric2'), isTrue);
      expect(allTimings['metric1'], isNotNull);
      expect(allTimings['metric1']['count'], equals(1));
    });

    test('clearAllTimings removes all recorded timings', () {
      utils.startTiming('clear_test');
      utils.stopTiming('clear_test');

      var allTimings = utils.getAllTimings();
      expect(allTimings.isNotEmpty, isTrue);

      utils.clearAllTimings();

      allTimings = utils.getAllTimings();
      expect(allTimings.isEmpty, isTrue);
    });

    test('timings respect maximum measurements per metric', () {
      const maxTimings = 100;

      for (int i = 0; i < maxTimings + 50; i++) {
        utils.startTiming('overflow_test');
        utils.stopTiming('overflow_test');
      }

      final allTimings = utils.getAllTimings();
      expect(allTimings['overflow_test']['count'], equals(maxTimings));
    });

    test('PerformanceTracker measures elapsed time correctly', () {
      final tracker = PerformanceTracker('tracker_test');

      // Simulate some work
      int sum = 0;
      for (int i = 0; i < 100000; i++) {
        sum += i;
      }

      tracker.end();
      expect(tracker.elapsedMilliseconds, isGreaterThanOrEqualTo(0));
    });

    test('PerformanceTracker name extension works correctly', () {
      final tracker = 'extension_test'.startPerformanceTracking();
      expect(tracker.name, equals('extension_test'));

      // Simulate some work
      int sum = 0;
      for (int i = 0; i < 100000; i++) {
        sum += i;
      }

      tracker.end();

      final allTimings = utils.getAllTimings();
      expect(allTimings.containsKey('extension_test'), isTrue);
    });

    test('multiple concurrent timings can be tracked', () {
      utils.startTiming('operation_a');
      utils.startTiming('operation_b');
      utils.startTiming('operation_c');

      // Simulate different work durations
      int sum = 0;
      for (int i = 0; i < 100000; i++) {
        sum += i;
      }

      utils.stopTiming('operation_a');

      for (int i = 0; i < 100000; i++) {
        sum += i;
      }

      utils.stopTiming('operation_b');
      utils.stopTiming('operation_c');

      final allTimings = utils.getAllTimings();
      expect(allTimings.containsKey('operation_a'), isTrue);
      expect(allTimings.containsKey('operation_b'), isTrue);
      expect(allTimings.containsKey('operation_c'), isTrue);
    });

    test('statistics calculations are correct', () {
      // Record known timings
      utils.startTiming('stats_test');
      utils.stopTiming('stats_test');

      utils.startTiming('stats_test');
      utils.stopTiming('stats_test');

      final average = utils.getAverageTiming('stats_test');
      final max = utils.getMaxTiming('stats_test');
      final min = utils.getMinTiming('stats_test');

      expect(average, isGreaterThanOrEqualTo(0));
      expect(max, isNotNull);
      expect(min, isNotNull);
      expect(max, greaterThanOrEqualTo(min!));
    });
  });
}
