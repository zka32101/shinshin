import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feedback_report.dart';

/// このアプリのバージョン。pubspec.yaml の version と揃える。
const String _kAppVersion = '1.0.0';

/// 送信の状態。
enum FeedbackSubmitStatus { idle, submitting, success, error }

class FeedbackSubmitState {
  final FeedbackSubmitStatus status;
  final String? errorMessage;

  const FeedbackSubmitState({required this.status, this.errorMessage});

  static const idle = FeedbackSubmitState(status: FeedbackSubmitStatus.idle);

  FeedbackSubmitState copyWith({
    FeedbackSubmitStatus? status,
    String? errorMessage,
  }) =>
      FeedbackSubmitState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

/// 「バグ報告・ご意見」フォームの送信状態を管理する Notifier。
/// Firestore の `feedback` コレクションへ直接書き込む
/// （FirestoreService とは独立して、firebase_service.dart と同じく
/// FirebaseFirestore.instance / FirebaseAuth.instance を直接利用する）。
class FeedbackNotifier extends StateNotifier<FeedbackSubmitState> {
  FeedbackNotifier() : super(FeedbackSubmitState.idle);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _detectPlatform() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isIOS) return 'iOS';
      if (Platform.isAndroid) return 'Android';
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  /// バグ報告・改善要望を送信する。
  Future<void> submitFeedback({
    required FeedbackType type,
    required String title,
    required String description,
  }) async {
    state = state.copyWith(status: FeedbackSubmitStatus.submitting, errorMessage: null);

    final report = FeedbackReport(
      id: '',
      type: type,
      title: title,
      description: description,
      appVersion: _kAppVersion,
      platform: _detectPlatform(),
      createdAt: DateTime.now(),
      userId: FirebaseAuth.instance.currentUser?.uid,
    );

    try {
      await _db.collection('feedback').add({
        ...report.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = state.copyWith(status: FeedbackSubmitStatus.success);
    } catch (e, st) {
      debugPrint('[FeedbackNotifier.submitFeedback] error: $e\n$st');
      state = state.copyWith(status: FeedbackSubmitStatus.error, errorMessage: e.toString());
    }
  }

  void reset() {
    state = FeedbackSubmitState.idle;
  }
}

final feedbackProvider =
    StateNotifierProvider<FeedbackNotifier, FeedbackSubmitState>((ref) {
  return FeedbackNotifier();
});
