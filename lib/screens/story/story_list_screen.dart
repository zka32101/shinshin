import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story.dart';
import '../../providers/story_provider_fs.dart';
import '../../providers/child_provider.dart';
import '../../constants/virtue_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import 'story_learning_screen.dart';

/// ストーリー一覧画面
/// テーマ別フィルター、難易度表示、プレミアム表記に対応
class StoryListScreen extends ConsumerStatefulWidget {
  const StoryListScreen({super.key});

  @override
  ConsumerState<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends ConsumerState<StoryListScreen> {
  String? _selectedTheme;
  int? _selectedDifficulty;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'ストーリー',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: child.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (childData) => childData == null
            ? const Center(
                child: Text('お子さんを選択してください'),
              )
            : Column(
                children: [
                  // フィルターバー
                  _FilterBar(
                    selectedTheme: _selectedTheme,
                    selectedDifficulty: _selectedDifficulty,
                    onThemeChanged: (theme) =>
                        setState(() => _selectedTheme = theme),
                    onDifficultyChanged: (difficulty) =>
                        setState(() => _selectedDifficulty = difficulty),
                  ),
                  // ストーリーリスト
                  Expanded(
                    child: _StoryListContent(
                      childId: childData.id,
                      gradeLevel: childData.grade,
                      selectedTheme: _selectedTheme,
                      selectedDifficulty: _selectedDifficulty,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// フィルターバー（テーマ、難易度）
class _FilterBar extends StatelessWidget {
  final String? selectedTheme;
  final int? selectedDifficulty;
  final Function(String?) onThemeChanged;
  final Function(int?) onDifficultyChanged;

  const _FilterBar({
    required this.selectedTheme,
    required this.selectedDifficulty,
    required this.onThemeChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // テーマフィルター
          const Text(
            'テーマで選ぶ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'すべて',
                  isSelected: selectedTheme == null,
                  onTap: () => onThemeChanged(null),
                ),
                ...VirtueConstants.themes.map((theme) {
                  return _FilterChip(
                    label: VirtueConstants.getVirtueLabel(theme),
                    isSelected: selectedTheme == theme,
                    onTap: () => onThemeChanged(theme),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 難易度フィルター
          const Text(
            '難易度で選ぶ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FilterChip(
                label: 'すべて',
                isSelected: selectedDifficulty == null,
                onTap: () => onDifficultyChanged(null),
              ),
              for (int i = 1; i <= 3; i++)
                _FilterChip(
                  label: '難易度 $i',
                  isSelected: selectedDifficulty == i,
                  onTap: () => onDifficultyChanged(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// フィルターチップ
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFFEEEEEE),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF666666),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFFDDDDDD),
        ),
      ),
    );
  }
}

/// ストーリーリスト表示
class _StoryListContent extends ConsumerWidget {
  final String childId;
  final int gradeLevel;
  final String? selectedTheme;
  final int? selectedDifficulty;

  const _StoryListContent({
    required this.childId,
    required this.gradeLevel,
    required this.selectedTheme,
    required this.selectedDifficulty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesFsProvider((
      theme: selectedTheme,
      gradeLevel: gradeLevel,
      isPremium: null,
    )));

    return storiesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (stories) {
        // フィルタリング（難易度）
        var filtered = stories;
        if (selectedDifficulty != null) {
          filtered = filtered
              .where((story) => story.difficulty == selectedDifficulty)
              .toList();
        }

        if (filtered.isEmpty) {
          return const _EmptyView(message: 'ストーリーが見つかりません');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final story = filtered[index];
            return _StoryCard(
              story: story,
              childId: childId,
            );
          },
        );
      },
    );
  }
}

/// ストーリーカード
class _StoryCard extends StatelessWidget {
  final Story story;
  final String childId;

  const _StoryCard({
    required this.story,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoryLearningScreen(
                  storyId: story.id,
                  childId: childId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // イラスト
                if (story.illustrationUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: Image.network(
                        story.illustrationUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image, size: 32),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 32),
                    ),
                  ),
                const SizedBox(width: 12),

                // テキスト情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル + プレミアム表記
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              story.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (story.isPremium)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'プレミアム',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 説明
                      if (story.description != null)
                        Text(
                          story.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),

                      // テーマ、難易度、時間
                      Row(
                        children: [
                          // テーマバッジ
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: VirtueConstants.getVirtueColor(story.theme),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              VirtueConstants.getVirtueLabel(story.theme),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 難易度
                          Text(
                            '難易度: ${story.difficulty}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 読了時間
                          Text(
                            '${story.durationSeconds ~/ 60}分',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // チェボン
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// エラー表示
class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// 空状態表示
class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppStyles.bodyLarge,
          ),
        ],
      ),
    );
  }
}
