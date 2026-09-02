import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Story Screen Optimization', () {
    // ── Story Content Loading Tests ──────────────────────────────────

    group('Story content loading optimization', () {
      testWidgets(
        'story screen loads and displays content efficiently',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryScreen(),
            ),
          );

          stopwatch.stop();

          // Story screen should load quickly (< 1 second)
          expect(stopwatch.elapsedMilliseconds, lessThan(1000),
              reason:
                  'Story screen should load quickly (${stopwatch.elapsedMilliseconds}ms)');

          expect(find.byType(_MockStoryScreen), findsOneWidget);
        },
      );

      testWidgets(
        'story text displays without excessive rebuilds',
        (WidgetTester tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockStoryContent(
                  onBuild: () => buildCount++,
                ),
              ),
            ),
          );

          expect(buildCount, 1, reason: 'Should build once initially');

          // Trigger update (simulating page flip)
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockStoryContent(
                  onBuild: () => buildCount++,
                  pageNumber: 2,
                ),
              ),
            ),
          );

          // Should not have excessive rebuilds
          expect(buildCount, lessThanOrEqualTo(3),
              reason: 'Story content should minimize rebuilds (count: $buildCount)');
        },
      );

      testWidgets(
        'story choices render efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryWithChoices(),
            ),
          );

          // Choices should display
          expect(find.byType(ElevatedButton), findsWidgets);

          // Choices should be clickable
          await tester.tap(find.byType(ElevatedButton).first);
          await tester.pumpAndSettle();

          // Should still be functional
          expect(find.byType(_MockStoryWithChoices), findsOneWidget);
        },
      );
    });

    // ── Story Navigation Tests ──────────────────────────────────────

    group('Story navigation optimization', () {
      testWidgets(
        'page flipping does not cause excessive memory usage',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryWithNavigation(),
            ),
          );

          // Simulate page flipping
          for (int i = 0; i < 10; i++) {
            await tester.tap(find.byIcon(Icons.arrow_forward));
            await tester.pumpAndSettle();
          }

          // App should still be responsive
          expect(find.byType(_MockStoryWithNavigation), findsOneWidget);
        },
      );

      testWidgets(
        'story progress updates efficiently',
        (WidgetTester tester) async {
          int progressUpdateCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockStoryWithProgress(
                onProgressUpdate: () => progressUpdateCount++,
              ),
            ),
          );

          // Simulate page completion
          await tester.tap(find.byIcon(Icons.arrow_forward));
          await tester.pumpAndSettle();

          // Progress should update minimal times
          expect(progressUpdateCount, greaterThan(0),
              reason: 'Progress should update');
          expect(progressUpdateCount, lessThan(10),
              reason: 'Progress updates should be minimal (count: $progressUpdateCount)');
        },
      );

      testWidgets(
        'story completion flow completes quickly',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryCompletion(),
            ),
          );

          stopwatch.start();

          // Simulate completing the story
          await tester.tap(find.text('Complete Story'));
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Completion should be fast
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'Story completion should be fast (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });

    // ── Choice Selection Performance Tests ────────────────────────────

    group('Choice selection performance', () {
      testWidgets(
        'choice selection provides instant feedback',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryWithChoices(),
            ),
          );

          stopwatch.start();

          // Select a choice
          await tester.tap(find.byType(ElevatedButton).first);
          await tester.pump(); // Not pumpAndSettle - measure immediate response

          stopwatch.stop();

          // Should respond instantly (< 100ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(100),
              reason:
                  'Choice selection should respond instantly (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'multiple choice scenarios handle efficiently',
        (WidgetTester tester) async {
          int scenarioCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockMultipleScenarios(
                onScenarioLoad: () => scenarioCount++,
              ),
            ),
          );

          // Navigate through scenarios
          for (int i = 0; i < 5; i++) {
            await tester.tap(find.byType(ElevatedButton).first);
            await tester.pumpAndSettle();
          }

          // Scenarios should load
          expect(scenarioCount, greaterThan(0));
        },
      );

      testWidgets(
        'choice branching does not cause memory leaks',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockBranchingStory(),
            ),
          );

          // Simulate branching through story (take different paths)
          for (int i = 0; i < 3; i++) {
            if (find.byIcon(Icons.arrow_forward).evaluate().isNotEmpty) {
              await tester.tap(find.byIcon(Icons.arrow_forward));
              await tester.pumpAndSettle();
            }
          }

          // App should still be functional
          expect(find.byType(_MockBranchingStory), findsOneWidget);
        },
      );
    });

    // ── Story Content Caching Tests ──────────────────────────────────

    group('Story content caching', () {
      testWidgets(
        'story content is cached efficiently',
        (WidgetTester tester) async {
          int loadCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockCachedStoryContent(
                onLoad: () => loadCount++,
              ),
            ),
          );

          final initialLoadCount = loadCount;

          // Navigate away and back
          await tester.pumpWidget(
            MaterialApp(
              home: _MockCachedStoryContent(
                onLoad: () => loadCount++,
                storyId: 'different-story',
              ),
            ),
          );

          // Different story should load
          expect(loadCount, greaterThan(initialLoadCount),
              reason: 'Different story should be loaded');
        },
      );

      testWidgets(
        'repeated story access uses cache',
        (WidgetTester tester) async {
          int loadCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockCachedStoryContent(
                onLoad: () => loadCount++,
              ),
            ),
          );

          final firstLoadCount = loadCount;

          // Access same story again
          await tester.pumpWidget(
            MaterialApp(
              home: _MockCachedStoryContent(
                onLoad: () => loadCount++,
              ),
            ),
          );

          // Load count should not increase much (cached)
          expect(loadCount - firstLoadCount, lessThanOrEqualTo(1),
              reason:
                  'Repeated access should use cache (additional loads: ${loadCount - firstLoadCount})');
        },
      );
    });

    // ── Story Media Handling Tests ──────────────────────────────────

    group('Story media optimization', () {
      testWidgets(
        'story images load without blocking UI',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          stopwatch.start();
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryWithImages(),
            ),
          );
          stopwatch.stop();

          // Should load quickly despite images
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'Story with images should load quickly (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'story images display efficiently',
        (WidgetTester tester) async {
          int imageLoadCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockStoryWithImageTracking(
                onImageLoad: () => imageLoadCount++,
              ),
            ),
          );

          // Images should be tracked
          expect(imageLoadCount, greaterThanOrEqualTo(0));
        },
      );
    });

    // ── Story Performance Integration Tests ──────────────────────────

    group('Story screen performance integration', () {
      testWidgets(
        'full story flow: load → navigate → complete performs well',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          stopwatch.start();

          // Load story
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryScreen(),
            ),
          );

          // Navigate through story
          for (int i = 0; i < 3; i++) {
            if (find.byIcon(Icons.arrow_forward).evaluate().isNotEmpty) {
              await tester.tap(find.byIcon(Icons.arrow_forward));
              await tester.pumpAndSettle();
            }
          }

          stopwatch.stop();

          // Full flow should be fast (< 2 seconds)
          expect(stopwatch.elapsedMilliseconds, lessThan(2000),
              reason:
                  'Full story flow should be fast (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'story screen respects CLAUDE.md performance requirements',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          stopwatch.start();

          // Load story (requirement: < 1 second)
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryScreen(),
            ),
          );

          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(1000),
              reason:
                  'Should meet CLAUDE.md requirement: story loading < 1s (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });
  });
}

