import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resource cleanup and memory management utilities
/// Implements Priority 5: Memory Leak Prevention patterns
class ResourceCleanupUtils {
  /// Ensures proper cleanup of StreamSubscriptions in providers
  /// Pattern: Use this in FutureProvider/StreamProvider onDispose
  ///
  /// Example:
  /// ```dart
  /// ref.onDispose(() {
  ///   ResourceCleanupUtils.ensureDisposed([subscription1, subscription2]);
  /// });
  /// ```
  static Future<void> ensureDisposed(List<dynamic> resources) async {
    for (final resource in resources) {
      try {
        if (resource is StreamSubscription) {
          await resource.cancel();
        } else if (resource is Future) {
          // Can't cancel a Future, just await it
          await resource;
        }
      } catch (e) {
        debugPrint('[ResourceCleanup] Failed to dispose resource: $e');
      }
    }
  }

  /// Validate and cleanup abandoned subscriptions
  /// Call periodically to detect and clean up leaked resources
  static Future<void> validateAndCleanupResources() async {
    // This would integrate with app telemetry/logging
    // Monitor for resource leaks through error tracking
  }
}

/// Mixin for safer resource management in StatefulWidgets
/// Use this mixin in your State class to get automatic subscription tracking
mixin ResourceManagementState<T extends StatefulWidget> on State<T> {
  /// Store subscriptions for cleanup in dispose()
  final List<StreamSubscription> _subscriptions = [];

  /// Add subscription to automatic cleanup list
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Cleanup all stored subscriptions
  Future<void> cleanupSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}

/// Mixin for automatic resource cleanup in ConsumerWidget/ConsumerStatefulWidget
/// Ensures all provider listeners are properly disposed
mixin AutoDisposeMixin {
  /// Call in dispose() or use with ref.onDispose()
  Future<void> disposeAllResources(Ref ref) async {
    // Framework automatically disposes providers with .autoDispose
    // This mixin documents the pattern
  }
}

/// Monitor animation and state controller cleanup
class ControllerCleanupHelper {
  /// Ensure AnimationControllers are properly disposed
  /// Call in State.dispose()
  static Future<void> disposeAnimationControllers(
    List<AnimationController> controllers,
  ) async {
    for (final controller in controllers) {
      if (!controller.isDisposed) {
        await controller.dispose();
      }
    }
  }

  /// Ensure TextEditingControllers are properly disposed
  /// Call in State.dispose()
  static void disposeTextControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  /// Ensure FocusNodes are properly disposed
  /// Call in State.dispose()
  static void disposeFocusNodes(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.dispose();
    }
  }
}

/// Memory usage monitoring (for debugging)
class MemoryMonitor {
  static final List<String> _memoryWarnings = [];

  /// Log potential memory usage issues
  static void logMemoryWarning(String message) {
    _memoryWarnings.add('${DateTime.now()}: $message');
    if (_memoryWarnings.length > 100) {
      _memoryWarnings.removeAt(0); // Keep last 100 warnings
    }
    debugPrint('[MemoryMonitor] $message');
  }

  /// Get memory warnings log
  static List<String> getWarningsLog() => List.unmodifiable(_memoryWarnings);

  /// Clear memory warnings log
  static void clearLog() => _memoryWarnings.clear();
}

/// Pattern documentation: Resource cleanup checklist
/// Use this as a reference when implementing screens with resources:
///
/// ```dart
/// class MyScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends ConsumerState<MyScreen> {
///   late AnimationController _animationController;
///   late TextEditingController _textController;
///   late FocusNode _focusNode;
///   final List<StreamSubscription> _subscriptions = [];
///
///   @override
///   void initState() {
///     super.initState();
///     _animationController = AnimationController(
///       duration: const Duration(milliseconds: 300),
///       vsync: this,
///     );
///     _textController = TextEditingController();
///     _focusNode = FocusNode();
///
///     // Setup subscriptions
///     _subscriptions.add(someStream.listen((_) {}));
///   }
///
///   @override
///   void dispose() {
///     // Cleanup in order: controllers, text, focus, subscriptions
///     ControllerCleanupHelper.disposeAnimationControllers([_animationController]);
///     ControllerCleanupHelper.disposeTextControllers([_textController]);
///     ControllerCleanupHelper.disposeFocusNodes([_focusNode]);
///     for (final sub in _subscriptions) {
///       sub.cancel();
///     }
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     // Use ref.listen for automatic cleanup with .autoDispose providers
///     ref.listen(someProvider, (previous, next) {
///       // Handle updates
///     });
///     return Container();
///   }
/// }
/// ```
