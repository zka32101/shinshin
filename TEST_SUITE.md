# テストスイート — Phase 5.4 実装

## テストの目的

小学コレ！道徳アプリの品質保証と信頼性確保を目的に、複数レベルのテストを実施します：

1. **ユニットテスト** - 個別のコンポーネント機能
2. **ウィジェットテスト** - UI コンポーネント動作
3. **統合テスト** - フロー全体の動作
4. **パフォーマンステスト** - 起動時間と応答性

## テストカバレッジ構成

### 📦 ユニットテスト

#### プロバイダーテスト
- ✅ `test/providers/badge_provider_test.dart` (新規)
- ✅ `test/providers/cache_config_provider_test.dart` (新規)
- ✅ `test/providers/report_provider_test.dart` (既存)
- ✅ `test/providers/progress_provider_test.dart` (既存)
- ✅ `test/providers/story_provider_test.dart` (既存)
- ✅ `test/providers/audio_provider_test.dart` (既存)
- ✅ `test/providers/locale_provider_test.dart` (既存)
- ✅ `test/providers/notification_provider_test.dart` (既存)
- ✅ `test/providers/offline_sync_provider_test.dart` (既存)
- ✅ `test/providers/quiz_completion_provider_test.dart` (既存)

#### ユーティリティテスト
- ✅ `test/utils/performance_utils_test.dart` (新規)
- ✅ `test/utils/provider_select_optimization_test.dart` (既存)

#### モデルテスト
- ✅ `test/models/badge_test.dart` (既存)
- ✅ `test/models/story_test.dart` (既存)
- ✅ `test/models/report_test.dart` (既存)
- ✅ `test/models/progress_test.dart` (既存)
- ✅ `test/models/user_test.dart` (既存)
- ✅ `test/models/child_profile_test.dart` (既存)
- ✅ `test/models/question_test.dart` (既存)
- ✅ `test/models/quiz_session_test.dart` (既存)
- ✅ `test/models/avatar_test.dart` (既存)

#### サービステスト
- ✅ `test/services/api_service_test.dart` (既存)
- ✅ `test/services/hive_service_test.dart` (既存)
- ✅ `test/services/avatar_service_test.dart` (既存)

### 🎨 ウィジェットテスト

#### スクリーンテスト
- ✅ `test/screens/home_screen_test.dart` (既存)
- ✅ `test/screens/library_screen_test.dart` (既存)
- ✅ `test/screens/report_screen_test.dart` (既存＆Phase 5.4拡張)
- ✅ `test/screens/splash_screen_test.dart` (既存)
- ✅ `test/screens/settings_screen_test.dart` (既存)
- ✅ `test/screens/story_learning_screen_test.dart` (既存)
- ✅ `test/screens/story_result_screen_test.dart` (既存)
- ✅ `test/screens/growth_screen_test.dart` (既存)
- ✅ `test/screens/help_screen_test.dart` (既存)
- ✅ `test/screens/privacy_policy_screen_test.dart` (既存)
- ✅ `test/screens/badge/badge_showcase_screen_test.dart` (新規 Phase 5.4)

#### 認証スクリーンテスト
- ✅ `test/screens/auth/login_screen_test.dart` (既存)
- ✅ `test/screens/auth/email_login_screen_test.dart` (既存)
- ✅ `test/screens/auth/email_register_screen_test.dart` (既存)
- ✅ `test/screens/auth/child_registration_screen_test.dart` (既存)

#### プロフィール関連テスト
- ✅ `test/screens/profile/profile_management_screen_test.dart` (既存)
- ✅ `test/screens/profile/profile_edit_screen_test.dart` (既存)

#### ウィジェットテスト
- ✅ `test/widgets/animated_option_card_test.dart` (既存)
- ✅ `test/widgets/animated_progress_bar_test.dart` (既存)
- ✅ `test/widgets/badge_card_test.dart` (新規 Phase 5.4)

