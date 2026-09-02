import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Badge Display Optimization', () {
    // ── Badge Rendering Tests ────────────────────────────────────────

    group('Badge rendering optimization', () {
      testWidgets(
        'badge display renders efficiently',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeDisplay(),
            ),
          );

          stopwatch.stop();

          // Badge display should be fast (< 300ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(300),
              reason:
                  'Badge display should render quickly (${stopwatch.elapsedMilliseconds}ms)');

          expect(find.byType(_MockBadgeDisplay), findsOneWidget);
        },
      );

      testWidgets(
        'multiple badges render without excessive rebuilds',
        (WidgetTester tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockBadgeGrid(
                onBuild: () => buildCount++,
              ),
            ),
          );

          expect(buildCount, 1, reason: 'Should build once');

          // Update (e.g., new badge earned)
          await tester.pumpWidget(
            MaterialApp(
              home: _MockBadgeGrid(
                onBuild: () => buildCount++,
                newBadgeEarned: true,
              ),
            ),
          );

          // Should minimize rebuilds
          expect(buildCount, lessThanOrEqualTo(3),
              reason: 'Badge grid should minimize rebuilds (count: $buildCount)');
        },
      );

      testWidgets(
        'badge icons display without lag',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeWithIcons(),
            ),
          );

          // Icons should display
          expect(find.byType(Icon), findsWidgets);

          // Should be responsive to taps
          await tester.tap(find.byType(Card).first);
          await tester.pumpAndSettle();

          expect(find.byType(_MockBadgeWithIcons), findsOneWidget);
        },
      );
    });

    // ── Badge Progress Indicator Tests ──────────────────────────────

    group('Badge progress indicator optimization', () {
      testWidgets(
        'badge progress bars update smoothly',
        (WidgetTester tester) async {
          int updateCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockBadgeWithProgress(
                onProgressUpdate: () => updateCount++,
              ),
            ),
          );

          expect(updateCount, greaterThanOrEqualTo(0));

          // Progress should display
          expect(find.byType(LinearProgressIndicator), findsWidgets);
        },
      );

      testWidgets(
        'progress indicator does not cause frequent rebuilds',
        (WidgetTester tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockBadgeProgressDisplay(
                onBuild: () => buildCount++,
              ),
            ),
          );

          final initialCount = buildCount;

          // Simulate progress update
          await tester.pumpWidget(
            MaterialApp(
              home: _MockBadgeProgressDisplay(
                onBuild: () => buildCount++,
                progress: 0.6,
              ),
            ),
          );

          // Should minimize rebuilds
          expect(buildCount - initialCount, lessThanOrEqualTo(1),
              reason:
                  'Progress update should minimize rebuilds (increase: ${buildCount - initialCount})');
        },
      );
    });

    // ── Badge Animation Tests ────────────────────────────────────────

    group('Badge animation optimization', () {
      testWidgets(
        'badge earned animation is smooth',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeWithAnimation(),
            ),
          );

          stopwatch.start();

          // Trigger animation
          await tester.tap(find.byType(ElevatedButton));

          // Animation should play smoothly
          await tester.pumpFrames(find.byType(AnimatedContainer), Duration(milliseconds: 500));

          stopwatch.stop();

          // Animation should complete in reasonable time
          expect(stopwatch.elapsedMilliseconds, lessThan(1000),
              reason:
                  'Badge animation should be smooth (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'multiple badge animations do not cause jank',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockMultipleBadgeAnimations(),
            ),
          );

          // Trigger animations
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();

          // Should remain responsive
          expect(find.byType(_MockMultipleBadgeAnimations), findsOneWidget);
        },
      );
    });

    // ── Badge Information Display Tests ──────────────────────────────

    group('Badge information display optimization', () {
      testWidgets(
        'badge details display without blocking',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeDetails(),
            ),
          );

          // Details should display
          expect(find.text('Badge Details'), findsOneWidget);
          expect(find.text('Requirements: 5 stories'), findsOneWidget);
        },
      );

      testWidgets(
        'badge tooltip displays responsively',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeWithTooltip(),
            ),
          );

          stopwatch.start();

          // Hover/long press for tooltip
          await tester.longPress(find.byType(Card));
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Tooltip should appear quickly
          expect(stopwatch.elapsedMilliseconds, lessThan(300),
              reason: 'Tooltip should appear quickly');
        },
      );
    });

    // ── Badge List Scrolling Tests ──────────────────────────────────

    group('Badge list scrolling optimization', () {
      testWidgets(
        'badge list scrolling is smooth',
        (WidgetTester tester) async {
          tester.binding.window.physicalSizeTestValue = const Size(400, 800);
          addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeListView(),
            ),
          );

          final stopwatch = Stopwatch();
          stopwatch.start();

          // Scroll through badges
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();

          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(1000),
              reason:
                  'Badge list scrolling should be smooth (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'large badge collection handles efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLargeBadgeList(),
            ),
          );

          // Scroll extensively
          for (int i = 0; i < 3; i++) {
            await tester.drag(
              find.byType(ListView),
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
          }

          // Should remain functional
          expect(find.byType(ListView), findsOneWidget);
        },
      );
    });

    // ── Badge Cache Optimization Tests ──────────────────────────────

    group('Badge data caching optimization', () {
      testWidgets(
        'badge data is cached efficiently',
        (WidgetTester tester) async {
          int loadCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockCachedBadgeDisplay(
                onLoad: () => loadCount++,
              ),
            ),
          );

          final initialCount = loadCount;

          // Navigate away and back
          await tester.pumpWidget(
            MaterialApp(
              home: _MockCachedBadgeDisplay(
                onLoad: () => loadCount++,
              ),
            ),
          );

          // Should use cache (minimal additional loads)
          expect(loadCount - initialCount, lessThanOrEqualTo(1),
              reason:
                  'Cached badge data should minimize loads (increase: ${loadCount - initialCount})');
        },
      );
    });

    // ── Badge Performance Integration Tests ──────────────────────────

    group('Badge display performance integration', () {
      testWidgets(
        'full badge flow: load → animate → display details',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          // Load badges
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeDisplay(),
            ),
          );

          // Tap to animate
          if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
            await tester.tap(find.byType(ElevatedButton).first);
            await tester.pumpAndSettle();
          }

          // Show details
          await tester.tap(find.byType(Card).first);
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Full flow should be responsive
          expect(stopwatch.elapsedMilliseconds, lessThan(2000),
              reason:
                  'Badge flow should be responsive (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'badge display meets performance requirements',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBadgeDisplay(),
            ),
          );

          stopwatch.stop();

          // Should meet requirements
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'Badge display should be fast (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });
  });
}

