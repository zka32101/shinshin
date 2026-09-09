# 小学コレ！道徳 — Claude Code 開発ガイド

## プロジェクト概要
- **名前**: 小学コレ！道徳 (shinshin)
- **説明**: 小学3-4年生が、日常のジレンマを選択肢型ストーリーで体験しながら、親向けの月次成長レポートで判断力の成長を見守るサブスク型道徳学習アプリ
- **スタック**: Flutter + Riverpod + Firebase + FastAPI
- **ステータス**: ✅ Phase 7 完了（v0.9.0 → v1.0 開発中）

## セットアップ

### 初回セットアップ
```bash
cd /home/user/shinshin
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase 設定
1. Firebase コンソール（https://console.firebase.google.com）でプロジェクト作成
2. `lib/config/firebase_config.dart` に認証情報設定
3. ファイル配置:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### FastAPI バックエンド設定
```bash
# バックエンド（別リポジトリ）の起動
cd ~/shinshin-backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## ディレクトリ構成

```
lib/
├── config/                      # Firebase・API設定・定数
├── models/
│   ├── story_model.dart         # ストーリーデータ
│   ├── child_profile.dart       # 子どもプロフィール
│   ├── growth_analytics.dart    # 成長分析データ
│   └── receipt_validation.dart  # 領収書検証（v1.0 新規）
├── providers/
│   ├── auth_provider.dart       # Firebase 認証
│   ├── story_provider.dart      # ストーリー管理
│   ├── progress_provider.dart   # 進捗管理
│   ├── growth_provider.dart     # 親向け成長レポート
│   └── subscription_provider.dart # サブスク管理（v1.0）
├── screens/
│   ├── auth/                    # ログイン・登録
│   ├── home/                    # ホーム画面
│   ├── story/                   # ストーリー学習
│   ├── library/                 # ライブラリ（履歴）
│   ├── report/                  # 親向けレポート
│   └── settings/                # 設定
├── services/
│   ├── firebase_service.dart    # Firebase API
│   ├── api_service.dart         # FastAPI 連携
│   └── receipt_validator.dart   # 領収書検証（v1.0）
├── widgets/
│   ├── story_widgets.dart
│   ├── chart_widgets.dart
│   └── common_widgets.dart
└── main.dart
```

## 実装フェーズ

### Phase 1: 基盤構築 ✅ 完了
- ✅ Firebase 認証の実装
- ✅ API サービスの実装
- ✅ ローカルDB（Hive）初期化
- ✅ ホーム画面の基本レイアウト

### Phase 2: コンテンツ管理 ✅ 完了
- ✅ ストーリー一覧画面
- ✅ ストーリー学習画面
- ✅ 選択肢の分岐表示
- ✅ ストーリーデータ（20+話）実装

### Phase 3: 学習進捗管理 ✅ 完了
- ✅ 選択履歴の保存
- ✅ バッジシステム（shared_core 統合）
- ✅ 進捗表示・カウント機構

### Phase 4: 親向け機能 ✅ 完了
- ✅ 月次レポート表示
- ✅ レーダーチャート実装（fl_chart）
- ✅ 成長パターン分析
- ✅ FastAPI による AI分析（オプション）

### Phase 5: 最適化・リリース ✅ 完了
- ✅ UI・UX 最適化
- ✅ パフォーマンス改善
- ✅ 単体テスト実装
- ✅ ビルド・申請準備

### Phase 6: サブスクリプション連携 ✅ 完了（v1.0）
- ✅ RevenueCat SDK 統合
- ✅ 月額¥120の購読オプション
- ✅ 購買フロー実装
- ✅ プレミアム機能ゲート

### Phase 7: 領収書検証・セキュリティ ✅ 完了（v1.0.1）
- ✅ Google Play Billing Library 連携
- ✅ App Store Server API 連携
- ✅ 領収書の実サーバー検証実装
- ✅ ダミー検証の削除・本実装対応

