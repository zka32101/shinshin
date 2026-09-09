// ──────────────────────────────────────────────────────────────────────────────
// FeedbackReport — 「バグ報告・ご意見」フォームで送信する1件分のデータ
// ──────────────────────────────────────────────────────────────────────────────
//
// shared_core 側の feedback_model.dart / feedback_provider.dart と同じ設計思想
// （種別・タイトル・詳細・端末情報を1件のレポートとしてFirestoreに保存する）を、
// このアプリのコードスタイル（cloud_firestore への直接依存、lesson.dart と同様の
// シンプルなクラス定義）に合わせてローカル実装したもの。

/// 報告の種別。
enum FeedbackType {
  bug, // 不具合報告
  feature, // 改善要望
  other, // その他
}

extension FeedbackTypeLabel on FeedbackType {
  String get label => switch (this) {
        FeedbackType.bug => '不具合報告',
        FeedbackType.feature => '改善要望',
        FeedbackType.other => 'その他',
      };
}

/// 1件のバグ報告・改善要望。
class FeedbackReport {
  final String id;
  final FeedbackType type;
  final String title;
  final String description;
  final String appVersion;
  final String platform; // 'iOS' / 'Android' / 'Web' 等
  final DateTime createdAt;
  final String? userId; // 匿名認証のUID
  final String status; // 'open' / 'reviewing' / 'resolved' など。初期値'open'

  const FeedbackReport({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
    required this.userId,
    this.status = 'open',
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'description': description,
        'appVersion': appVersion,
        'platform': platform,
        'createdAt': createdAt.toIso8601String(),
        'userId': userId,
        'status': status,
      };

  factory FeedbackReport.fromJson(String id, Map<String, dynamic> json) => FeedbackReport(
        id: id,
        type: FeedbackType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => FeedbackType.other,
        ),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        appVersion: json['appVersion'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        userId: json['userId'] as String?,
        status: json['status'] as String? ?? 'open',
      );
}
