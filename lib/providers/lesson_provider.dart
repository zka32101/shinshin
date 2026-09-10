import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart' show LessonContent;

const _readPrefix = 'shinshin_lesson_read_';
const _favoritePrefix = 'shinshin_lesson_favorite_';

class LessonState {
  final List<LessonContent> lessons;
  final Set<String> readIds;
  final Set<String> favoriteIds;

  const LessonState({
    required this.lessons,
    required this.readIds,
    required this.favoriteIds,
  });

  static const empty = LessonState(lessons: [], readIds: {}, favoriteIds: {});

  LessonState copyWith({
    List<LessonContent>? lessons,
    Set<String>? readIds,
    Set<String>? favoriteIds,
  }) =>
      LessonState(
        lessons: lessons ?? this.lessons,
        readIds: readIds ?? this.readIds,
        favoriteIds: favoriteIds ?? this.favoriteIds,
      );

  bool isRead(String id) => readIds.contains(id);
  bool isFavorite(String id) => favoriteIds.contains(id);
  int get readCount => readIds.length;
}

class LessonNotifier extends Notifier<LessonState> {
  // 各アプリが定義した解説記事一覧をセット
  List<LessonContent> _appLessons = [];

  void setLessons(List<LessonContent> lessons) {
    _appLessons = lessons;
  }

  @override
  LessonState build() {
    // Load read/favorite state from SharedPreferences on initialization
    _loadAsync();
    return LessonState.empty;
  }

  Future<void> _loadAsync() async {
    // Async loading happens in background after build completes
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = <String>{};
      final favorite = <String>{};
      for (final lesson in _appLessons) {
        if (prefs.getBool('$_readPrefix${lesson.id}') ?? false) {
          read.add(lesson.id);
        }
        if (prefs.getBool('$_favoritePrefix${lesson.id}') ?? false) {
          favorite.add(lesson.id);
        }
      }
      if (read.isNotEmpty || favorite.isNotEmpty) {
        state = LessonState(lessons: _appLessons, readIds: read, favoriteIds: favorite);
      }
    } catch (e) {
      // Silently fail if loading doesn't work
    }
  }

  Future<void> load(List<LessonContent> lessons) async {
    _appLessons = lessons;
    final prefs = await SharedPreferences.getInstance();
    final read = <String>{};
    final favorite = <String>{};
    for (final lesson in _appLessons) {
      if (prefs.getBool('$_readPrefix${lesson.id}') ?? false) {
        read.add(lesson.id);
      }
      if (prefs.getBool('$_favoritePrefix${lesson.id}') ?? false) {
        favorite.add(lesson.id);
      }
    }
    state = LessonState(lessons: _appLessons, readIds: read, favoriteIds: favorite);
  }

  Future<void> markAsRead(String lessonId) async {
    if (state.readIds.contains(lessonId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_readPrefix$lessonId', true);
    state = state.copyWith(readIds: {...state.readIds, lessonId});
  }

  Future<void> toggleFavorite(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final next = {...state.favoriteIds};
    if (next.contains(lessonId)) {
      next.remove(lessonId);
      await prefs.remove('$_favoritePrefix$lessonId');
    } else {
      next.add(lessonId);
      await prefs.setBool('$_favoritePrefix$lessonId', true);
    }
    state = state.copyWith(favoriteIds: next);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs
        .getKeys()
        .where((k) => k.startsWith(_readPrefix) || k.startsWith(_favoritePrefix))
        .toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
    state = state.copyWith(readIds: {}, favoriteIds: {});
  }
}

final lessonProvider = NotifierProvider<LessonNotifier, LessonState>(LessonNotifier.new);
