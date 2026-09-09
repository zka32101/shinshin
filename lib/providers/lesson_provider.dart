import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/lesson_data.dart';
import '../models/lesson.dart';

const _readKeyPrefix = 'lesson_read_';

/// 「学ぶ」記事の既読状態プロバイダー。
/// バッジ（earnedBadgesProvider）と違い、記事の既読は端末ローカルの
/// 好みに過ぎないため Firestore ではなく SharedPreferences に保存する
/// （locale_provider.dart と同じ方式）。
final lessonProvider =
    StateNotifierProvider<LessonNotifier, Set<String>>((ref) {
  return LessonNotifier();
});

/// 記事一覧プロバイダー（アプリバンドル内の静的データをそのまま返す）
final allLessonsProvider = Provider<List<Lesson>>((ref) => kDoutokuLessons);

/// 既読数プロバイダー（一覧画面のヘッダー表示用）
final lessonReadCountProvider = Provider<int>((ref) {
  return ref.watch(lessonProvider).length;
});

/// 既読管理 Notifier。起動時に SharedPreferences から既読 ID 一覧を読み込む。
class LessonNotifier extends StateNotifier<Set<String>> {
  LessonNotifier() : super(const {}) {
    _loadReadIds();
  }

  Future<void> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = <String>{
        for (final lesson in kDoutokuLessons)
          if (prefs.getBool('$_readKeyPrefix${lesson.id}') ?? false) lesson.id,
      };
      state = readIds;
    } catch (e) {
      // 読み込みに失敗しても既読なしの状態で継続
      debugPrint('Failed to load lesson read status: $e');
    }
  }

  bool isRead(String lessonId) => state.contains(lessonId);

  /// 記事を既読にする（すでに既読なら何もしない）
  Future<void> markAsRead(String lessonId) async {
    if (state.contains(lessonId)) return;
    state = {...state, lessonId};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_readKeyPrefix$lessonId', true);
    } catch (e) {
      debugPrint('Failed to save lesson read status: $e');
    }
  }
}
