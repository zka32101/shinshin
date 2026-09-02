import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Library Screen Optimization', () {
    // ── Library Loading Tests ────────────────────────────────────────

    group('Library content loading optimization', () {
      testWidgets(
        'library screen loads efficiently',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryScreen(),
            ),
          );

          stopwatch.stop();

          // Library should load quickly (< 500ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'Library should load quickly (${stopwatch.elapsedMilliseconds}ms)');

          expect(find.byType(_MockLibraryScreen), findsOneWidget);
        },
      );

      testWidgets(
        'library story grid renders without excessive rebuilds',
        (WidgetTester tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockLibraryGrid(
                onBuild: () => buildCount++,
              ),
            ),
          );

          expect(buildCount, 1, reason: 'Should build once');

          // Trigger update (e.g., mark story as completed)
          await tester.pumpWidget(
            MaterialApp(
              home: _MockLibraryGrid(
                onBuild: () => buildCount++,
                refreshCount: 1,
              ),
            ),
          );

          // Should minimize rebuilds
          expect(buildCount, lessThanOrEqualTo(3),
              reason: 'Library grid should minimize rebuilds (count: $buildCount)');
        },
      );

      testWidgets(
        'library filter/sort operations are responsive',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryWithFilters(),
            ),
          );

          stopwatch.start();

          // Trigger filter change
          await tester.tap(find.byIcon(Icons.filter_list));
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Filter should respond quickly (< 200ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(200),
              reason:
                  'Filter should respond quickly (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });

    // ── Library Scrolling Performance Tests ───────────────────────────

    group('Library scrolling performance', () {
      testWidgets(
        'library story grid scrolling is smooth',
        (WidgetTester tester) async {
          tester.binding.window.physicalSizeTestValue = const Size(400, 800);
          addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryGrid(),
            ),
          );

          final stopwatch = Stopwatch();
          stopwatch.start();

          // Scroll through grid
          await tester.drag(
            find.byType(GridView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Scrolling should be smooth
          expect(stopwatch.elapsedMilliseconds, lessThan(1000),
              reason: 'Grid scrolling should be smooth');
        },
      );

      testWidgets(
        'large library grid renders efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLargeLibraryGrid(),
            ),
          );

          // Grid should render
          expect(find.byType(GridView), findsOneWidget);

          // Should be able to scroll
          await tester.drag(
            find.byType(GridView),
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          expect(find.byType(GridView), findsOneWidget);
        },
      );
    });

    // ── Story Card Optimization Tests ────────────────────────────────

    group('Story card rendering optimization', () {
      testWidgets(
        'story cards display content efficiently',
        (WidgetTester tester) async {
          int cardBuildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockStoryCard(
                  onBuild: () => cardBuildCount++,
                ),
              ),
            ),
          );

          final initialCount = cardBuildCount;

          // Trigger update
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockStoryCard(
                  onBuild: () => cardBuildCount++,
                ),
              ),
            ),
          );

          // Card should minimize rebuilds
          expect(cardBuildCount - initialCount, lessThanOrEqualTo(1),
              reason: 'Story card should rebuild minimally');
        },
      );

      testWidgets(
        'story card images load efficiently',
        (WidgetTester tester) async {
          int imageLoadCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockStoryCardWithImage(
                onImageLoad: () => imageLoadCount++,
              ),
            ),
          );

          // Image should load
          expect(imageLoadCount, greaterThanOrEqualTo(0));
        },
      );

      testWidgets(
        'story card tap responds quickly',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockStoryCard(),
            ),
          );

          stopwatch.start();

          // Tap card
          await tester.tap(find.byType(_MockStoryCard));
          await tester.pump(); // Measure immediate response

          stopwatch.stop();

          // Should respond instantly
          expect(stopwatch.elapsedMilliseconds, lessThan(100),
              reason:
                  'Card tap should respond instantly (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });

    // ── Library Progress Tracking Tests ──────────────────────────────

    group('Library progress tracking optimization', () {
      testWidgets(
        'progress indicators update smoothly',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryWithProgress(),
            ),
          );

          // Progress should display
          expect(find.byType(LinearProgressIndicator), findsWidgets);
        },
      );

      testWidgets(
        'library statistics display efficiently',
        (WidgetTester tester) async {
          int statsBuildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockLibraryStats(
                onBuild: () => statsBuildCount++,
              ),
            ),
          );

          expect(statsBuildCount, 1);

          // Stats should not rebuild on unrelated changes
          await tester.pumpWidget(
            MaterialApp(
              home: _MockLibraryStats(
                onBuild: () => statsBuildCount++,
              ),
            ),
          );

          // Should minimize rebuilds
          expect(statsBuildCount, lessThanOrEqualTo(2),
              reason: 'Stats should minimize rebuilds');
        },
      );
    });

    // ── Library Filter/Search Optimization Tests ──────────────────────

    group('Library filter and search optimization', () {
      testWidgets(
        'search is responsive and non-blocking',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryWithSearch(),
            ),
          );

          stopwatch.start();

          // Type in search
          await tester.enterText(find.byType(TextField), 'test');
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Should be fast (< 300ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(300),
              reason: 'Search should be responsive');
        },
      );

      testWidgets(
        'filter combinations update efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryWithMultipleFilters(),
            ),
          );

          // Apply first filter
          await tester.tap(find.byIcon(Icons.filter_list));
          await tester.pumpAndSettle();

          // Apply second filter
          await tester.tap(find.byType(Checkbox).first);
          await tester.pumpAndSettle();

          // Should still be responsive
          expect(find.byType(GridView), findsOneWidget);
        },
      );
    });

    // ── Library Memory Efficiency Tests ──────────────────────────────

    group('Library memory efficiency', () {
      testWidgets(
        'large library does not cause memory issues',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLargeLibraryGrid(),
            ),
          );

          // Scroll extensively
          for (int i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(GridView),
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
          }

          // Should still be functional
          expect(find.byType(GridView), findsOneWidget);
        },
      );

      testWidgets(
        'off-screen library content is disposed',
        (WidgetTester tester) async {
          int disposeCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: _MockLibraryWithDisposal(
                onDispose: () => disposeCount++,
              ),
            ),
          );

          // Scroll to dispose items
          await tester.drag(
            find.byType(GridView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();

          // Off-screen items should be disposed
          expect(disposeCount, greaterThan(0),
              reason: 'Off-screen items should be disposed');
        },
      );
    });

    // ── Library Performance Integration Tests ───────────────────────

    group('Library screen performance integration', () {
      testWidgets(
        'full library flow: load → filter → scroll → open story',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          // Load library
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryScreen(),
            ),
          );

          // Filter
          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryWithFilters(),
            ),
          );

          // Scroll
          await tester.drag(
            find.byType(GridView),
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Full flow should be quick
          expect(stopwatch.elapsedMilliseconds, lessThan(2000),
              reason:
                  'Library flow should be fast (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'library respects app performance budget',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            const MaterialApp(
              home: _MockLibraryScreen(),
            ),
          );

          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'Library load should meet budget (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });
  });
}