### 🔗 統合テスト

- ✅ `test/integration_tests/app_flow_test.dart` (既存)
  - ログイン → 子ども登録 → ホーム画面
- ✅ `test/integration_tests/firebase_integration_test.dart` (既存)
  - Firebase 認証と Firestore 連携
- ✅ `test/integration_tests/badge_report_flow_test.dart` (新規 Phase 5.4)
  - バッジと月次レポート統合フロー
  - ストーリー完了とバッジ獲得の連動
  - 月比較でのバッジ進捗表示

### ⚡ パフォーマンステスト

- ✅ `test/performance_test.dart` (更新)
  - アプリ起動時間 < 3秒
  - ストーリー読み込み < 500ms
  - レポート生成 < 1秒
  - バッジ計算 < 100ms
  - API 呼び出し < 2秒
  - スクリーン遷移（60 FPS）

## Phase 5.4 で追加したテスト

### Badge Provider テスト (`badge_provider_test.dart`)
```
✅ earnedBadgesProvider: 空の初期状態
✅ badgeProgressProvider: ゼロ進捗の初期状態
✅ totalEarnedBadgesCountProvider: 初期値 0
✅ totalAvailableBadgesCountProvider: 正確な合計数
✅ badgeCompletionRateProvider: 初期値 0.0
✅ バッジ定義の構造検証
✅ findBadge() 機能
✅ EarnedBadge シリアライゼーション
✅ バッジテーマの検証
```

### Cache Config Provider テスト (`cache_config_provider_test.dart`)
```
✅ デフォルト設定の検証
✅ frequentAccess, periodicallyChanging, rarelyChanging, userSpecific, networkOptimized 設定の検証
✅ プロバイダーの返り値確認
✅ カスタム設定の生成
✅ TTL 値の妥当性チェック
✅ maxInstances の適切性チェック
```

### Performance Utils テスト (`performance_utils_test.dart`)
```
✅ シングルトンパターン検証
✅ startTiming/stopTiming 記録
✅ getAverageTiming/getMaxTiming/getMinTiming 計算
✅ getAllTimings の統計情報
✅ clearAllTimings クリア機能
✅ 最大測定値数制限（100）
✅ PerformanceTracker クラス
✅ String 拡張メソッド
✅ 複数同時計測
✅ 統計計算の正確性
```

### パフォーマンスベンチマーク (`performance_test.dart` 更新)
```
✅ アプリ起動 < 3秒
✅ ストーリーリスト読み込み < 500ms
✅ レポート生成 < 1秒
✅ バッジ計算 < 100ms
✅ API 呼び出し < 2秒
✅ スクリーン遷移スムーズ性（60 FPS）
✅ パフォーマンス測定メカニズム
```

### ウィジェットテスト (`Phase 5.4 追加)

#### バッジショーケーススクリーンテスト (`badge_showcase_screen_test.dart`)
```
✅ AppBar タイトル表示
✅ ローディング表示
✅ 全体完了率表示
✅ バッジグリッド表示
✅ 進捗バー表示
✅ 獲得/未獲得の視覚的区別
✅ バッジ絵文字表示
✅ バッジ名前表示
✅ 獲得日表示
✅ スクロール対応（20テスト）
```

#### バッジカードウィジェットテスト (`badge_card_test.dart`)
```
✅ 絵文字表示
✅ 名前表示
✅ 説明表示
✅ 進捗バー（未獲得時）
✅ 獲得日表示（獲得時）
✅ パーセンテージ計算検証
✅ テーマ対応
✅ レスポンシブレイアウト（15テスト）
```

#### レポートスクリーン拡張テスト (`report_screen_test.dart` 拡張)
```
✅ バッジセクションヘッダー
✅ 徳目スコアトレンド
✅ 進捗バーの色分け
✅ 月比較レーダーチャート
✅ AI コメント展開/折りたたみ
✅ スクロール対応（15テスト追加）
```

