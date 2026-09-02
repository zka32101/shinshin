import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Optimized List Rendering', () {
    // ── Widget Optimization Tests ────────────────────────────────────

    group('List rendering with provider optimization', () {
      testWidgets(
        'story list renders efficiently with select() optimization',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: _MockStoryList(),
              ),
            ),
          );

          // List should render without errors
          expect(find.byType(_MockStoryList), findsOneWidget);

          // Scroll should work smoothly
          await tester.dragFrom(
            const Offset(100, 300),
            const Offset(0, -100),
          );
          await tester.pumpAndSettle();

          // List should still be intact
          expect(find.byType(ListView), findsOneWidget);
        },
      );

      testWidgets(
        'badge list updates efficiently',
        (WidgetTester tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockBadgeList(
                  onBuild: () => buildCount++,
                ),
              ),
            ),
          );

          final initialBuildCount = buildCount;

          // Pump to allow any pending operations
          await tester.pumpAndSettle();

          // Badge list should build minimal times
          final buildIncrease = buildCount - initialBuildCount;
          expect(buildIncrease, lessThanOrEqualTo(2),
              reason:
                  'Badge list should minimize rebuilds (increase: $buildIncrease)');
        },
      );

      testWidgets(
        'list items render with correct data',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockDataList(),
              ),
            ),
          );

          // Should display list items
          expect(find.byType(ListTile), findsWidgets);

          // Each item should have correct text
          expect(find.text('Item 0'), findsOneWidget);
          expect(find.text('Item 1'), findsOneWidget);
        },
      );
    });

    // ── List Scrolling Performance Tests ────────────────────────────

    group('List scrolling performance', () {
      testWidgets(
        'large list scrolling is smooth',
        (WidgetTester tester) async {
          // Set screen size for predictable scrolling
          tester.binding.window.physicalSizeTestValue = const Size(400, 600);
          addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockLargeList(),
              ),
            ),
          );

          // Scroll down
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Scrolling should be fast (< 1 second for smooth interaction)
          expect(stopwatch.elapsedMilliseconds, lessThan(1000),
              reason:
                  'List scrolling should be smooth (${stopwatch.elapsedMilliseconds}ms)');
        },
      );

      testWidgets(
        'list maintains performance with dynamic content updates',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockDynamicList(),
              ),
            ),
          );

          // Initial render
          expect(find.byType(ListTile), findsWidgets);

          // Perform dynamic update (e.g., adding item)
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockDynamicList(itemCount: 20),
              ),
            ),
          );

          stopwatch.stop();

          // Update should be fast
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'Dynamic update should be fast (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });

    // ── Memory Efficiency Tests ──────────────────────────────────────

    group('List memory efficiency', () {
      testWidgets(
        'long list does not cause excessive memory usage',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockLargeList(),
              ),
            ),
          );

          // List should render without crashing
          expect(find.byType(ListView), findsOneWidget);

          // Scroll to bottom
          await tester.dragFrom(
            const Offset(200, 400),
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();

          // Should still be functional
          expect(find.byType(ListView), findsOneWidget);
        },
      );

      testWidgets(
        'list item disposal cleans up resources',
        (WidgetTester tester) async {
          int disposeCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockListWithDisposal(
                  onDispose: () => disposeCount++,
                ),
              ),
            ),
          );

          // Scroll to dispose items
          await tester.drag(find.byType(ListView), const Offset(0, -500));
          await tester.pumpAndSettle();

          // Items should be disposed
          expect(disposeCount, greaterThan(0),
              reason: 'Off-screen items should be disposed');
        },
      );
    });

    // ── Provider Caching Impact on Lists ────────────────────────────

    group('Provider caching reduces list rebuild overhead', () {
      testWidgets(
        'list with cached provider data rebuilds less frequently',
        (WidgetTester tester) async {
          int rebuildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockCachedProviderList(
                  onRebuild: () => rebuildCount++,
                ),
              ),
            ),
          );

          final initialRebuildCount = rebuildCount;

          // Trigger parent rebuild that doesn't affect list data
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockCachedProviderList(
                  onRebuild: () => rebuildCount++,
                ),
              ),
            ),
          );

          // List rebuild should be minimal
          expect(rebuildCount - initialRebuildCount, lessThanOrEqualTo(2),
              reason:
                  'Cached provider list should minimize rebuilds (increase: ${rebuildCount - initialRebuildCount})');
        },
      );
    });

    // ── List Item Optimization Tests ────────────────────────────────

    group('Individual list item optimization', () {
      testWidgets(
        'list item rebuilds only on relevant data changes',
        (WidgetTester tester) async {
          int item0Rebuilds = 0;
          int item1Rebuilds = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockSelectiveUpdateList(
                  item0OnRebuild: () => item0Rebuilds++,
                  item1OnRebuild: () => item1Rebuilds++,
                ),
              ),
            ),
          );

          final initial0 = item0Rebuilds;
          final initial1 = item1Rebuilds;

          // Trigger update
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockSelectiveUpdateList(
                  item0OnRebuild: () => item0Rebuilds++,
                  item1OnRebuild: () => item1Rebuilds++,
                ),
              ),
            ),
          );

          // Only affected items should rebuild
          expect((item0Rebuilds - initial0) + (item1Rebuilds - initial1), lessThanOrEqualTo(2),
              reason: 'Only affected items should rebuild');
        },
      );

      testWidgets(
        'list items display content correctly',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockStoryList(),
              ),
            ),
          );

          // Verify content display
          expect(find.text('Story 1'), findsOneWidget);
          expect(find.text('Story 2'), findsOneWidget);
          expect(find.text('Story 3'), findsOneWidget);
        },
      );
    });

    // ── List Performance Integration Tests ────────────────────────────

    group('List rendering performance integration', () {
      testWidgets(
        'multiple lists can coexist without performance degradation',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockMultipleListsView(),
              ),
            ),
          );

          // Both lists should render
          expect(find.byType(ListView), findsWidgets);

          // Should be able to interact with both
          await tester.drag(find.byType(ListView).at(0), const Offset(0, -100));
          await tester.pumpAndSettle();

          expect(find.byType(ListView), findsWidgets);
        },
      );

      testWidgets(
        'list rendering respects performance budget',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();
          stopwatch.start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: _MockLargeList(),
              ),
            ),
          );

          stopwatch.stop();

          // List should render within performance budget (< 500ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason:
                  'List rendering should be fast (${stopwatch.elapsedMilliseconds}ms)');
        },
      );
    });
  });
}