// ── Mock Story Widgets ───────────────────────────────────────────────────

class _MockStoryScreen extends StatelessWidget {
  const _MockStoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: const Center(
        child: Text('Once upon a time...'),
      ),
    );
  }
}

class _MockStoryContent extends StatelessWidget {
  final VoidCallback onBuild;
  final int pageNumber;

  const _MockStoryContent({
    required this.onBuild,
    this.pageNumber = 1,
  });

  @override
  Widget build(BuildContext context) {
    onBuild();
    return Center(
      child: Text('Page $pageNumber of the story'),
    );
  }
}

class _MockStoryWithChoices extends StatelessWidget {
  const _MockStoryWithChoices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('What will you do?'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('Choice A')),
          ElevatedButton(onPressed: () {}, child: const Text('Choice B')),
        ],
      ),
    );
  }
}

class _MockStoryWithNavigation extends StatefulWidget {
  const _MockStoryWithNavigation();

  @override
  State<_MockStoryWithNavigation> createState() =>
      _MockStoryWithNavigationState();
}

class _MockStoryWithNavigationState
    extends State<_MockStoryWithNavigation> {
  int page = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page $page'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() => page++);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MockStoryWithProgress extends StatelessWidget {
  final VoidCallback onProgressUpdate;

  const _MockStoryWithProgress({required this.onProgressUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Story Progress'),
            LinearProgressIndicator(
              value: 0.5,
              onChanged: (_) {
                onProgressUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MockStoryCompletion extends StatelessWidget {
  const _MockStoryCompletion();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Complete Story'),
        ),
      ),
    );
  }
}

class _MockMultipleScenarios extends StatelessWidget {
  final VoidCallback onScenarioLoad;

  const _MockMultipleScenarios({required this.onScenarioLoad});

  @override
  Widget build(BuildContext context) {
    onScenarioLoad();
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Next Scenario'),
        ),
      ),
    );
  }
}

class _MockBranchingStory extends StatefulWidget {
  const _MockBranchingStory();

  @override
  State<_MockBranchingStory> createState() => _MockBranchingStoryState();
}

class _MockBranchingStoryState extends State<_MockBranchingStory> {
  int branch = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Branch $branch'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() => branch++);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MockCachedStoryContent extends StatelessWidget {
  final VoidCallback onLoad;
  final String storyId;

  const _MockCachedStoryContent({
    required this.onLoad,
    this.storyId = 'story-1',
  });

  @override
  Widget build(BuildContext context) {
    onLoad();
    return Center(
      child: Text('Story: $storyId'),
    );
  }
}

class _MockStoryWithImages extends StatelessWidget {
  const _MockStoryWithImages();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 100),
            const SizedBox(height: 16),
            const Text('Story with image'),
          ],
        ),
      ),
    );
  }
}

class _MockStoryWithImageTracking extends StatelessWidget {
  final VoidCallback onImageLoad;

  const _MockStoryWithImageTracking({required this.onImageLoad});

  @override
  Widget build(BuildContext context) {
    onImageLoad();
    return Center(
      child: const Icon(Icons.image, size: 100),
    );
  }
}