## 実装状況（2026-09-09）

### v1.0 リリース（現在）
| 機能 | 状態 | 詳細 |
|---|---|---|
| ストーリー学習 | ✅ | 20+話実装、音声ナレーション対応 |
| 親向けレポート | ✅ | 月次分析・レーダーチャート表示 |
| サブスクリプション | ✅ | RevenueCat 経由・月額¥120 |
| 領収書検証 | ✅ | Google Play/App Store API 対応 |
| バッジシステム | ✅ | 10個バッジ（shared_core 統合） |
| COPPA/プライバシー | ✅ | 子ども情報最小化・親ゲート実装 |

### v1.1 計画中
- リアルタイムアナリティクス（Firebase）
- マルチユーザー親管理画面
- ストーリー数拡張（30+話）

## 命名規則

### Dart ファイル
- **ファイル名**: snake_case (例: `story_learning_screen.dart`)
- **クラス名**: PascalCase (例: `StoryLearningScreen`)
- **関数名**: camelCase (例: `fetchStories()`)
- **定数**: UPPER_SNAKE_CASE (例: `API_BASE_URL`)

### Riverpod プロバイダー
```dart
// FutureProvider
final storyDetailProvider = FutureProvider.autoDispose
    .family<Story, String>((ref, storyId) async { ... });

// StateProvider
final selectedChildProvider = StateProvider<String>((ref) => '');
```

## セキュリティ・課金

### サブスクリプション実装（v1.0）
- **SDK**: RevenueCat（ベンダー中立的な決済管理）
- **商品**: `shinshin_premium_monthly` (¥120/月)
- **領収書検証**: Google Play + App Store Server API
- **実装ファイル**: `lib/services/receipt_validator.dart`

```dart
// 領収書検証の例
final isValid = await receiptValidator.validateReceipt(
  platform: 'android',
  packageName: 'com.example.shinshin',
  productId: 'shinshin_premium_monthly',
  transactionToken: token,
);
```

### API キー管理
```bash
# .env ファイル（ローカルのみ）
FIREBASE_PROJECT_ID=shinshin-xxx
FIREBASE_API_KEY=AIzaXXXX
REVENUE_CAT_API_KEY=appl_xxxx

# 本番環境（CI/CD）
# → GitHub Secrets / Firebase Cloud Functions で管理
```

## 注意点

- **COPPA準拠**: 子どもの個人情報は最小化（名前・学年のみ）
- **オフライン対応**: ダウンロード済みストーリーはオフラインで再生可能
- **アクセシビリティ**: 音声ナレーション機能実装済み
- **パフォーマンス**: アプリ起動 3秒以内、ストーリー読み込み 1秒以内
- **⚠️ セキュリティ**: 領収書検証は本番環境で必須。テスト環境では `isDebugMode` で自動確認スキップ

## デバッグ・テスト

### ホットリロード
```bash
flutter run
# 実行中に 'r' を押すと hot reload
# 'R' を押すと hot restart
```

### コード生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### テスト実行
```bash
flutter test
```

### 領収書検証テスト
```bash
# テスト用トークン（Google Play）
flutter run --dart-define=RECEIPT_TOKEN=sandbox-token

# 本番環境では実トークンを使用
```

## iOS/Android ビルド

### Android
```bash
flutter build appbundle --release  # Google Play用
flutter build apk --release         # 直接配信用
```

### iOS
```bash
flutter build ios --release         # App Store用
```

## 参考資料
- 企画書: `../../shougaku-kore-doutoku-kika-v2.md`
- 設計ドキュメント: `../../shougaku-kore-doutoku-design.md`
- [RevenueCat ドキュメント](https://docs.revenuecat.com)
- [Google Play Billing](https://developer.android.com/google/play/billing)
- [App Store Server API](https://developer.apple.com/app-store/server-api/)

---

**最終更新**: 2026-09-09  
**ステータス**: ✅ v1.0 リリース中 / v1.0.1 セキュリティ完了
