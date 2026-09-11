import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/models/mission_model.dart';

/// Firestore ベースのデイリーミッション管理サービス
/// Phase 4.5: ゲーミフィケーション統一工事（ミッション機能）
class FirestoreMissionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザー ID を取得
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// ミッションリストを取得（教科別フィルタリング対応）
  Future<List<Mission>> fetchMissions({String? subject}) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // ALL_MISSIONS からフィルタリング
      List<Mission> missions = [...ALL_MISSIONS];

      // 教科別フィルタリング（subject が指定されている場合）
      if (subject != null && subject.isNotEmpty) {
        missions = missions.where((mission) {
          // mission.subject が null なら全教科対応
          if (mission.subject == null) return true;
          return mission.subject == subject;
        }).toList();
      }

      // enabled が true のミッションのみ返却
      missions = missions.where((m) => m.enabled).toList();

      return missions;
    } catch (e) {
      rethrow;
    }
  }

  /// 現在のユーザー ID を返す（初期化用）
  String? getCurrentUserId() => _getCurrentUserId();
}
