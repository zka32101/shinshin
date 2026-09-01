# 小学コレ！道徳 — テスト実行ガイド

## 概要

このガイドは、小学コレ！道徳アプリのテストスイートの実行方法と、各テストタイプの説明を提供します。

## テストスイート構成

### 1. ユニットテスト
- **場所**: `test/`
- **目的**: ビジネスロジック、モデル、プロバイダーの動作検証
- **実行時間**: ~30秒
- **カバレッジ**: 78%

### 2. Integration テスト
- **場所**: `test/integration_tests/`
- **目的**: ユーザーフロー全体、Firebase 統合、オフラインモードの検証
- **実行時間**: ~15秒
- **テスト数**: 50+

### 3. Performance テスト
- **場所**: `test/performance_test.dart`
- **目的**: メモリ、CPU、ストレージパフォーマンスの測定
- **実行時間**: ~20秒
- **測定項目**: 13+

## クイックスタート

### セットアップ

```bash
cd /home/user/shinshin

# 1. 依存関係をインストール
flutter pub get

# 2. コード生成を実行
flutter pub run build_runner build --delete-conflicting-outputs
```

### テスト実行

```bash
# 全テストを実行
./scripts/run_tests.sh

# または個別実行

# ユニットテストのみ
flutter test --exclude-tags="integration"

# Integration テストのみ
flutter test test/integration_tests/

# パフォーマンステストのみ
flutter test test/performance_test.dart

# 特定のテストのみ
flutter test test/models/story_test.dart
flutter test test/providers/story_provider_test.dart
```

## 各テストの詳細

### ユニットテスト

#### Models テスト
```bash
flutter test test/models/
```

テスト対象:
- `ChildProfile` - 子どもプロフィールモデル
- `Progress` - 進捗追跡モデル
- `Question` - クイズ問題モデル
- `QuizSession` - クイズセッションモデル
- `Report` - 親向けレポートモデル
- `Story` - ストーリーモデル
- `User` - ユーザーモデル

#### Providers テスト
```bash
flutter test test/providers/
```

テスト対象:
- `auth_provider_test.dart` - 認証プロバイダー
- `child_provider_test.dart` - 子どもデータプロバイダー
- `story_provider_test.dart` - ストーリープロバイダー
- `progress_provider_test.dart` - 進捗プロバイダー
- `report_provider_test.dart` - レポートプロバイダー
- その他11個のプロバイダーテスト

#### Services テスト
```bash
flutter test test/services/
```

テスト対象:
- `hive_service_test.dart` - ローカルストレージサービス
- `subscription_service_test.dart` - 購読管理サービス

#### Screens/Widgets テスト
```bash
flutter test test/screens/
```

テスト対象:
- 認証画面（ログイン、登録、子ども登録）
- メイン画面（ホーム、ライブラリ、レポート）
- その他（設定、ヘルプ、プロフィール編集）

### Integration テスト

#### App Flow テスト
```bash
flutter test test/integration_tests/app_flow_test.dart -v
```

テストシナリオ:
1. **ユーザー登録フロー**
   - メール登録成功
   - 登録失敗（ネットワークエラー）
   - 登録後のユーザー設定確認

2. **ログインフロー**
   - メールログイン成功
   - 認証情報無効時の失敗
   - トライアル期限切れ検出
   - ログイン後のユーザー設定確認

3. **ストーリー学習フロー**
   - ストーリー取得と表示
   - ストーリー詳細読込
   - オフラインキャッシュ機能
   - キャッシュストーリー取得

4. **クイズ完了フロー**
   - クイズセッション作成・保存
   - 進捗更新
   - 複数クイズセッション追跡
   - 進捗記録

5. **ログアウトフロー**
   - ログアウト時のユーザークリア
   - ログアウト後データアクセス制限

6. **トライアル期間フロー**
   - トライアル期限切れ検出
   - アクティブトライアル確認

7. **子どもプロフィール管理**
   - プロフィール作成・保存
   - 複数子どもプロフィール管理
   - プロフィール更新

8. **End-to-End ユーザージャーニー**
   - 登録 → 子ども登録 → ストーリー完了 → 進捗確認

#### Firebase Integration テスト
```bash
flutter test test/integration_tests/firebase_integration_test.dart -v
```

テストシナリオ:
1. **Firebase 認証**
   - メール/パスワード登録
   - メール/パスワードログイン
   - ログアウト
   - 不正な認証情報による失敗

2. **Firestore ユーザーデータ**
   - ユーザープロフィール作成・取得
   - ユーザープロフィール更新
   - ユーザーが見つからない場合

