import '../models/friend.dart';
import 'api_service.dart';
import 'logger_service.dart';

/// 友だち関係サービス
/// 招待コードによる友だち追加・一覧取得・削除をバックエンドAPI経由で行う
class FriendService {
  final ApiService _apiService;
  final LoggerService _logger = LoggerService();

  FriendService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// 友だち一覧を取得
  Future<List<Friend>> getFriends(String childId) async {
    try {
      final friends = await _apiService.getFriends(childId);
      _logger.log('Fetched ${friends.length} friends for child: $childId');
      return friends;
    } catch (e) {
      _logger.logError('Failed to fetch friends for child: $childId', error: e);
      rethrow;
    }
  }

  /// 招待コードを使って友だちを追加する
  Future<Friend> addFriend(String childId, String inviteCode) async {
    try {
      final friend = await _apiService.addFriend(childId, inviteCode);
      _logger.log('Added friend for child: $childId');
      return friend;
    } catch (e) {
      _logger.logError('Failed to add friend for child: $childId', error: e);
      rethrow;
    }
  }

  /// 友だちを削除する
  Future<void> removeFriend(String friendId, String childId) async {
    try {
      await _apiService.removeFriend(friendId, childId);
      _logger.log('Removed friend: $friendId for child: $childId');
    } catch (e) {
      _logger.logError('Failed to remove friend: $friendId', error: e);
      rethrow;
    }
  }
}