#### 統合テスト (`badge_report_flow_test.dart`)
```
✅ レポート表示＋バッジ情報
✅ バッジショーケースの獲得表示
✅ 徳目スコア更新
✅ ストーリー完了とバッジ連動
✅ 月比較でのバッジ変化
✅ 完了率の更新
✅ 絵文字の表示確認
✅ スクロール時の状態保持（10テスト）
```

## テスト実行方法

### すべてのテストを実行
```bash
flutter test
```

### 特定のテストファイルを実行
```bash
flutter test test/providers/badge_provider_test.dart
flutter test test/providers/cache_config_provider_test.dart
flutter test test/utils/performance_utils_test.dart
flutter test test/performance_test.dart
```

### カバレッジを含めて実行
```bash
flutter test --coverage
```

### ウィジェットテストのみ実行
```bash
flutter test test/screens/
flutter test test/widgets/
```

### パフォーマンステストのみ実行
```bash
flutter test test/performance_test.dart
```

## テスト品質メトリクス

### カバレッジ目標
- **プロバイダー**: 80%+
- **モデル**: 90%+
- **ユーティリティ**: 85%+
- **ウィジェット**: 70%+
- **全体**: 75%+

### テスト種別の配分
- ユニットテスト: 60%
- ウィジェットテスト: 25%
- 統合テスト: 10%
- パフォーマンステスト: 5%

## 継続的インテグレーション

### CI/CD パイプラインでの実行
1. ユニットテスト実行
2. ウィジェットテスト実行
3. カバレッジ計測
4. パフォーマンスベンチマーク実行
5. レポート生成

### 失敗時の対応
- テスト失敗時は PR マージを防止
- カバレッジ低下時は警告
- パフォーマンス低下時は調査要求

## テスト保守指針

### 新機能追加時
1. ユニットテストを先に作成
2. 実装後にウィジェットテスト追加
3. 必要に応じて統合テスト追加
4. パフォーマンス影響を測定

### テスト修正時
- テスト失敗の根本原因を特定
- 実装の問題か、テストの問題か判断
- テスト結果を明記してコミット

### 既存テストの改善
- ブランチカバレッジの拡大
- エッジケースのテスト追加
- テストパフォーマンスの最適化

## よくあるテスト失敗と対応

| 症状 | 原因 | 対応 |
|------|------|------|
| Firebase 未初期化エラー | テストが Firebase を必要としている | Mock Firebase を使用 |
| Riverpod プロバイダーエラー | ProviderContainer の設定不足 | setUp で ProviderContainer 初期化 |
| ウィジェットレンダリング失敗 | Material/Cupertino テーマなし | MaterialApp でラップ |
| タイムアウトエラー | 非同期処理が長すぎる | Future.delayed を短縮 |
| イメージロード失敗 | アセット未登録 | test/pubspec.yaml でアセット登録 |

## 今後の改善予定

- [x] E2E テストの充実（Golden テスト） - Phase 5.5 で実装
- [ ] Dart 静的解析の厳格化
- [ ] カバレッジレポートの可視化
- [ ] パフォーマンス回帰検出の自動化
- [ ] テストドキュメント生成の自動化

## 📸 Golden テスト (Phase 5.5)

### バッジショーケーススクリーンテスト
- ✅ `test/screens/badge/badge_showcase_screen_golden_test.dart` (5テスト)
  - 初期状態、獲得バッジ、混合プログレス、全獲得、スクロール状態

### レポートスクリーンテスト
- ✅ `test/screens/report_screen_golden_test.dart` (8テスト)
  - 未生成、標準、低スコア、高スコア、月比較、保護者メッセージ、スクロール、不均衡

### Golden テスト管理
- ✅ `test/GOLDEN_TEST_GUIDE.md` - Golden テスト実装ガイド
  - 実行方法、保守フロー、ベストプラクティス、CI/CD 統合

**合計**: 13 Golden テスト、視覚的回帰検出カバレッジ
