import 'package:dio/dio.dart';

import '../models/ai_features.dart';
import '../models/child_profile.dart';
import '../models/distribution_response.dart';
import '../models/friend.dart';
import '../models/kindness_mission.dart';
import '../models/parent_child_comparison.dart';
import '../models/progress.dart';
import '../models/ranking.dart';
import '../models/report.dart';
import '../models/revisit_schedule.dart';
import 'logger_service.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.shougaku-kore.jp/api/v1';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  final _logger = LoggerService();

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// Validates that a string parameter is not empty
  String _validateParam(String value, String paramName) {
    if (value.isEmpty) {
      throw ApiException('Parameter $paramName cannot be empty');
    }
    return value;
  }

  /// Validates response data structure
  bool _isValidResponse(dynamic data) {
    return data != null && data is Map<String, dynamic>;
  }

  /// Retries a request with exponential backoff
  Future<Response<dynamic>> _retryRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    int attempt = 0;
    late DioException lastError;

    while (attempt < _maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        lastError = e;
        // Only retry on transient errors (timeout, connection errors)
        if (!_isTransientError(e)) {
          rethrow;
        }

        attempt++;
        if (attempt < _maxRetries) {
          final delay = _retryDelay * (1 << (attempt - 1)); // exponential backoff
          _logger.log('Retrying request (attempt $attempt/$_maxRetries) after $delay');
          await Future.delayed(delay);
        }
      }
    }

    throw lastError;
  }

  /// Determines if an error is transient (should be retried)
  bool _isTransientError(DioException e) {
    // Timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Network errors
    if (e.type == DioExceptionType.unknown) {
      final error = e.error;
      // Check for connection reset, no route to host, etc.
      if (error is Exception) {
        return error.toString().contains('SocketException') ||
            error.toString().contains('Connection refused') ||
            error.toString().contains('Connection reset');
      }
      return true;
    }

    // Server errors (5xx) are transient
    if (e.response?.statusCode != null &&
        e.response!.statusCode! >= 500 &&
        e.response!.statusCode! < 600) {
      return true;
    }

    return false;
  }

  Future<DistributionResponse> getDistribution(String storyId) async {
    try {
      _validateParam(storyId, 'storyId');

      final response = await _retryRequest(
        () => _dio.get('/stories/$storyId/distribution'),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for distribution');
      }

      _logger.log('Distribution fetched for story: $storyId');
      return DistributionResponse.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch distribution for $storyId', error: e);
      throw ApiException(
        'Failed to fetch distribution: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<RevisitStory>> getRevisitStories(String userId) async {
    try {
      _validateParam(userId, 'userId');

      final response = await _retryRequest(
        () => _dio.get('/users/$userId/revisit-stories'),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for revisit stories');
      }

      final List<dynamic> data = response.data['revisits'] ?? [];
      if (data is! List) {
        throw ApiException('Expected revisits to be a list');
      }

      _logger.log('Revisit stories fetched for user: $userId (count: ${data.length})');
      return data.map((item) => RevisitStory.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch revisit stories for $userId', error: e);
      throw ApiException(
        'Failed to fetch revisit stories: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<RevisitResult> answerRevisitStory(
    String revisitId,
    String answerChoice,
  ) async {
    try {
      _validateParam(revisitId, 'revisitId');
      _validateParam(answerChoice, 'answerChoice');

      final response = await _retryRequest(
        () => _dio.post(
          '/revisit-stories/$revisitId/answer',
          data: {'answer_choice': answerChoice},
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for revisit answer');
      }

      _logger.log('Revisit story answered: $revisitId with choice: $answerChoice');
      return RevisitResult.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to answer revisit story: $revisitId', error: e);
      throw ApiException(
        'Failed to answer revisit story: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<ParentAnswerResponse> answerParentChildStory(
    String parentId,
    String childId,
    String storyId,
    String answerChoice,
  ) async {
    try {
      _validateParam(parentId, 'parentId');
      _validateParam(childId, 'childId');
      _validateParam(storyId, 'storyId');
      _validateParam(answerChoice, 'answerChoice');

      final response = await _retryRequest(
        () => _dio.post(
          '/parent-child/$parentId/$childId/answer',
          data: {
            'story_id': storyId,
            'answer_choice': answerChoice,
          },
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for parent-child answer');
      }

      _logger.log('Parent-child story answered: $storyId');
      return ParentAnswerResponse.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to answer parent-child story', error: e);
      throw ApiException(
        'Failed to answer parent-child story: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<ParentChildComparison>> getParentChildDialogueHistory(
    String parentId,
    String childId,
  ) async {
    try {
      _validateParam(parentId, 'parentId');
      _validateParam(childId, 'childId');

      final response = await _retryRequest(
        () => _dio.get(
          '/parent-child/$parentId/$childId/dialogue-history',
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for dialogue history');
      }

      final List<dynamic> data = response.data['histories'] ?? [];
      if (data is! List) {
        throw ApiException('Expected histories to be a list');
      }

      _logger.log('Dialogue history fetched: ${data.length} items');
      return data.map((item) => ParentChildComparison.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch dialogue history', error: e);
      throw ApiException(
        'Failed to fetch dialogue history: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<ParentChildComparison?> getLatestParentChildComparison(
    String parentId,
    String childId,
  ) async {
    try {
      final histories = await getParentChildDialogueHistory(parentId, childId);
      return histories.isNotEmpty ? histories.first : null;
    } on ApiException {
      rethrow;
    }
  }

  Future<KindnessMission> getCurrentMission(String userId) async {
    try {
      _validateParam(userId, 'userId');

      final response = await _retryRequest(
        () => _dio.get('/users/$userId/kindness/mission'),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for mission');
      }

      _logger.log('Kindness mission fetched for user: $userId');
      return KindnessMission.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch mission for user: $userId', error: e);
      throw ApiException(
        'Failed to fetch mission: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<KindnessRecordResponse> recordKindness(
    String userId,
    String description,
    String? person,
    String? context,
  ) async {
    try {
      _validateParam(userId, 'userId');
      _validateParam(description, 'description');

      final response = await _retryRequest(
        () => _dio.post(
          '/users/$userId/kindness-records',
          data: {
            'kindness_description': description,
            'person_involved': person,
            'context': context,
          },
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for kindness record');
      }

      _logger.log('Kindness recorded for user: $userId');
      return KindnessRecordResponse.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to record kindness for user: $userId', error: e);
      throw ApiException(
        'Failed to record kindness: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<KindnessMap> getKindnessMap(String userId, String month) async {
    try {
      _validateParam(userId, 'userId');
      _validateParam(month, 'month');

      final response = await _retryRequest(
        () => _dio.get(
          '/users/$userId/kindness-map/$month',
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for kindness map');
      }

      _logger.log('Kindness map fetched for user: $userId, month: $month');
      return KindnessMap.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch kindness map for user: $userId', error: e);
      throw ApiException(
        'Failed to fetch kindness map: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  // ③ りゆう記録分析（月50人抽出版）
  Future<ReasonAnalysis?> getReasonAnalysis(String userId, String month) async {
    try {
      _validateParam(userId, 'userId');
      _validateParam(month, 'month');

      final response = await _retryRequest(
        () => _dio.get(
          '/users/$userId/reason-analysis/$month',
        ),
      );

      // No content status
      if (response.statusCode == 204) return null;

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for reason analysis');
      }

      _logger.log('Reason analysis fetched for user: $userId, month: $month');
      return ReasonAnalysis.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.log('Reason analysis not found for user: $userId, month: $month');
        return null;
      }
      _logger.logError('Failed to fetch reason analysis for user: $userId', error: e);
      throw ApiException(
        'Failed to fetch reason analysis: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  // ⑤ 創作フィード — 記録
  Future<void> submitCreation(
    String userId,
    String storyId,
    String storyTitle,
    String userCreatedEnding,
  ) async {
    try {
      _validateParam(userId, 'userId');
      _validateParam(storyId, 'storyId');
      _validateParam(storyTitle, 'storyTitle');
      _validateParam(userCreatedEnding, 'userCreatedEnding');

      await _retryRequest(
        () => _dio.post(
          '/users/$userId/creations',
          data: {
            'story_id': storyId,
            'story_title': storyTitle,
            'user_created_ending': userCreatedEnding,
          },
        ),
      );

      _logger.log('Creation submitted for user: $userId, story: $storyId');
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to submit creation for user: $userId', error: e);
      throw ApiException(
        'Failed to submit creation: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  // ⑤ 創作フィード — 月次フィードバック取得
  Future<CreationFeedback?> getCreationFeedback(
    String userId,
    String month,
  ) async {
    try {
      _validateParam(userId, 'userId');
      _validateParam(month, 'month');

      final response = await _retryRequest(
        () => _dio.get(
          '/users/$userId/creation-feedback/$month',
        ),
      );

      // No content status
      if (response.statusCode == 204) return null;

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for creation feedback');
      }

      _logger.log('Creation feedback fetched for user: $userId, month: $month');
      return CreationFeedback.fromJson(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.log(
          'Creation feedback not found for user: $userId, month: $month',
        );
        return null;
      }
      _logger.logError('Failed to fetch creation feedback for user: $userId', error: e);
      throw ApiException(
        'Failed to fetch creation feedback: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 月間ランキングを取得
  Future<List<RankingEntry>> getMonthlyRanking(
    String month,
    String groupType, {
    String? groupValue,
  }) async {
    try {
      _validateParam(month, 'month');
      _validateParam(groupType, 'groupType');

      final params = {
        'group_type': groupType,
        if (groupValue != null) 'group_value': groupValue,
      };

      final response = await _retryRequest(
        () => _dio.get(
          '/rankings/month/$month',
          queryParameters: params,
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for monthly ranking');
      }

      final List<dynamic> rankings = response.data['rankings'] ?? [];
      if (rankings is! List) {
        throw ApiException('Expected rankings to be a list');
      }

      _logger.log(
          'Monthly ranking fetched: ${rankings.length} entries for $month ($groupType)');
      return rankings.map((item) => RankingEntry.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch monthly ranking for $month', error: e);
      throw ApiException(
        'Failed to fetch monthly ranking: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 友だち一覧を取得
  Future<List<Friend>> getFriends(String childId) async {
    try {
      _validateParam(childId, 'childId');

      final response = await _retryRequest(
        () => _dio.get(
          '/friends',
          queryParameters: {'child_id': childId},
        ),
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException('Invalid response structure for friends list');
      }

      _logger.log('Friends fetched: ${data.length} entries for child: $childId');
      return data
          .map((item) => Friend.fromApiJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch friends for child: $childId', error: e);
      throw ApiException(
        'Failed to fetch friends: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 招待コードを使って友だちを追加
  Future<Friend> addFriend(String childId, String inviteCode) async {
    try {
      _validateParam(childId, 'childId');
      _validateParam(inviteCode, 'inviteCode');

      final response = await _retryRequest(
        () => _dio.post(
          '/friends',
          data: {
            'childId': childId,
            'inviteCode': inviteCode,
          },
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for add friend');
      }

      _logger.log('Friend added for child: $childId');
      return Friend.fromApiJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to add friend for child: $childId', error: e);
      throw ApiException(
        e.response?.data is Map && (e.response?.data as Map)['detail'] != null
            ? (e.response!.data as Map)['detail'].toString()
            : 'Failed to add friend: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 友だちを削除
  Future<void> removeFriend(String friendId, String childId) async {
    try {
      _validateParam(friendId, 'friendId');
      _validateParam(childId, 'childId');

      await _retryRequest(
        () => _dio.delete(
          '/friends/$friendId',
          queryParameters: {'child_id': childId},
        ),
      );

      _logger.log('Friend removed: $friendId for child: $childId');
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to remove friend: $friendId', error: e);
      throw ApiException(
        'Failed to remove friend: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// Google Play購読の購入トークンをバックエンドで検証する
  Future<Map<String, dynamic>> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? packageName,
  }) async {
    try {
      _validateParam(productId, 'productId');
      _validateParam(purchaseToken, 'purchaseToken');

      final response = await _retryRequest(
        () => _dio.post(
          '/purchases/verify/google',
          data: {
            'productId': productId,
            'purchaseToken': purchaseToken,
            if (packageName != null) 'packageName': packageName,
          },
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for Google Play purchase verification');
      }

      _logger.log('Google Play purchase verified for product: $productId');
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to verify Google Play purchase: $productId', error: e);
      throw ApiException(
        e.response?.data is Map && (e.response?.data as Map)['detail'] != null
            ? (e.response!.data as Map)['detail'].toString()
            : 'Failed to verify Google Play purchase: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// App Storeのトランザクションをバックエンドで検証する
  Future<Map<String, dynamic>> verifyApplePurchase({
    required String productId,
    required String transactionId,
  }) async {
    try {
      _validateParam(productId, 'productId');
      _validateParam(transactionId, 'transactionId');

      final response = await _retryRequest(
        () => _dio.post(
          '/purchases/verify/apple',
          data: {
            'productId': productId,
            'transactionId': transactionId,
          },
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for Apple purchase verification');
      }

      _logger.log('Apple purchase verified for product: $productId');
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to verify Apple purchase: $productId', error: e);
      throw ApiException(
        e.response?.data is Map && (e.response?.data as Map)['detail'] != null
            ? (e.response!.data as Map)['detail'].toString()
            : 'Failed to verify Apple purchase: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 現在のプレミアム購読状態を取得する
  Future<Map<String, dynamic>> getPurchaseStatus() async {
    try {
      final response = await _retryRequest(
        () => _dio.get('/purchases/status'),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for purchase status');
      }

      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch purchase status', error: e);
      throw ApiException(
        'Failed to fetch purchase status: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// Firebase IDトークンをバックエンドJWTに交換
  Future<Map<String, dynamic>> loginWithFirebase(String idToken) async {
    try {
      _validateParam(idToken, 'idToken');

      final response = await _retryRequest(
        () => _dio.post(
          '/auth/login-firebase',
          data: {'firebase_id_token': idToken},
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for Firebase login');
      }

      _logger.log('Firebase login successful');
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Firebase login failed', error: e);
      throw ApiException(
        'Firebase login failed: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 認証トークンを設定
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _logger.log('Auth token set');
  }

  /// 子どもプロフィール一覧を取得
  Future<List<ChildProfile>> fetchChildrenProfiles() async {
    try {
      final response = await _retryRequest(
        () => _dio.get('/children/profiles'),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for children profiles');
      }

      final List<dynamic> data = response.data['children'] ?? [];
      if (data is! List) {
        throw ApiException('Expected children to be a list');
      }

      _logger.log('Children profiles fetched: ${data.length} profiles');
      return data.map((item) => ChildProfile.fromApiJson(item as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to fetch children profiles', error: e);
      throw ApiException(
        'Failed to fetch children profiles: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Stub methods for features in development - TODO: Implement these endpoints
  // ════════════════════════════════════════════════════════════════════════════

  Future<ChildProfile> fetchChildProfile(String childId) async {
    throw UnimplementedError('fetchChildProfile: Endpoint not yet implemented');
  }

  Future<ChildProfile> createChild({
    required String name,
    required int grade,
    required String avatarEmoji,
  }) async {
    throw UnimplementedError('createChild: Endpoint not yet implemented');
  }

  Future<void> updateChild(String childId, Map<String, dynamic> updates) async {
    throw UnimplementedError('updateChild: Endpoint not yet implemented');
  }

  Future<void> deleteChild(String childId) async {
    throw UnimplementedError('deleteChild: Endpoint not yet implemented');
  }

  Future<Map<String, dynamic>> completeQuizSession({
    required String sessionId,
    required String chosenChoiceId,
    required int timeSpentSeconds,
    String? reflectionText,
  }) async {
    throw UnimplementedError('completeQuizSession: Endpoint not yet implemented');
  }

  Future<List<Progress>> fetchProgress(String childId) async {
    throw UnimplementedError('fetchProgress: Endpoint not yet implemented');
  }

  Future<Map<String, dynamic>> startQuizSession({
    required String childId,
    required String storyId,
  }) async {
    throw UnimplementedError('startQuizSession: Endpoint not yet implemented');
  }

  Future<List<Map<String, dynamic>>> fetchStories({
    String? theme,
    int? gradeLevel,
  }) async {
    throw UnimplementedError('fetchStories: Endpoint not yet implemented');
  }

  Future<Map<String, dynamic>> fetchWeeklyTheme() async {
    throw UnimplementedError('fetchWeeklyTheme: Endpoint not yet implemented');
  }

  Future<Map<String, dynamic>> fetchStoryDetail(String storyId) async {
    throw UnimplementedError('fetchStoryDetail: Endpoint not yet implemented');
  }

  Future<MonthlyReport?> fetchMonthlyReport({
    required String childId,
    required int year,
    required int month,
  }) async {
    try {
      _validateParam(childId, 'childId');

      final response = await _retryRequest(
        () => _dio.get('/reports/$childId/$year/$month'),
      );

      // No content - report not yet generated
      if (response.statusCode == 204) {
        _logger.log('No report found for $childId: $year-$month');
        return null;
      }

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for monthly report');
      }

      _logger.log('Monthly report fetched for $childId: $year-$month');
      return MonthlyReport.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.log('Report not found for $childId: $year-$month');
        return null;
      }
      _logger.logError('Failed to fetch monthly report for $childId', error: e);
      throw ApiException(
        'Failed to fetch monthly report: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<MonthlyReport> generateMonthlyReport({
    required String childId,
    required int year,
    required int month,
  }) async {
    try {
      _validateParam(childId, 'childId');

      final response = await _retryRequest(
        () => _dio.post(
          '/reports/$childId/$year/$month/generate',
          data: {
            'year': year,
            'month': month,
          },
        ),
      );

      if (!_isValidResponse(response.data)) {
        throw ApiException('Invalid response structure for generated report');
      }

      _logger.log('Monthly report generated for $childId: $year-$month');
      return MonthlyReport.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      _logger.logError('Failed to generate monthly report for $childId', error: e);
      throw ApiException(
        'Failed to generate monthly report: ${e.message}',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<void> clearAuthToken() async {
    throw UnimplementedError('clearAuthToken: Endpoint not yet implemented');
  }

  Future<void> updateUser({required String fcmToken}) async {
    throw UnimplementedError('updateUser: Endpoint not yet implemented');
  }
}
