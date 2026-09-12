import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/models/daily_mission_model.dart';
import 'package:shared_core/models/reward_model.dart';

/// Firestore ベースのデイリーミッション管理サービス
/// Phase 4.5: ゲーミフィケーション統一工事（ミッション機能）
class FirestoreMissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String appId = 'shinshin'; // 道徳コレ アプリID

  /// Handler 1: ミッション取得
  /// Firestore の apps/{appId}/daily_missions/active からミッション定義を取得
  Future<List<DailyMission>> fetchMissions(String appId) async {
    try {
      final doc = await _firestore
          .collection('apps')
          .doc(appId)
          .collection('daily_missions')
          .doc('active')
          .get();

      if (!doc.exists) {
        debugPrint('No daily missions found for appId: $appId');
        return []; // フォールバック: デフォルトミッションは shared_core で使用
      }

      final data = doc.data() as Map<String, dynamic>;
      final missions = (data['missions'] as List?)
          ?.map((m) => DailyMission.fromJson(m as Map<String, dynamic>))
          .toList() ?? [];

      debugPrint('Fetched ${missions.length} missions for $appId');
      return missions;
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      rethrow; // Provider でキャッチされ、デフォルト読込へ
    }
  }

  /// Handler 2: 進捗更新（Firestore 永続化）
  /// ユーザーのミッション進捗を Firestore に保存
  Future<void> updateProgress(
    String userId,
    String missionId,
    int currentValue,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_missions')
          .doc(missionId)
          .update({
        'currentValue': currentValue,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated progress for $missionId: $currentValue');
    } catch (e) {
      debugPrint('Error updating progress: $e');
      // キャッシュは既に更新済みなので、ここはエラー無視
    }
  }

  /// Handler 3: 報酬配布
  /// ミッション完了時に報酬（コイン）をユーザーに付与
  /// Firestore transaction で原子性を保証
  Future<void> completeMission(
    String userId,
    String missionId,
    MissionReward reward,
  ) async {
    try {
      // Firestore transaction で報酬配布
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);

        // ミッション完了マーク
        transaction.update(
          userRef.collection('daily_missions').doc(missionId),
          {
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
          },
        );

        // コイン加算（RewardType.coins の場合）
        if (reward.type == RewardType.coins) {
          final userDoc = await transaction.get(userRef);
          final currentCoins = (userDoc.data()?['coins'] as int?) ?? 0;
          transaction.update(userRef, {
            'coins': currentCoins + reward.amount,
          });

          debugPrint(
            'Awarded ${reward.amount} coins to $userId for $missionId',
          );
        }

        // 報酬ログ（分析用）
        transaction.set(
          userRef.collection('reward_logs').doc(),
          {
            'type': 'mission_completion',
            'missionId': missionId,
            'reward': reward.toJson(),
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      });

      debugPrint('Mission $missionId completed for user $userId');
    } catch (e) {
      debugPrint('Error completing mission: $e');
      rethrow;
    }
  }
}
