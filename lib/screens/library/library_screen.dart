import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/virtue_constants.dart';
import '../../models/story.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/story_provider.dart'; // weeklyThemeProvider
import '../../providers/story_provider_fs.dart'; // storiesFsProvider
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import '../story/story_learning_screen.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFF5F5F5);
const _cardColor = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF333333);
const _textSecondary = Color(0xFF999999);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _primaryColor,
            title: const Text(
              'ライブラリ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: '今週'),
                Tab(text: 'テーマ'),
                Tab(text: '完了済み'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _WeeklyTab(),
            _ThemeTab(
              selectedTheme: _selectedTheme,
              onThemeChanged: (t) => setState(() => _selectedTheme = t),
            ),
            const _CompletedTab(),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final weekNum = (now.difference(DateTime(now.year, 1, 1)).inDays ~/ 7) + 1;
    final storiesAsync = ref.watch(weeklyThemeProvider(weekNum));
    return storiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (stories) => stories.isEmpty
          ? const _EmptyView(message: '今週のストーリーはまだありません')
          : _StoryList(stories: stories),
    );
  }
}

class _ThemeTab extends ConsumerWidget {
  final String? selectedTheme;
  final ValueChanged<String?> onThemeChanged;
  const _ThemeTab({required this.selectedTheme, required this.onThemeChanged});

  static List<(String, String?)> get _themes => [
    ('すべて', null),
    ...VirtueConstants.themes.map(
      (theme) => (VirtueConstants.getVirtueLabel(theme), theme),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(
      storiesFsProvider((theme: selectedTheme, gradeLevel: null, isPremium: null)),
    );
    return Column(
      children: [
        Container(
          color: _cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_themes.length, (index) {
                final t = _themes[index];
                final isSelected = t.$2 == selectedTheme;
                return AnimatedSlideIn(
                  direction: SlideDirection.fromLeft,
                  duration: AnimationDurations.medium,
                  delay: Duration(milliseconds: 100 + (index * 50)),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(t.$1),
                      selected: isSelected,
                      onSelected: (_) => onThemeChanged(t.$2),
                      selectedColor: _primaryColor.withAlpha(40),
                      checkmarkColor: _primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? _primaryColor : _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: storiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
            error: (e, _) => _ErrorView(error: e.toString()),
            data: (stories) => stories.isEmpty
                ? const _EmptyView(message: 'このテーマのストーリーはありません')
                : _StoryList(stories: stories),
          ),
        ),
      ],
    );
  }
}

class _CompletedTab extends ConsumerWidget {
  const _CompletedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);

    return childAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (child) {
        if (child == null) {
          return const _EmptyView(message: 'お子さんを選択してください', emoji: '👶');
        }
        return _CompletedStoriesList(childId: child.id);
      },
    );
  }
}

class _CompletedStoriesList extends ConsumerWidget {
  final String childId;
  const _CompletedStoriesList({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(completedStoriesProvider(childId));

    return completedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (stories) {
        if (stories.isEmpty) {
          return const _EmptyView(
            message: 'まだ完了したストーリーはありません\nチャレンジしてみよう！',
            emoji: '🏆',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            return AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 100 + (i * 75)),
              child: _CompletedStoryCard(story: stories[i], childId: childId),
            );
          },
        );
      },
    );
  }
}

class _CompletedStoryCard extends StatelessWidget {
  final Story story;
  final String childId;

  const _CompletedStoryCard({required this.story, required this.childId});

  @override
  Widget build(BuildContext context) {
    final themeColor = VirtueConstants.getVirtueColor(story.theme);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(30)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryLearningScreen(
              storyId: story.id,
              childId: childId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 完了バッジ
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle, color: themeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Tag(label: story.theme, color: themeColor),
                        const SizedBox(width: 6),
                        _Tag(
                          label: '${story.durationSeconds ~/ 60}分',
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.replay, color: _textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryList extends ConsumerWidget {
  final List<Story> stories;
  const _StoryList({required this.stories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      itemBuilder: (context, i) => AnimatedSlideIn(
        direction: SlideDirection.fromBottom,
        duration: AnimationDurations.medium,
        delay: Duration(milliseconds: 100 + (i * 75)),
        child: _LibraryStoryCard(
          story: stories[i],
          onTap: () => childAsync.whenData((child) {
            if (child == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('子供プロフィールを作成してください')),
              );
              return;
            }
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StoryLearningScreen(storyId: stories[i].id, childId: child.id),
            ));
          }),
        ),
      ),
    );
  }
}

class _LibraryStoryCard extends StatefulWidget {
  final Story story;
  final VoidCallback onTap;
  const _LibraryStoryCard({required this.story, required this.onTap});


  @override
  State<_LibraryStoryCard> createState() => _LibraryStoryCardState();
}

class _LibraryStoryCardState extends State<_LibraryStoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationDurations.short,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.snappyEasing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = VirtueConstants.getVirtueColor(widget.story.theme);
    final label = VirtueConstants.getVirtueLabel(widget.story.theme);
    final emoji = VirtueConstants.getVirtueEmoji(widget.story.theme);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [BoxShadow(
              color: Colors.black.withAlpha(_isPressed ? 20 : 12),
              blurRadius: _isPressed ? 4 : 8,
              offset: const Offset(0, 2),
            )],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.story.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Tag(label: label, color: color),
                        const SizedBox(width: 6),
                        _Tag(label: '${(widget.story.durationSeconds / 60).round()}分', color: _textSecondary),
                        if (widget.story.isPremium) ...[
                          const SizedBox(width: 6),
                          const _Tag(label: 'Premium', color: Color(0xFFF39C12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}

class _EmptyView extends StatelessWidget {
  final String message;
  final String emoji;
  const _EmptyView({required this.message, this.emoji = '📖'});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(fontSize: 15, color: _textSecondary),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('エラー: $error', style: const TextStyle(color: Colors.red)),
    ),
  );
}
