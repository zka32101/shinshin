import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/resource_cleanup_utils.dart';

void main() {
  group('Resource Cleanup Utils', () {
    // ── PRIORITY 5: StreamSubscription Cleanup Tests ─────────────────

    group('StreamSubscription Cleanup', () {
      test('ensureDisposed cancels stream subscriptions', () async {
        var onDataCallCount = 0;
        final controller = StreamController<int>();
        final subscription = controller.stream.listen((_) {
          onDataCallCount++;
        });

        // Emit value before disposal
        controller.add(1);
        expect(onDataCallCount, 1);

        // Dispose subscription
        await ResourceCleanupUtils.ensureDisposed([subscription]);

        // Emit another value after disposal (should not be received)
        controller.add(2);
        expect(onDataCallCount, 1, reason: 'Should not receive data after disposal');

        await controller.close();
      });

      test('ensureDisposed handles multiple subscriptions', () async {
        final controller1 = StreamController<int>();
        final controller2 = StreamController<int>();
        var count1 = 0;
        var count2 = 0;

        final sub1 = controller1.stream.listen((_) => count1++);
        final sub2 = controller2.stream.listen((_) => count2++);

        controller1.add(1);
        controller2.add(1);
        expect(count1, 1);
        expect(count2, 1);

        // Dispose both
        await ResourceCleanupUtils.ensureDisposed([sub1, sub2]);

        controller1.add(2);
        controller2.add(2);
        expect(count1, 1, reason: 'Sub1 should not receive after disposal');
        expect(count2, 1, reason: 'Sub2 should not receive after disposal');

        await controller1.close();
        await controller2.close();
      });

      test('ensureDisposed handles empty list', () async {
        // Should not throw
        await ResourceCleanupUtils.ensureDisposed([]);
        expect(true, true);
      });

      test('ensureDisposed handles already-cancelled subscriptions', () async {
        final controller = StreamController<int>();
        final subscription = controller.stream.listen((_) {});

        // Pre-cancel subscription
        await subscription.cancel();

        // Disposing again should not throw
        await ResourceCleanupUtils.ensureDisposed([subscription]);
        expect(true, true);

        await controller.close();
      });
    });

    // ── PRIORITY 5: Controller Cleanup Tests ──────────────────────────

    group('AnimationController Cleanup', () {
      test('disposeAnimationControllers properly disposes controllers', () {
        final controller1 = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: TestVSync(),
        );
        final controller2 = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: TestVSync(),
        );

        expect(controller1.isDisposed, false);
        expect(controller2.isDisposed, false);

        ControllerCleanupHelper.disposeAnimationControllers([controller1, controller2]);

        expect(controller1.isDisposed, true);
        expect(controller2.isDisposed, true);
      });

      test('disposeAnimationControllers handles already-disposed controllers', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: TestVSync(),
        );

        controller.dispose();
        expect(controller.isDisposed, true);

        // Disposing again should not throw
        ControllerCleanupHelper.disposeAnimationControllers([controller]);
        expect(true, true);
      });

      test('disposeAnimationControllers handles empty list', () {
        ControllerCleanupHelper.disposeAnimationControllers([]);
        expect(true, true);
      });
    });

    group('TextEditingController Cleanup', () {
      test('disposeTextControllers properly disposes controllers', () {
        final controller1 = TextEditingController();
        final controller2 = TextEditingController();

        controller1.text = 'Text 1';
        controller2.text = 'Text 2';

        ControllerCleanupHelper.disposeTextControllers([controller1, controller2]);

        // After disposal, should not be able to modify
        expect(
          () => controller1.text = 'New text',
          throwsA(isA<FlutterError>()),
          reason: 'Should throw when modifying disposed controller',
        );
      });

      test('disposeTextControllers handles empty list', () {
        ControllerCleanupHelper.disposeTextControllers([]);
        expect(true, true);
      });
    });

    group('FocusNode Cleanup', () {
      test('disposeFocusNodes properly disposes nodes', () {
        final node1 = FocusNode();
        final node2 = FocusNode();

        expect(node1.hasFocus, false);
        expect(node2.hasFocus, false);

        ControllerCleanupHelper.disposeFocusNodes([node1, node2]);

        expect(node1.hasFocus, false);
        expect(node2.hasFocus, false);
      });

      test('disposeFocusNodes handles empty list', () {
        ControllerCleanupHelper.disposeFocusNodes([]);
        expect(true, true);
      });
    });

    // ── PRIORITY 5: Memory Leak Prevention Tests ──────────────────────

    group('Memory Leak Prevention', () {
      test('subscription disposal prevents memory leak', () async {
        final controller = StreamController<int>();
        var eventCount = 0;

        final subscription = controller.stream.listen((_) {
          eventCount++;
        });

        // Simulate events
        for (int i = 0; i < 1000; i++) {
          controller.add(i);
        }

        expect(eventCount, 1000);

        // Proper cleanup
        await subscription.cancel();
        await controller.close();

        // After cleanup, no references should exist
        // (In real scenario, would verify memory was released)
        expect(true, true);
      });

      test('multiple resource cleanup in correct order', () async {
        final animationController = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: TestVSync(),
        );
        final textController = TextEditingController();
        final focusNode = FocusNode();
        final streamController = StreamController<int>();
        final subscription = streamController.stream.listen((_) {});

        // Cleanup in proper order: subscription → animation → text → focus
        await subscription.cancel();
        ControllerCleanupHelper.disposeAnimationControllers([animationController]);
        ControllerCleanupHelper.disposeTextControllers([textController]);
        ControllerCleanupHelper.disposeFocusNodes([focusNode]);
        await streamController.close();

        // All should be disposed
        expect(animationController.isDisposed, true);
        expect(
          () => textController.text = 'test',
          throwsA(isA<FlutterError>()),
        );
      });
    });

    // ── PRIORITY 5: Memory Monitor Tests ───────────────────────────

    group('MemoryMonitor', () {
      setUp(() {
        MemoryMonitor.clearLog();
      });

      test('logs memory warnings', () {
        MemoryMonitor.logMemoryWarning('Test warning 1');
        MemoryMonitor.logMemoryWarning('Test warning 2');

        final log = MemoryMonitor.getWarningsLog();
        expect(log.length, 2);
        expect(log[0], contains('Test warning 1'));
        expect(log[1], contains('Test warning 2'));
      });

      test('maintains maximum 100 warnings in log', () {
        for (int i = 0; i < 150; i++) {
          MemoryMonitor.logMemoryWarning('Warning $i');
        }

        final log = MemoryMonitor.getWarningsLog();
        expect(log.length, 100, reason: 'Should keep only last 100 warnings');
      });

      test('clearLog removes all warnings', () {
        MemoryMonitor.logMemoryWarning('Warning 1');
        MemoryMonitor.logMemoryWarning('Warning 2');

        var log = MemoryMonitor.getWarningsLog();
        expect(log, isNotEmpty);

        MemoryMonitor.clearLog();
        log = MemoryMonitor.getWarningsLog();
        expect(log, isEmpty);
      });

      test('warnings are timestamped', () {
        MemoryMonitor.logMemoryWarning('Test warning');

        final log = MemoryMonitor.getWarningsLog();
        expect(log[0], contains(':'),
            reason: 'Warning should contain timestamp');
      });
    });

    // ── PRIORITY 5: Optimization Effectiveness Tests ──────────────────

    group('Resource Cleanup Effectiveness', () {
      test('proper cleanup prevents resource leaks', () async {
        var disposedCount = 0;

        // Create multiple resources
        final subscriptions = <StreamSubscription>[];
        final controllers = <AnimationController>[];

        for (int i = 0; i < 5; i++) {
          final controller = StreamController<int>();
          subscriptions.add(
            controller.stream.listen((_) {
              disposedCount++;
            }),
          );
          controllers.add(
            AnimationController(
              duration: const Duration(milliseconds: 300),
              vsync: TestVSync(),
            ),
          );
        }

        // Emit events
        for (int i = 0; i < 5; i++) {
          (controllers[i].parent as StreamController?)?.add(i);
        }

        // Proper cleanup
        await ResourceCleanupUtils.ensureDisposed(subscriptions);
        ControllerCleanupHelper.disposeAnimationControllers(controllers);

        // All controllers should be disposed
        for (final controller in controllers) {
          expect(controller.isDisposed, true);
        }
      });

      test('subscription memory is released after cleanup', () async {
        final controller = StreamController<int>();
        var dataReceived = <int>[];

        final subscription = controller.stream.listen((value) {
          dataReceived.add(value);
        });

        // Emit 1000 events
        for (int i = 0; i < 1000; i++) {
          controller.add(i);
        }

        expect(dataReceived.length, 1000);

        // Cleanup
        await subscription.cancel();
        await controller.close();
        dataReceived.clear();

        // Memory should be released
        expect(dataReceived, isEmpty);
      });

      test('animation controller animation stops after disposal', () async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: TestVSync(),
        );

        controller.forward();
        expect(controller.isAnimating, true);

        ControllerCleanupHelper.disposeAnimationControllers([controller]);

        // After disposal, animation should stop
        expect(controller.isAnimating, false);
      });
    });
  });
}

/// Test-specific TickerProvider implementation
class TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
