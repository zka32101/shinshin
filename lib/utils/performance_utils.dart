import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Performance monitoring and optimization utilities
/// Tracks key metrics for performance analysis and optimization
class PerformanceUtils {
  static final PerformanceUtils _instance = PerformanceUtils._internal();

  factory PerformanceUtils() {
    return _instance;
  }

  PerformanceUtils._internal();

  final Map<String, Stopwatch> _activeStopwatches = {};
  final Map<String, List<int>> _timings = {};
  static const int _maxTimingsPerMetric = 100; // Keep last 100 measurements

  /// Start timing a named operation
  /// Returns stopwatch that can be stopped later
  void startTiming(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeStopwatches[operationName] = stopwatch;
  }

  /// Stop timing and record the result
  /// Returns elapsed milliseconds
  int stopTiming(String operationName) {
    final stopwatch = _activeStopwatches.remove(operationName);
    if (stopwatch == null) {
      debugPrint('[PerformanceUtils] No active stopwatch for $operationName');
      return 0;
    }

    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;

    // Record timing
    _timings.putIfAbsent(operationName, () => []);
    _timings[operationName]!.add(elapsed);

    // Keep only last N measurements
    if (_timings[operationName]!.length > _maxTimingsPerMetric) {
      _timings[operationName]!.removeAt(0);
    }

    debugPrint('[Performance] $operationName: ${elapsed}ms');

    // Log to native profiler if available
    if (!kIsWeb) {
      developer.Timeline.instantSync(operationName, arguments: {'elapsed_ms': elapsed});
    }

    return elapsed;
  }

  /// Get average timing for an operation
  double getAverageTiming(String operationName) {
    final timings = _timings[operationName];
    if (timings == null || timings.isEmpty) return 0;
    return timings.fold<int>(0, (a, b) => a + b) / timings.length;
  }

  /// Get maximum timing for an operation
  int? getMaxTiming(String operationName) {
    return _timings[operationName]?.isEmpty ?? true
        ? null
        : _timings[operationName]!.reduce((a, b) => a > b ? a : b);
  }

  /// Get minimum timing for an operation
  int? getMinTiming(String operationName) {
    return _timings[operationName]?.isEmpty ?? true
        ? null
        : _timings[operationName]!.reduce((a, b) => a < b ? a : b);
  }

  /// Get all recorded timings
  Map<String, dynamic> getAllTimings() {
    return {
      for (final entry in _timings.entries)
        entry.key: {
          'count': entry.value.length,
          'average': getAverageTiming(entry.key).toStringAsFixed(2),
          'max': getMaxTiming(entry.key),
          'min': getMinTiming(entry.key),
          'last': entry.value.isEmpty ? null : entry.value.last,
        }
    };
  }

  /// Clear all recorded timings
  void clearAllTimings() {
    _timings.clear();
    _activeStopwatches.clear();
  }

  /// Log all timing statistics
  void logAllTimings() {
    debugPrint('=== Performance Timings ===');
    for (final entry in getAllTimings().entries) {
      debugPrint('${entry.key}: ${entry.value}');
    }
  }
}

/// Utility to measure widget build performance
class PerformanceTracker {
  final String name;
  late Stopwatch _stopwatch;

  PerformanceTracker(this.name) {
    _stopwatch = Stopwatch()..start();
  }

  void end() {
    _stopwatch.stop();
    PerformanceUtils().stopTiming(name);
  }

  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
}

/// Extension for convenient performance tracking
extension PerformanceExtension on String {
  PerformanceTracker startPerformanceTracking() {
    return PerformanceTracker(this);
  }
}
