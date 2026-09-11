import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/models/friend_model.dart';

/// shinshin（道徳）用の Firestore 友達管理サービス。
///
/// shared_core の [FriendFetchHandler], [FriendAddHandler], [FriendRemoveHandler]
/// インターフェースを実装し、[friendProvider.notifier] に注入される。
class FirestoreFriendService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreFriendService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// 友達一覧を取得（FriendFetchHandler実装）。
  ///
  /// 現在ユーザーの `friends/{userId}/friend_list` から全友達を読み込む。
  Future<List<Friend>> fetchFriends() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('friends')
          .doc(userId)
          .collection('friend_list')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Friend.fromJson(doc.data()))
          .toList();
    } catch (e) {
      // コレクション未作成時は空リスト
      return [];
    }
  }

  /// 友達を追加（FriendAddHandler実装）。
  ///
  /// [friendCodeOrId] は friendUserId。
  /// Firestore トランザクションで双方向リレーションを作成する。
  Future<Friend> addFriend(String friendCodeOrId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    if (userId == friendCodeOrId) {
      throw Exception('Cannot add yourself as friend');
    }

    late Friend addedFriend;

    await _firestore.runTransaction((tx) async {
      // 相手ユーザーの情報を取得
      final friendDoc = await tx.get(
        _firestore.collection('users_v3').doc(friendCodeOrId),
      );

      if (!friendDoc.exists) throw Exception('Friend user not found');

      final friendData = friendDoc.data()!;
      final friendDisplayName = friendData['displayName'] as String? ?? 'Player';
      final friendGrade = friendData['grade'] as int?;

      // 相手を自分のフレンド一覧に追加
      final friendRef = _firestore
          .collection('friends')
          .doc(userId)
          .collection('friend_list')
          .doc(friendCodeOrId);

      tx.set(friendRef, {
        'friendUserId': friendCodeOrId,
        'displayName': friendDisplayName,
        'grade': friendGrade,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 自分を相手のフレンド一覧に追加
      final myDoc = await tx.get(
        _firestore.collection('users_v3').doc(userId),
      );
      final myDisplayName = (myDoc.data()?['displayName'] as String?) ?? 'Player';
      final myGrade = myDoc.data()?['grade'] as int?;

      final myRef = _firestore
          .collection('friends')
          .doc(friendCodeOrId)
          .collection('friend_list')
          .doc(userId);

      tx.set(myRef, {
        'friendUserId': userId,
        'displayName': myDisplayName,
        'grade': myGrade,
        'addedAt': FieldValue.serverTimestamp(),
      });

      addedFriend = Friend(
        friendUserId: friendCodeOrId,
        displayName: friendDisplayName,
        grade: friendGrade,
        addedAt: DateTime.now(),
      );
    });

    return addedFriend;
  }

  /// 友達を削除（FriendRemoveHandler実装）。
  ///
  /// Firestore トランザクションで双方向リレーションを削除する。
  Future<void> removeFriend(String friendUserId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.runTransaction((tx) async {
      // 相手を自分のフレンド一覧から削除
      tx.delete(
        _firestore
            .collection('friends')
            .doc(userId)
            .collection('friend_list')
            .doc(friendUserId),
      );

      // 自分を相手のフレンド一覧から削除
      tx.delete(
        _firestore
            .collection('friends')
            .doc(friendUserId)
            .collection('friend_list')
            .doc(userId),
      );
    });
  }
}
