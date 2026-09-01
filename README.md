# 小学コレ！道徳 ～かっこいい大人になるために～

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3.0-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)
[![COPPA](https://img.shields.io/badge/COPPA-Compliant-green)](https://coppa.gov)
[![iOS](https://img.shields.io/badge/iOS-12.0+-black)](https://www.apple.com/ios/)
[![Android](https://img.shields.io/badge/Android-5.0+-green)](https://www.android.com)

小学3-4年生が、日常のジレンマを選択肢型ストーリーで体験しながら、親向けの月次成長レポートで判断力の成長を見守るサブスク型道徳学習アプリです。

## 🌟 特徴

- 📖 **ジレンマ型ストーリー**: 正解のない日常の判断を通じて、子どもが自分で考える力を育成
- 👨‍👧 **親向け月次レポート**: 子どもの道徳的判断パターンを可視化し、成長を見守る（業界初）
- 🎯 **4つのテーマ特化**: 友人関係・家族・自分探し・社会に絞り、ニーズ直撃
- 👤 **偉人 + 同年代キャラ**: 実在の人物と架空キャラで、子どもの実行可能性を高める
- 🔒 **COPPA準拠**: 13歳未満の子どもの個人情報を厳格に保護
- 🎤 **音声ナレーション**: テキスト読み上げ機能でリーディング支援
- 📊 **データドリブン成長**: 親が子どもの道徳的発展をデータで見守れる

## 🚀 クイックスタート

### 前提条件
- Flutter 3.24.0 以上
- Dart 3.3.0 以上
- iOS 12.0+ または Android 5.0+ (デバイス)
- Xcode 14+ (iOS 開発の場合)
- Android Studio (Android 開発の場合)

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/zkaz83/shinshin.git
cd shinshin

# 依存関係をインストール
flutter pub get

# コード生成
flutter pub run build_runner build --delete-conflicting-outputs

# 環境設定
cp .env.example .env.development

# 開発実行
flutter run
```

### Firebase セットアップ

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成
2. `lib/config/firebase_config.dart` に認証情報を設定
3. `google-services.json` (Android) と `GoogleService-Info.plist` (iOS) を配置
4. Firestore と Storage を有効化

詳細は [docs/firebase-setup.md](docs/firebase-setup.md) をご参照ください。

## 📁 ディレクトリ構成

```
shinshin/
├── lib/                          # Dart ソースコード
│   ├── config/                   # Firebase・API 設定
│   ├── models/                   # データモデル
│   ├── providers/                # Riverpod プロバイダー
│   ├── screens/                  # UI スクリーン
│   │   ├── auth/                 # ログイン・登録・COPPA
│   │   ├── home/                 # ホーム画面
│   │   ├── story/                # ストーリー学習
│   │   ├── library/              # ライブラリ
│   │   ├── report/               # 親向けレポート
│   │   └── settings/             # 設定
│   ├── services/                 # API・Firebase サービス
│   ├── widgets/                  # 再利用可能なウィジェット
│   ├── utils/                    # ユーティリティ関数
│   └── main.dart                 # エントリーポイント
├── backend/                      # Python FastAPI バックエンド
│   ├── app/                      # アプリケーション
│   ├── tests/                    # テスト
│   └── requirements.txt          # Python 依存関係
├── firebase/                     # Firebase 設定
│   ├── firestore.rules           # Firestore セキュリティルール
│   └── storage.rules             # Storage セキュリティルール
├── ios/                          # iOS プロジェクト
├── android/                      # Android プロジェクト
├── test/                         # Flutter テスト
├── docs/                         # ドキュメント
├── .github/workflows/            # GitHub Actions
├── pubspec.yaml                  # Flutter 依存関係
├── CLAUDE.md                     # 開発ガイド
└── README.md                     # このファイル
```

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│ フロントエンド: Flutter + Riverpod                       │
│ ├─ UI Layer (screens/)                                  │
│ ├─ State Management (providers/)                        │
│ ├─ Business Logic (services/)                           │
│ └─ Data Layer (models/, local_db/)                      │
└──────────────────────┬──────────────────────────────────┘
                       │ Firebase API
┌──────────────────────┴──────────────────────────────────┐
│ クラウドバックエンド: Firebase                           │
│ ├─ Authentication (Firebase Auth)                       │
│ ├─ Database (Firestore)                                │
│ ├─ Storage (Firebase Storage)                          │
│ ├─ Analytics (Firebase Analytics)                      │
│ └─ Messaging (Firebase Cloud Messaging)                │
└──────────────────────┬──────────────────────────────────┘
                       │ REST API
┌──────────────────────┴──────────────────────────────────┐
│ バックエンド: Python FastAPI                            │
│ ├─ Analytics Engine                                     │
│ ├─ Report Generation                                    │
│ └─ Data Processing                                      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────┐
│ データベース: PostgreSQL + Firebase Firestore           │
│ ├─ User Data (Firestore)                               │
│ ├─ Analytics (PostgreSQL)                              │
│ └─ Media (Firebase Storage)                            │
└─────────────────────────────────────────────────────────┘
```

## 🔐 セキュリティ & COPPA準拠

このアプリは COPPA (Children's Online Privacy Protection Act) に完全準拠しています。

### 重要な実装
- ✅ **生年月日未保存**: 学年情報のみを保存（個人識別不可）
- ✅ **親の同意**: 13歳未満のユーザーには必須
- ✅ **Firestore セキュリティルール**: ユーザーデータの厳格な保護
- ✅ **Storage セキュリティルール**: メディアファイルのアクセス制御
- ✅ **継続的なセキュリティスキャン**: 脆弱性自動検査

詳細は [docs/security.md](docs/security.md) をご参照ください。

## 🧪 テスト

### ユニットテスト

```bash
flutter test
```

### テストカバレッジ

```bash
flutter test --coverage
open coverage/index.html
```

### 統合テスト

```bash
flutter test integration_test/
```

### セキュリティスキャン

```bash
flutter analyze              # 静的解析
dart run lints:main lib    # Lint チェック
```

## 📊 開発進捗

- ✅ Phase 1: ビルド・署名インフラ
- ✅ Phase 2: セキュリティ・COPPA対応
- 🔄 Phase 3: テスト・品質保証拡充
- 📋 Phase 4: ストア申請メタデータ
- 🚀 Phase 5: リリース自動化

詳細は [CHANGELOG.md](CHANGELOG.md) をご参照ください。

## 📚 ドキュメント

| ドキュメント | 説明 |
|-----------|------|
| [CLAUDE.md](CLAUDE.md) | 開発ガイド・セットアップ |
| [docs/firebase-setup.md](docs/firebase-setup.md) | Firebase 設定ガイド |
| [docs/github-secrets-setup.md](docs/github-secrets-setup.md) | GitHub Secrets 設定 |
| [docs/ios-signing-setup.md](docs/ios-signing-setup.md) | iOS 署名設定 |
| [docs/security.md](docs/security.md) | セキュリティ情報 |
| [CHANGELOG.md](CHANGELOG.md) | 変更ログ・ロードマップ |

## 🤝 貢献

このプロジェクトはプライベートリポジトリです。
貢献希望の場合は、プロジェクト管理者に連絡してください。

## 📞 サポート

- 🐛 [バグ報告](https://github.com/zkaz83/shinshin/issues)
- 💡 [機能リクエスト](https://github.com/zkaz83/shinshin/discussions)
- 🔒 [セキュリティ報告](mailto:security@shougaku-kore.jp)

## 📄 ライセンス

Proprietary - 小学コレ（Petit Works Inc.）

```
(C) 2026 Petitworks Inc. All rights reserved.
```

## 🙏 謝辞

- Flutter チーム
- Firebase チーム
- すべてのテスター・コントリビューター

---

**公式サイト**: https://shougaku-kore.jp  
**最終更新**: 2026-09-01  
**バージョン**: 1.0.0
