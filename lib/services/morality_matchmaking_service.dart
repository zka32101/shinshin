import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/shared_core.dart' show MatchmakingHandlers, MatchHandlers;

/// 道徳アプリ固有のマッチメイキング・バトル処理
class MoralityMatchmakingService {
  static const String subject = 'morality';

  /// Firestore での subject コレクション名
  static String get collectionPath => 'matchmaking/$subject/pending_requests';

  static String get leaderboardPath => 'leaderboards/$subject/entries';

  /// shared_core の MatchmakingHandlers を実装
  static final MatchmakingHandlers matchmakingHandlers = MatchmakingHandlers(
    onRequestMatch: (userId, userRating, gradeLevel) async {
      final firestore = FirebaseFirestore.instance;

      // pending_requests に 30秒間のタイムアウト付きで登録
      final docRef = firestore.collection(collectionPath).doc();
      await docRef.set({
        'userId': userId,
        'rating': userRating,
        'gradeLevel': gradeLevel,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(seconds: 30)),
        ),
      });

      // 30秒待機後、ドキュメントがまだ存在するか確認
      await Future.delayed(const Duration(seconds: 30));
      final doc = await docRef.get();

      // マッチメイキング成功: ドキュメントが削除されている
      // マッチメイキング失敗: ドキュメントがまだ存在
      return !doc.exists;
    },

    onFindOpponent: (userRating, gradeLevel) async {
      final firestore = FirebaseFirestore.instance;

      // ±300 レート範囲内の opponent を探す
      final minRating = userRating - 300;
      final maxRating = userRating + 300;

      final query = firestore.collection(collectionPath)
          .where('rating', isGreaterThanOrEqualTo: minRating)
          .where('rating', isLessThanOrEqualTo: maxRating)
          .where('gradeLevel', isEqualTo: gradeLevel)
          .orderBy('createdAt')
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return null;

      final opponentDoc = snapshot.docs.first;
      final opponentData = opponentDoc.data() as Map<String, dynamic>;

      return {
        'userId': opponentData['userId'] as String,
        'rating': opponentData['rating'] as int,
      };
    },
  );

  /// shared_core の MatchHandlers を実装
  static final MatchHandlers matchHandlers = MatchHandlers(
    onRecordBattleResult: (matchId, winnerId, loserId, winnerScore, loserScore) async {
      final firestore = FirebaseFirestore.instance;

      // ¥100 の手数料を控除（¥900に変換）
      final winnerPayout = 900;
      final loserPayout = 100;

      // Firestore transaction でレート・スコア更新
      await firestore.runTransaction((transaction) async {
        // 優勝者のレート更新
        final winnerRef = firestore.collection('users').doc(winnerId);
        final winnerDoc = await transaction.get(winnerRef);
        final winnerRating = (winnerDoc['rating'] as int?) ?? 1500;

        transaction.update(winnerRef, {
          'rating': winnerRating + 50,
          'totalMatches': (winnerDoc['totalMatches'] as int?) ?? 0 + 1,
          'winCount': (winnerDoc['winCount'] as int?) ?? 0 + 1,
          'lastActivityAt': Timestamp.now(),
        });

        // 敗北者のレート更新
        final loserRef = firestore.collection('users').doc(loserId);
        final loserDoc = await transaction.get(loserRef);
        final loserRating = (loserDoc['rating'] as int?) ?? 1500;

        transaction.update(loserRef, {
          'rating': (loserRating - 50).clamp(0, 100000),
          'totalMatches': (loserDoc['totalMatches'] as int?) ?? 0 + 1,
          'lastActivityAt': Timestamp.now(),
        });

        // マッチ結果を記録
        final matchRef = firestore.collection('matches').doc(matchId);
        transaction.set(matchRef, {
          'subject': subject,
          'winnerId': winnerId,
          'loserId': loserId,
          'winnerScore': winnerScore,
          'loserScore': loserScore,
          'completedAt': Timestamp.now(),
        });
      });

      return {
        'winnerPayout': winnerPayout,
        'loserPayout': loserPayout,
      };
    },

    onGetLeaderboard: (limit, offset) async {
      final firestore = FirebaseFirestore.instance;

      final snapshot = await firestore
          .collection(leaderboardPath)
          .orderBy('rating', descending: true)
          .limit(limit)
          .offset(offset)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'userId': data['userId'] as String,
          'displayName': data['displayName'] as String,
          'rating': data['rating'] as int,
          'totalMatches': data['totalMatches'] as int,
          'winCount': data['winCount'] as int,
        };
      }).toList();
    },
  );
}
