import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/models/cloud_functions_model.dart';

class CloudFunctionsService {
  static final CloudFunctionsService _instance =
      CloudFunctionsService._internal();
  final functions = FirebaseFunctions.instance;

  CloudFunctionsService._internal();

  factory CloudFunctionsService() {
    return _instance;
  }

  // 週次レポート自動生成を実行
  Future<Map<String, dynamic>> triggerWeeklyReportGeneration() async {
    try {
      final callable = functions.httpsCallable(
        'generateWeeklyReports',
        options: HttpsCallableOptions(timeout: Duration(minutes: 5)),
      );

      final result = await callable.call({
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Weekly report generation triggered: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error triggering weekly report generation: $e');
      rethrow;
    }
  }

  // 月次レポート自動生成を実行
  Future<Map<String, dynamic>> triggerMonthlyReportGeneration() async {
    try {
      final callable = functions.httpsCallable(
        'generateMonthlyReports',
        options: HttpsCallableOptions(timeout: Duration(minutes: 5)),
      );

      final result = await callable.call({
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Monthly report generation triggered: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error triggering monthly report generation: $e');
      rethrow;
    }
  }

  // ユーザーセグメンテーション更新を実行
  Future<Map<String, dynamic>> updateUserSegmentation() async {
    try {
      final callable = functions.httpsCallable(
        'updateUserSegmentation',
        options: HttpsCallableOptions(timeout: Duration(minutes: 10)),
      );

      final result = await callable.call({
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('User segmentation update triggered: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating user segmentation: $e');
      rethrow;
    }
  }

  // コホート分析更新を実行
  Future<Map<String, dynamic>> updateCohortAnalysis() async {
    try {
      final callable = functions.httpsCallable(
        'updateCohortAnalytics',
        options: HttpsCallableOptions(timeout: Duration(minutes: 10)),
      );

      final result = await callable.call({
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Cohort analysis update triggered: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating cohort analysis: $e');
      rethrow;
    }
  }

  // チャーン予測を実行
  Future<Map<String, dynamic>> predictChurnRisk() async {
    try {
      final callable = functions.httpsCallable(
        'predictChurnRisk',
        options: HttpsCallableOptions(timeout: Duration(minutes: 10)),
      );

      final result = await callable.call({
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Churn prediction triggered: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error predicting churn risk: $e');
      rethrow;
    }
  }

  // 特定のユーザーのセグメンテーション更新
  Future<Map<String, dynamic>> updateUserSegmentationForUser(
    String userId,
  ) async {
    try {
      final callable = functions.httpsCallable(
        'updateUserSegmentationForUser',
        options: HttpsCallableOptions(timeout: Duration(seconds: 30)),
      );

      final result = await callable.call({
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint(
          'User segmentation updated for $userId: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating user segmentation for $userId: $e');
      rethrow;
    }
  }

  // 特定のユーザーのチャーン予測
  Future<Map<String, dynamic>> predictChurnRiskForUser(String userId) async {
    try {
      final callable = functions.httpsCallable(
        'predictChurnRiskForUser',
        options: HttpsCallableOptions(timeout: Duration(seconds: 30)),
      );

      final result = await callable.call({
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Churn prediction completed for $userId: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error predicting churn risk for $userId: $e');
      rethrow;
    }
  }

  // リアルタイム通知を送信
  Future<Map<String, dynamic>> sendNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final callable = functions.httpsCallable(
        'sendNotification',
        options: HttpsCallableOptions(timeout: Duration(seconds: 15)),
      );

      final result = await callable.call({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
      });

      debugPrint('Notification sent to $userId: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error sending notification to $userId: $e');
      rethrow;
    }
  }

  // 人口統計を更新
  Future<Map<String, dynamic>> updatePopulationStats() async {
    try {
      final callable = functions.httpsCallable(
        'updatePopulationStats',
        options: HttpsCallableOptions(timeout: Duration(minutes: 5)),
      );

      final result = await callable.call({
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Population stats updated: ${result.data}');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating population stats: $e');
      rethrow;
    }
  }
}
