import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import '../../widgets/common_states.dart';

/// 「学ぶ」画面 — 徳目ごとの解説記事一覧
class LessonScreen extends ConsumerWidget {
  const LessonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(allLessonsProvider);
    final readCount = ref.watch(lessonReadCountProvider);

    // 徳目ごとにグループ化（badge_showcase_screen.dart と同じ並び順）
    final themeGroups = <String, List<Lesson>>{};
    for (final lesson in lessons) {
      themeGroups.putIfAbsent(lesson.theme, () => []).add(lesson);
    }
    const themeOrder = [
      'kindness',
      'honesty',
      'courage',
      'respect',
      'cooperation',
      'responsibility',
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('学ぶ'),
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$readCount/${lessons.length} よんだ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: lessons.isEmpty
          ? const CommonEmptyState(
              message: 'まだ解説記事がありません',
              icon: Icons.menu_book_outlined,
            )
          : AnimatedFadeInScale(
              duration: AnimationDurations.medium,
              beginScale: 0.95,
              endScale: 1.0,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final theme in themeOrder)
                    if (themeGroups[theme]?.isNotEmpty ?? false) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Text(
                          kLessonThemeLabels[theme] ?? theme,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      for (final lesson in themeGroups[theme]!)
                        _LessonCard(lesson: lesson),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
    );
  }
}

class _LessonCard extends ConsumerWidget {
  final Lesson lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = ref.watch(lessonProvider).contains(lesson.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.success.withAlpha(20)
                : AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          child: Center(child: Text(lesson.emoji, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${lesson.summary} ・ 読了目安${lesson.estimatedReadMinutes}分',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRead) const Icon(Icons.check_circle, color: AppColors.success, size: 18),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
          );
        },
      ),
    );
  }
}

/// 解説記事の本文表示画面。開くと自動的に既読を記録する。
class LessonDetailScreen extends ConsumerStatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonProvider.notifier).markAsRead(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(lesson.title, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(lesson.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${kLessonThemeLabels[lesson.theme] ?? lesson.theme} ・ 読了目安${lesson.estimatedReadMinutes}分',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final section in lesson.sections) ...[
              if (section.heading != null) ...[
                Text(
                  section.heading!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                section.body,
                style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
