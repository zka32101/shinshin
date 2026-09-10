import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/models/ranking_model.dart';

/// shinshin（道徳）用の Firestore ランキング取得サービス。
///
/// shared_core の [RankingFetchHandler] インターフェースを実装し、
/// [rankingProvider.notifier.setFetchHandler()] に注入される。
class FirestoreRankingService {
  final FirebaseFirestore _firestore;

  FirestoreRankingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ランキングデータを Firestore から取得・ソート。
  ///
  /// [RankingFilter] に応じて以下をサポート:
  /// - overall: 全体ランキング
  /// - grade: 同学年ランキング
  /// - gradeAndStartPeriod: 同学年×同時期開始
  ///
  /// 戻り値はスコア降順で順位（rank）を採番した状態で返される。
  Future<List<RankingEntry>> fetchRankings(RankingFilter filter) async {
    Query<Map<String, dynamic>> query = _firestore.collection('users_v3');

    // グレードでフィルタ
    if (filter.grade != null) {
      query = query.where('grade', isEqualTo: filter.grade);
    }

    // 同時期開始でフィルタ
    if (filter.startPeriod != null) {
      final parts = filter.startPeriod!.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      final periodStart = DateTime(year, month, 1);
      final nextMonth = month == 12 ? 1 : month + 1;
      final nextYear = month == 12 ? year + 1 : year;
      final periodEnd = DateTime(nextYear, nextMonth, 1);

      query = query
          .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .where('startedAt', isLessThan: Timestamp.fromDate(periodEnd));
    }

    // スコア降順で最大100件取得
    final snapshot = await query
        .orderBy('stats.totalScore', descending: true)
        .limit(100)
        .get();

    final entries = snapshot.docs.map((doc) {
      final data = doc.data();
      final stats = (data['stats'] as Map<String, dynamic>?) ?? {};

      return RankingEntry(
        userId: doc.id,
        rawName: data['displayName'] as String? ?? 'Player',
        isNamePublic: data['isNamePublic'] as bool? ?? false,
        score: (stats['totalScore'] as int?) ?? 0,
        grade: data['grade'] as int?,
        startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
        isFriend: false, // 友達フラグはアプリ側で別途設定
      );
    }).toList();

    // スコア降順で順位を採番
    return RankingEntry.withRecalculatedRanks(entries);
  }

  /// ユーザーが quiz 完了後にスコアを更新（Firestore トランザクション）。
  ///
  /// スコア加算はこのメソッドで行い、ランキング集計は Cloud Function に委ねる。
  Future<void> updateUserStats({
    required String userId,
    required int pointsEarned,
    required bool isCorrect,
  }) async {
    final userRef = _firestore.collection('users_v3').doc(userId);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final stats = (data['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      final totalScore = (stats['totalScore'] as int? ?? 0) + (isCorrect ? pointsEarned : 0);
      final totalCorrect = (stats['totalCorrect'] as int? ?? 0) + (isCorrect ? 1 : 0);
      final totalPlayed = (stats['totalPlayed'] as int? ?? 0) + 1;
      final correctRate = totalPlayed > 0 ? totalCorrect / totalPlayed : 0.0;

      tx.set(
        userRef,
        {
          'stats': {
            'totalScore': totalScore,
            'totalCorrect': totalCorrect,
            'totalPlayed': totalPlayed,
            'correctRate': correctRate,
          },
          'lastPlayedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// 学年・開始日を同期する（ランキング用メタデータ）。
  ///
  /// grade は毎回上書き（進級に対応）。startedAt は初回のみ設定（変わらない）。
  Future<void> syncUserMetadata({
    required String userId,
    required int grade,
    DateTime? startedAt,
  }) async {
    final userRef = _firestore.collection('users_v3').doc(userId);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      final data = snapshot.data();

      final updates = <String, dynamic>{
        'grade': grade,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // startedAt は初回のみ設定
      if (data?['startedAt'] == null && startedAt != null) {
        updates['startedAt'] = Timestamp.fromDate(startedAt);
      }

      tx.set(userRef, updates, SetOptions(merge: true));
    });
  }
}