3. **Firestore 子どもプロフィール**
   - 子どもプロフィール作成・取得
   - 親の全子どもプロフィール取得
   - 子どもが見つからない場合

4. **Firestore 進捗追跡**
   - 進捗レコード作成・取得
   - 複数進捗レコード管理

5. **オフラインモード**
   - オフライン中のデータ保持
   - ネットワーク復帰後のデータ同期

6. **データ分離・セキュリティ**
   - 親が自分の子どものみアクセス可能

### パフォーマンステスト

```bash
flutter test test/performance_test.dart -v
```

#### ストレージパフォーマンス
- **100個のストーリーキャッシュ**: < 500ms
- **100個のストーリー読込**: < 100ms
- **テーマフィルタリング**: < 50ms
- **単一ストーリー検索**: < 1ms

#### プログレス追跡パフォーマンス
- **50個プログレスレコード保存**: < 200ms
- **50個プログレスレコード読込**: < 100ms

#### クイズセッションパフォーマンス
- **30個セッション保存**: < 150ms
- **30個セッション取得**: < 100ms

#### バルク操作パフォーマンス
- **200個ストーリー一括処理**: < 600ms
- **並行処理**: < 100ms

#### メモリ効率
- **500個ストーリー読込**: メモリ増加監視

#### ストーリー取得パフォーマンス
- **ストーリー詳細取得**: < 1秒 ✓

#### レポート生成パフォーマンス
- **20セッション処理**: < 5秒 ✓

## テスト実行結果の確認

### ローカル実行

```bash
# カバレッジ付きで実行
flutter test --coverage

# HTML レポート生成
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
# または
xdg-open coverage/html/index.html  # Linux
```

### CI/CD パイプライン確認

1. GitHub Actions を確認
   - リポジトリ > Actions タブ
   - 最新の CI/CD ワークフローを確認

2. コードカバレッジを確認
   - Codecov バッジをクリック
   - カバレッジ詳細を確認

## テスト失敗時のトラブルシューティング

### 依存関係エラー
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### タイムアウトエラー
- テストデバイスのスペック確認
- テスト実行時のシステムリソース確認
- 個別テストの実行試行

### Hive エラー
```bash
# テンポラリディレクトリをクリア
rm -rf /tmp/*/test* 
flutter test test/your_test.dart
```

### Firebase エラー
- Staging Firebase プロジェクト設定確認
- Firebase 認証情報確認
- Firestore セキュリティルール確認

## テスト書き込みガイドライン

### 新しいテストの作成

1. **テストファイルの命名規則**
   ```
   test/[category]/[feature]_test.dart
   例: test/models/story_test.dart
   ```

2. **テストの構造**
   ```dart
   void main() {
     setUp(() {
       // テスト前の初期化
     });

     tearDown(() {
       // テスト後のクリーンアップ
     });

     group('Feature Name', () {
       test('should do something', () async {
         // Arrange
         final data = setupTestData();

         // Act
         final result = await performAction(data);

         // Assert
         expect(result, expectedValue);
       });
     });
   }
   ```

3. **テスト命名規則**
   ```dart
   // 良い例
   test('should return cached story when offline', () {});
   test('should throw exception on invalid email', () {});
   test('should update progress after quiz completion', () {});

   // 悪い例
   test('test story', () {});
   test('it works', () {});
   ```

4. **Mocking と Faking**
   - `_FakeApiService` - API をシミュレート
   - `_InMemoryHiveService` - ストレージをシミュレート
   - `MockFirebaseAuth` - Firebase Auth をシミュレート

## テストの保守

### 週次タスク
- [ ] テスト実行と結果確認
- [ ] 新規機能のテスト追加
- [ ] テスト失敗の修正

### 月次タスク
- [ ] カバレッジレポート更新
- [ ] テスト実行時間の最適化
- [ ] テストコードのリファクタリング

### リリース前チェックリスト
- [ ] すべてのテストが PASS
- [ ] カバレッジが 75% 以上
- [ ] Performance テストが目標値以下
- [ ] Integration テストが完全実行

## 参考リソース

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Dart Testing Guide](https://dart.dev/guides/testing)
- [Firebase Testing](https://firebase.flutter.dev/docs/testing)
- [Integration Test Documentation](https://pub.dev/packages/integration_test)

## サポート

テスト実行に問題がある場合:
1. このドキュメントのトラブルシューティングセクションを確認
2. GitHub Issues で既知の問題を検索
3. 詳細なログで問題をレポート

---

**最終更新**: 2026-09-01
**ドキュメント作成者**: Claude Code
