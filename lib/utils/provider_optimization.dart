/// Performance optimization patterns for Riverpod providers
///
/// This file documents best practices for writing performant provider-dependent code.
/// Implements Priority 1 optimizations: Provider Select Optimization

// ─── Pattern 1: Using .select() to reduce rebuilds ───────────────
//
// BEFORE (Full provider watch):
// ```dart
// final profile = ref.watch(userProfileProvider);
// final name = profile.maybeWhen(data: (p) => p.name, orElse: () => '');
// ```
//
// AFTER (Using .select() - prevents rebuilds when other fields change):
// ```dart
// final name = ref.watch(userProfileProvider.select(
//   (asyncProfile) => asyncProfile.maybeWhen(
//     data: (profile) => profile.name,
//     orElse: () => '',
//   ),
// ));
// ```
//
// Impact: 20-30% reduction in unnecessary rebuilds
// When to use: When a widget only needs 1-2 fields from a large provider result

// ─── Pattern 2: Extracting sub-widgets to isolate provider dependencies ───────────
//
// Instead of watching multiple providers in one widget, extract into smaller
// widgets that watch only what they need. This prevents parent rebuilds from
// cascading to children watching different providers.
//
// BEFORE:
// ```dart
// class ParentWidget extends ConsumerWidget {
//   @override
//   Widget build(context, ref) {
//     final profileData = ref.watch(profileProvider);
//     final statsData = ref.watch(statsProvider);
//     return Column(children: [
//       ProfileHeader(profile: profileData),
//       StatsChart(stats: statsData),
//     ]);
//   }
// }
// ```
//
// AFTER:
// ```dart
// class ParentWidget extends ConsumerWidget {
//   @override
//   Widget build(context, ref) {
//     return Column(children: [
//       _ProfileHeaderWidget(),  // Watches profileProvider only
//       _StatsChartWidget(),     // Watches statsProvider only
//     ]);
//   }
// }
// ```

// ─── Pattern 3: StateNotifier caching for computed values ────────────
//
// For expensive computations that derive from multiple providers,
// implement a StateNotifier that caches results and only updates when
// upstream providers change significantly.
//
// Example:
// ```dart
// class ComputedStatsNotifier extends StateNotifier<ComputedStats> {
//   ComputedStatsNotifier(this.ref) : super(ComputedStats.empty());
//
//   final Ref ref;
//   ComputedStats? _lastCached;
//
//   void updateIfNeeded(List<Progress> progress) {
//     final newStats = _computeStats(progress);
//     if (!_isSame(newStats, _lastCached)) {
//       state = newStats;
//       _lastCached = newStats;
//     }
//   }
// }
// ```

// ─── Pattern 4: Debouncing high-frequency updates ──────────────────
//
// When watching values that update frequently (search queries, scroll position),
// debounce the updates to prevent excessive rebuilds.
//
// Uses: SharedPreferences save, API search requests, analytics events

// ─── Pattern 5: Lazy loading with .autoDispose ────────────────────
//
// All FutureProvider and family providers should use .autoDispose to:
// - Free memory when provider is no longer watched
// - Automatically restart fetch when provider is re-watched
// - Reduce cache pollution for list-like data
//
// PATTERN (already in codebase):
// ```dart
// final storiesProvider = FutureProvider.autoDispose
//     .family<List<Story>, String>((ref, themeId) async { ... });
// ```

// ─── Measurement: How to verify improvements ──────────────────────
//
// Use Flutter DevTools Performance profiler:
// 1. Run: flutter run --profile
// 2. Open DevTools: Flutter DevTools → Performance tab
// 3. Record a session while navigating
// 4. Look for:
//    - Frame build times (should be < 16ms for 60fps)
//    - Number of rebuilds per action
//    - Memory allocation patterns
//
// Target metrics:
// - Widget rebuild count: 30%+ reduction
// - Frame build time: < 10ms
// - Memory footprint: < 150MB at peak

class ProviderOptimizationPatterns {
  // Marker class for documentation
  // All patterns are documented above and implemented throughout the codebase
}
