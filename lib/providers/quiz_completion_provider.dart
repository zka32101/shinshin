import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/validation_utils.dart';
import 'story_provider.dart' show apiServiceProvider, hiveServiceProvider;

/// クイズ完了結果
class QuizCompleteResult {
  final int pointsEarned;
  final int newLevel;
  final int newTotalPoints;
  final Map<String, dynamic> scoreDeltas;

  const QuizCompleteResult({
    required this.pointsEarned,
    required this.newLevel,
    required this.newTotalPoints,
    required this.scoreDeltas,
  });

  /// オフライン用フォールバック（ポイント 0 → 呼び出し元でローカル推定値を使用）
  static const offline = QuizCompleteResult(
    pointsEarned: 0,
    newLevel: 0,
    newTotalPoints: 0,
    scoreDeltas: {},
  );
}

// ── キー型 ────────────────────────────────────────────────────────────────────

typedef QuizStartKey = ({String childId, String storyId});
typedef QuizCompleteKey = ({
  String sessionId,
  String childId,
  String chosenChoiceId,
  int timeSpentSeconds,
  String? reflectionText,
});

// ── クイズ開始プロバイダー ─────────────────────────────────────────────────────

/// POST /api/v1/quizzes — クイズセッション開始。セッション ID を返す。
/// オフライン・API エラー時は例外を throw → 呼び出し元が _sessionId = null のまま続行。
final quizStartProvider =
    FutureProvider.autoDispose.family<String, QuizStartKey>((ref, key) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.startQuizSession(
    childId: key.childId,
    storyId: key.storyId,
  );
  // レスポンスキーは camelCase (id)
  final sessionId = data['id'] as String?;
  if (sessionId == null) {
    throw StateError('startQuizSession returned no id');
  }
  return sessionId;
});

// ── クイズ完了プロバイダー ─────────────────────────────────────────────────────

/// POST /api/v1/quizzes/{sessionId}/complete — クイズ完了・スコア更新。
/// オフライン時は QuizCompleteResult.offline を返す（pointsEarned == 0）。
/// Input validation is performed to prevent injection attacks and sanitize child-provided text.
final quizCompleteProvider =
    FutureProvider.autoDispose.family<QuizCompleteResult, QuizCompleteKey>(
        (ref, key) async {
  final api = ref.watch(apiServiceProvider);
  final hive = ref.read(hiveServiceProvider);
  try {
    // Validate all inputs before sending to API
    if (!ValidationUtils.isValidSessionId(key.sessionId)) {
      throw ArgumentError('Invalid sessionId: ${key.sessionId}');
    }
    if (!ValidationUtils.isValidChoiceId(key.chosenChoiceId)) {
      throw ArgumentError('Invalid chosenChoiceId: ${key.chosenChoiceId}');
    }
    if (!ValidationUtils.isValidTimeSpent(key.timeSpentSeconds)) {
      throw ArgumentError('Invalid timeSpentSeconds: ${key.timeSpentSeconds}');
    }

    // Validate and sanitize reflection text
    final sanitizedReflection = ValidationUtils.validateReflectionText(key.reflectionText);

    final data = await api.completeQuizSession(
      sessionId: key.sessionId,
      chosenChoiceId: key.chosenChoiceId,
      timeSpentSeconds: key.timeSpentSeconds,
      reflectionText: sanitizedReflection,
    );
    return QuizCompleteResult(
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
      newLevel: (data['newLevel'] as num?)?.toInt() ?? 0,
      newTotalPoints: (data['newTotalPoints'] as num?)?.toInt() ?? 0,
      scoreDeltas: (data['scoreDeltas'] as Map<String, dynamic>?) ?? {},
    );
  } catch (_) {
    // オフライン or API エラー → Hive に同期キューイングして後で再送
    // Sanitize reflection text before queuing offline
    final sanitizedReflection = ValidationUtils.validateReflectionText(key.reflectionText);
    unawaited(hive.enqueuePendingQuizCompletion({
      'sessionId': key.sessionId,
      'chosenChoiceId': key.chosenChoiceId,
      'timeSpentSeconds': key.timeSpentSeconds,
      if (sanitizedReflection != null) 'reflectionText': sanitizedReflection,
    }));
    return QuizCompleteResult.offline;
  }
});
