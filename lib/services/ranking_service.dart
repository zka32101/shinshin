import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ranking.dart';
import 'logger_service.dart';
import 'api_service.dart';

/// ランキングサービス
/// ユーザーのランキング情報とプライバシー設定を管理
class RankingService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final LoggerService _logger = LoggerService();

  RankingService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  /// ランキング設定を初期化
  Future<void> initializeRankingSettings(String userId) async {
    try {
      final settings = RankingSettings(
        userId: userId,
        isNamePublic: false, // デフォルトは名前非公表
        participateInRanking: true,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('ranking')
          .set(settings.toJson());

      _logger.log('Ranking settings initialized for user: $userId');
    } catch (e) {
      _logger.logError('Failed to initialize ranking settings', error: e);
      rethrow;
    }
  }

  /// ランキング設定を取得
  Future<RankingSettings?> getRankingSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('ranking')
          .get();

      if (!doc.exists) {
        return null;
      }

      return RankingSettings.fromJson(doc.data()!);
    } catch (e) {
      _logger.logError('Failed to get ranking settings', error: e);
      rethrow;
    }
  }

  /// ランキング設定を更新
  Future<void> updateRankingSettings(
    String userId, {
    required bool isNamePublic,
    required bool participateInRanking,
  }) async {
    try {
      final settings = RankingSettings(
        userId: userId,
        isNamePublic: isNamePublic,
        participateInRanking: participateInRanking,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('ranking')
          .update(settings.toJson());

      _logger.log(
        'Ranking settings updated for user: $userId (isNamePublic: $isNamePublic)',
      );
    } catch (e) {
      _logger.logError('Failed to update ranking settings', error: e);
      rethrow;
    }
  }

  /// 指定タイプのランキングを取得（上位N件）
  Future<List<RankingEntry>> getRankingByType(
    RankingType type, {
    int limit = 100,
  }) async {
    try {
      final collectionPath = _getRankingCollectionPath(type);
      final snapshot = await _firestore
          .collection(collectionPath)
          .orderBy('rank')
          .limit(limit)
          .get();

      final entries = <RankingEntry>[];
      for (final doc in snapshot.docs) {
        final entry = RankingEntry.fromJson(doc.data());
        entries.add(entry);
      }

      return entries;
    } catch (e) {
      _logger.logError('Failed to get ranking by type: $type', error: e);
      rethrow;
    }
  }

  /// ユーザーのランキング統計を取得
  Future<RankingStats?> getUserRankingStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('ranking_stats')
          .get();

      if (!doc.exists) {
        return null;
      }

      return RankingStats.fromJson(doc.data()!);
    } catch (e) {
      _logger.logError('Failed to get ranking stats for user: $userId', error: e);
      rethrow;
    }
  }

  /// ランキング統計をリアルタイム取得
  Stream<RankingStats?> getUserRankingStatsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('ranking_stats')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return RankingStats.fromJson(doc.data()!);
    });
  }

  /// ランキングを更新（バックエンド/スケジューラー用）
  Future<void> updateUserRanking(
    String userId,
    int totalScore,
    int monthlyScore,
    Map<String, int> virtueScores,
  ) async {
    try {
      final stats = RankingStats(
        userId: userId,
        totalScore: totalScore,
        monthlyScore: monthlyScore,
        virtueScores: virtueScores,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('ranking_stats')
          .set(stats.toJson(), SetOptions(merge: true));

      _logger.log('Ranking updated for user: $userId');
    } catch (e) {
      _logger.logError('Failed to update ranking', error: e);
      rethrow;
    }
  }

  /// 特定のランキングタイプで自分の順位を取得
  Future<int?> getUserRankInType(String userId, RankingType type) async {
    try {
      final collectionPath = _getRankingCollectionPath(type);
      final snapshot = await _firestore
          .collection(collectionPath)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final entry =
          RankingEntry.fromJson(snapshot.docs.first.data());
      return entry.rank;
    } catch (e) {
      _logger.logError(
        'Failed to get user rank for type: $type',
        error: e,
      );
      rethrow;
    }
  }

  /// ランキング周辺のユーザーを取得（自分を中心に上下5件）
  Future<List<RankingEntry>> getNearbyRankingEntries(
    String userId,
    RankingType type,
  ) async {
    try {
      // ユーザーの現在の順位を取得
      final userRank = await getUserRankInType(userId, type);
      if (userRank == null) {
        return [];
      }

      final collectionPath = _getRankingCollectionPath(type);
      final startRank = (userRank - 5).clamp(1, userRank);
      final endRank = userRank + 5;

      final snapshot = await _firestore
          .collection(collectionPath)
          .where('rank', isGreaterThanOrEqualTo: startRank)
          .where('rank', isLessThanOrEqualTo: endRank)
          .orderBy('rank')
          .get();

      return snapshot.docs
          .map((doc) => RankingEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.logError(
        'Failed to get nearby ranking entries for type: $type',
        error: e,
      );
      rethrow;
    }
  }

  /// ランキング統計をストリーム取得
  Stream<List<RankingEntry>> getRankingByTypeStream(
    RankingType type, {
    int limit = 100,
  }) {
    final collectionPath = _getRankingCollectionPath(type);
    return _firestore
        .collection(collectionPath)
        .orderBy('rank')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RankingEntry.fromJson(doc.data()))
            .toList());
  }

  /// ランキングコレクションパスを取得
  String _getRankingCollectionPath(RankingType type) {
    switch (type) {
      case RankingType.totalPoints:
        return 'rankings/global/total_points';
      case RankingType.monthlyPoints:
        return 'rankings/global/monthly_points';
      case RankingType.virtueCompassion:
        return 'rankings/virtues/compassion';
      case RankingType.virtueHonesty:
        return 'rankings/virtues/honesty';
      case RankingType.virtueResponsibility:
        return 'rankings/virtues/responsibility';
      case RankingType.virtueCourage:
        return 'rankings/virtues/courage';
      case RankingType.virtueRespect:
        return 'rankings/virtues/respect';
      case RankingType.virtueCooperation:
        return 'rankings/virtues/cooperation';
      default:
        throw ArgumentError('Unknown ranking type: $type');
    }
  }

  /// ランキングタイプの日本語表示名を取得
  static String getRankingTypeLabel(RankingType type) {
    switch (type) {
      case RankingType.totalPoints:
        return '総ポイント';
      case RankingType.monthlyPoints:
        return '月間ポイント';
      case RankingType.virtueCompassion:
        return '思いやり';
      case RankingType.virtueHonesty:
        return '正直';
      case RankingType.virtueResponsibility:
        return '責任';
      case RankingType.virtueCourage:
        return '勇気';
      case RankingType.virtueRespect:
        return '尊重';
      case RankingType.virtueCooperation:
        return '協力';
    }
  }

  /// 月間ランキングを取得（API経由）
  ///
  /// [groupValue] は group_type="friends" の場合に必須（自分の child_id を指定する）。
  Future<List<RankingEntry>> getMonthlyRanking(
    RankingGroupType groupType, {
    String? groupValue,
  }) async {
    try {
      final apiService = ApiService();
      _logger.log('Fetching monthly ranking for group type: $groupType');

      // 現在の月をYYYY-MM-01形式で取得
      final today = DateTime.now();
      final rankingMonth =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-01';
      final groupTypeStr = _getRankingGroupTypeString(groupType);

      // バックエンドAPIを呼び出し
      // GET /api/v1/rankings/month/{ranking_month}?group_type=...&group_value=...
      final entries = await apiService.getMonthlyRanking(
        rankingMonth,
        groupTypeStr,
        groupValue: groupValue,
      );

      _logger.log(
          'Monthly ranking fetched: ${entries.length} entries for $rankingMonth ($groupTypeStr)');
      return entries;
    } catch (e) {
      _logger.logError('Failed to get monthly ranking', error: e);
      rethrow;
    }
  }

  /// ランキンググループ化タイプの文字列表現を取得
  String _getRankingGroupTypeString(RankingGroupType type) {
    switch (type) {
      case RankingGroupType.overall:
        return 'overall';
      case RankingGroupType.byGrade:
        return 'by_grade';
      case RankingGroupType.byStartMonth:
        return 'by_start_month';
      case RankingGroupType.combined:
        return 'combined';
      case RankingGroupType.friends:
        return 'friends';
    }
  }
}