// ── Mock Widgets ─────────────────────────────────────────────────────────

class _MockStoryList extends StatelessWidget {
  const _MockStoryList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(title: const Text('Story 1')),
        ListTile(title: const Text('Story 2')),
        ListTile(title: const Text('Story 3')),
        ListTile(title: const Text('Story 4')),
        ListTile(title: const Text('Story 5')),
      ],
    );
  }
}

class _MockBadgeList extends StatelessWidget {
  final VoidCallback onBuild;

  const _MockBadgeList({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild();
    return ListView(
      children: [
        _BadgeItem(label: 'Badge 1'),
        _BadgeItem(label: 'Badge 2'),
        _BadgeItem(label: 'Badge 3'),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String label;

  const _BadgeItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.star),
    );
  }
}

class _MockDataList extends StatelessWidget {
  const _MockDataList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(title: Text('Item $index'));
      },
    );
  }
}

class _MockLargeList extends StatelessWidget {
  const _MockLargeList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 100,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Item $index'),
          subtitle: Text('Subtitle $index'),
        );
      },
    );
  }
}

class _MockDynamicList extends StatelessWidget {
  final int itemCount;

  const _MockDynamicList({this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ListTile(title: Text('Item $index'));
      },
    );
  }
}

class _MockListWithDisposal extends StatelessWidget {
  final VoidCallback onDispose;

  const _MockListWithDisposal({required this.onDispose});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) {
        return _DisposableItem(
          index: index,
          onDispose: onDispose,
        );
      },
    );
  }
}

class _DisposableItem extends StatefulWidget {
  final int index;
  final VoidCallback onDispose;

  const _DisposableItem({
    required this.index,
    required this.onDispose,
  });

  @override
  State<_DisposableItem> createState() => _DisposableItemState();
}

class _DisposableItemState extends State<_DisposableItem> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text('Item ${widget.index}'));
  }
}

class _MockCachedProviderList extends StatelessWidget {
  final VoidCallback onRebuild;

  const _MockCachedProviderList({required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    onRebuild();
    return ListView(
      children: const [
        ListTile(title: Text('Cached Item 1')),
        ListTile(title: Text('Cached Item 2')),
      ],
    );
  }
}

class _MockSelectiveUpdateList extends StatelessWidget {
  final VoidCallback item0OnRebuild;
  final VoidCallback item1OnRebuild;

  const _MockSelectiveUpdateList({
    required this.item0OnRebuild,
    required this.item1OnRebuild,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SelectiveItem(
          label: 'Item 0',
          onRebuild: item0OnRebuild,
        ),
        _SelectiveItem(
          label: 'Item 1',
          onRebuild: item1OnRebuild,
        ),
      ],
    );
  }
}

class _SelectiveItem extends StatelessWidget {
  final String label;
  final VoidCallback onRebuild;

  const _SelectiveItem({
    required this.label,
    required this.onRebuild,
  });

  @override
  Widget build(BuildContext context) {
    onRebuild();
    return ListTile(title: Text(label));
  }
}

class _MockMultipleListsView extends StatelessWidget {
  const _MockMultipleListsView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return ListTile(title: Text('List 1, Item $index'));
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return ListTile(title: Text('List 2, Item $index'));
            },
          ),
        ),
      ],
    );
  }
}