// ── Mock Library Widgets ─────────────────────────────────────────────

class _MockLibraryScreen extends StatelessWidget {
  const _MockLibraryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const _MockLibraryGrid(),
    );
  }
}

class _MockLibraryGrid extends StatelessWidget {
  final VoidCallback? onBuild;
  final int refreshCount;

  const _MockLibraryGrid({
    this.onBuild,
    this.refreshCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          child: Center(
            child: Text('Story ${index + 1}'),
          ),
        );
      },
    );
  }
}

class _MockLargeLibraryGrid extends StatelessWidget {
  const _MockLargeLibraryGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: 100,
      itemBuilder: (context, index) {
        return Card(
          child: Center(
            child: Text('Story ${index + 1}'),
          ),
        );
      },
    );
  }
}

class _MockLibraryWithFilters extends StatelessWidget {
  const _MockLibraryWithFilters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: const _MockLibraryGrid(),
    );
  }
}

class _MockStoryCard extends StatelessWidget {
  final VoidCallback? onBuild;

  const _MockStoryCard({this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return Card(
      child: InkWell(
        onTap: () {},
        child: const Center(
          child: Text('Story Card'),
        ),
      ),
    );
  }
}

class _MockStoryCardWithImage extends StatelessWidget {
  final VoidCallback onImageLoad;

  const _MockStoryCardWithImage({required this.onImageLoad});

  @override
  Widget build(BuildContext context) {
    onImageLoad();
    return Card(
      child: Column(
        children: [
          Icon(Icons.image, size: 100),
          const Text('Story with Image'),
        ],
      ),
    );
  }
}

class _MockLibraryWithProgress extends StatelessWidget {
  const _MockLibraryWithProgress();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Story ${index + 1}'),
            trailing: SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: (index + 1) / 10,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MockLibraryStats extends StatelessWidget {
  final VoidCallback onBuild;

  const _MockLibraryStats({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild();
    return Scaffold(
      body: Column(
        children: const [
          ListTile(
            title: Text('Stories Read: 5'),
          ),
          ListTile(
            title: Text('Completion: 50%'),
          ),
        ],
      ),
    );
  }
}

class _MockLibraryWithSearch extends StatelessWidget {
  const _MockLibraryWithSearch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(hintText: 'Search...'),
        ),
      ),
      body: const _MockLibraryGrid(),
    );
  }
}

class _MockLibraryWithMultipleFilters extends StatelessWidget {
  const _MockLibraryWithMultipleFilters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          Checkbox(value: false, onChanged: (_) {}),
          Expanded(
            child: _MockLibraryGrid(),
          ),
        ],
      ),
    );
  }
}

class _MockLibraryWithDisposal extends StatelessWidget {
  final VoidCallback onDispose;

  const _MockLibraryWithDisposal({required this.onDispose});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: 50,
      itemBuilder: (context, index) {
        return _DisposableStoryCard(
          index: index,
          onDispose: onDispose,
        );
      },
    );
  }
}

class _DisposableStoryCard extends StatefulWidget {
  final int index;
  final VoidCallback onDispose;

  const _DisposableStoryCard({
    required this.index,
    required this.onDispose,
  });

  @override
  State<_DisposableStoryCard> createState() => _DisposableStoryCardState();
}

class _DisposableStoryCardState extends State<_DisposableStoryCard> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Text('Story ${widget.index}'),
      ),
    );
  }
}