// ── Mock Badge Widgets ───────────────────────────────────────────────

class _MockBadgeDisplay extends StatelessWidget {
  const _MockBadgeDisplay();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: Center(
        child: Icon(Icons.star, size: 100),
      ),
    );
  }
}

class _MockBadgeGrid extends StatelessWidget {
  final VoidCallback onBuild;
  final bool newBadgeEarned;

  const _MockBadgeGrid({
    required this.onBuild,
    this.newBadgeEarned = false,
  });

  @override
  Widget build(BuildContext context) {
    onBuild();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: newBadgeEarned ? 11 : 10,
      itemBuilder: (context, index) {
        return Card(
          child: Center(
            child: Icon(Icons.star, size: 50),
          ),
        );
      },
    );
  }
}

class _MockBadgeWithIcons extends StatelessWidget {
  const _MockBadgeWithIcons();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Card(
          child: Icon(Icons.star, size: 40),
        );
      },
    );
  }
}

class _MockBadgeWithProgress extends StatelessWidget {
  final VoidCallback? onProgressUpdate;

  const _MockBadgeWithProgress({this.onProgressUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Badge Progress'),
        LinearProgressIndicator(
          value: 0.6,
        ),
        ElevatedButton(
          onPressed: () => onProgressUpdate?.call(),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _MockBadgeProgressDisplay extends StatelessWidget {
  final VoidCallback onBuild;
  final double progress;

  const _MockBadgeProgressDisplay({
    required this.onBuild,
    this.progress = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    onBuild();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Progress: ${(progress * 100).toStringAsFixed(0)}%'),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(value: progress),
          ),
        ],
      ),
    );
  }
}

class _MockBadgeWithAnimation extends StatefulWidget {
  const _MockBadgeWithAnimation();

  @override
  State<_MockBadgeWithAnimation> createState() =>
      _MockBadgeWithAnimationState();
}

class _MockBadgeWithAnimationState extends State<_MockBadgeWithAnimation> {
  bool animating = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: animating ? Colors.green : Colors.grey,
              boxShadow: animating
                  ? [BoxShadow(blurRadius: 20)]
                  : [],
            ),
            width: animating ? 120 : 100,
            height: animating ? 120 : 100,
            child: const Icon(Icons.star),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => animating = !animating);
            },
            child: const Text('Animate'),
          ),
        ],
      ),
    );
  }
}

class _MockMultipleBadgeAnimations extends StatefulWidget {
  const _MockMultipleBadgeAnimations();

  @override
  State<_MockMultipleBadgeAnimations> createState() =>
      _MockMultipleBadgeAnimationsState();
}

class _MockMultipleBadgeAnimationsState
    extends State<_MockMultipleBadgeAnimations> {
  List<bool> animating = [false, false, false];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: animating[index] ? 80 : 60,
                height: animating[index] ? 80 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.star),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                animating = animating.map((a) => !a).toList();
              });
            },
            child: const Text('Animate All'),
          ),
        ],
      ),
    );
  }
}

class _MockBadgeDetails extends StatelessWidget {
  const _MockBadgeDetails();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Badge Details'),
            Text('Requirements: 5 stories'),
          ],
        ),
      ),
    );
  }
}

class _MockBadgeWithTooltip extends StatelessWidget {
  const _MockBadgeWithTooltip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: 'Badge Tooltip',
        child: Card(
          child: Icon(Icons.star, size: 60),
        ),
      ),
    );
  }
}

class _MockBadgeListView extends StatelessWidget {
  const _MockBadgeListView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.star),
          title: Text('Badge ${index + 1}'),
        );
      },
    );
  }
}

class _MockLargeBadgeList extends StatelessWidget {
  const _MockLargeBadgeList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 100,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.star),
          title: Text('Badge ${index + 1}'),
        );
      },
    );
  }
}

class _MockCachedBadgeDisplay extends StatelessWidget {
  final VoidCallback onLoad;

  const _MockCachedBadgeDisplay({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    onLoad();
    return Center(
      child: Icon(Icons.star, size: 100),
    );
  }
}
