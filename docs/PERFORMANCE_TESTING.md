# 小学コレ！道徳 — 性能テストドキュメント

## 概要
このドキュメントは、小学コレ！道徳アプリの性能テスト戦略、測定方法、および目標値を定義しています。

## 性能目標

### アプリ起動時間
- **目標**: 3秒以内
- **測定方法**: Flutterのタイムラインツールで、アプリ起動からホーム画面表示までを測定
- **合格基準**: 本番環境で3回の平均が3秒以下
- **測定対象デバイス**:
  - Android: Google Pixel 4a（中程度の性能）
  - iOS: iPhone 12（中程度の性能）

### ストーリー読込時間
- **目標**: 1秒以内
- **測定方法**: ストーリー選択から表示開始までの時間
- **合格基準**: キャッシュあり・なし両方で1秒以下
- **テスト対象シナリオ**:
  1. ネットワークからの初回読込
  2. キャッシュからの読込
  3. オフラインモード

### レポート生成時間
- **目標**: 5秒以内
- **測定方法**: 月次レポート生成ボタンクリックから完全表示まで
- **合格基準**: 複数ユーザーのレポートも並行して生成可能

### メモリ使用量
- **目標**: 100MB以下（アプリ起動直後）
- **測定方法**: Android Studio / Xcode のメモリプロファイラ
- **警告値**: 150MB以上
- **リーク検出**: Google Mobile Testingのメモリリーク検出ツール

### バッテリー消費測定
- **テスト期間**: 1時間の連続使用
- **基準値**: 通常使用で5-10%の消費
- **警告値**: 15%以上

## テスト実行方法

### 単体性能テスト
```bash
# 性能テストのみ実行
flutter test test/performance_test.dart

# 詳細な出力付きで実行
flutter test test/performance_test.dart -v

# 性能レポート出力付きで実行
flutter test test/performance_test.dart --verbose 2>&1 | grep -A 100 "Performance Benchmark Report"
```

### Integration テスト
```bash
# Integration テスト実行
flutter test test/integration_tests/app_flow_test.dart

# Firebase Integration テスト
flutter test test/integration_tests/firebase_integration_test.dart
```

### 本番ビルドでのプロファイリング
```bash
# Android
flutter run --release --profile
android-studio > Profiler > Memory/CPU/Network tabs

# iOS
flutter run --release
Instruments > Time Profiler / Allocations / System Trace
```

### メモリリーク検出
```bash
# メモリプロファイル開始
flutter run --profile

# または Debug ビルドで明示的にテスト
dart --observe=localhost:8181 test/performance_test.dart
# DevTools で Observatory を開く
```

## 性能測定値の記録

### テスト実行結果の記録フォーマット

```markdown
# 性能テスト結果 - YYYY-MM-DD

## 環境
- Flutter バージョン: 3.19.x
- テストデバイス: Google Pixel 4a
- OS バージョン: Android 12
- テスト実施者: [名前]

## 測定結果

| メトリクス | 目標値 | 実測値 | ステータス | 備考 |
|-----------|--------|--------|-----------|------|
| アプリ起動時間 | < 3s | 2.4s | ✓ PASS | Cold start |
| ストーリー読込（キャッシュ） | < 1s | 0.3s | ✓ PASS | - |
| ストーリー読込（ネットワーク） | < 1s | 0.8s | ✓ PASS | - |
| レポート生成時間 | < 5s | 2.1s | ✓ PASS | 20セッション分 |
| メモリ使用量 | < 100MB | 85MB | ✓ PASS | - |

## 分析とアクション項目
- [分析内容]
- [改善予定事項]
```

## パフォーマンスベンチマーク詳細

### 1. ストレージ性能テスト
```dart
test('write 100 stories to cache', () async {
  // 100個のストーリーをキャッシュに書き込む
  // 目標: < 500ms
});

test('read 100 stories from cache', () async {
  // キャッシュから100個のストーリーを読み込む
  // 目標: < 100ms
});

test('filter 100 stories by theme', () async {
  // テーマでフィルタリング
  // 目標: < 50ms
});
```

### 2. プログレス追跡性能テスト
```dart
test('save 50 progress records', () async {
  // 50個のプログレスレコードを保存
  // 目標: < 200ms
});

test('read 50 progress records', () async {
  // 50個のプログレスレコードを読み込む
  // 目標: < 100ms
});
```

### 3. クイズセッション性能テスト
```dart
test('save 30 quiz sessions', () async {
  // 30個のクイズセッションを保存
  // 目標: < 150ms
});

test('retrieve 30 quiz sessions', () async {
  // 30個のクイズセッションを取得
  // 目標: < 100ms
});
```

### 4. バルク操作性能テスト
```dart
test('bulk cache + read operation', () async {
  // 200個のストーリーを一括処理
  // 目標: < 600ms
});

test('concurrent data operations', () async {
  // 複数の操作を並行実行
  // 目標: < 100ms
});
```

## CI/CD パイプラインでの性能テスト

### GitHub Actions 設定
```yaml
- name: Run performance tests
  run: flutter test test/performance_test.dart --verbose

- name: Compare with baseline
  run: |
    # ベースライン値と比較
    # 10% 以上の悪化を検出して警告
```

## Profiling ツール

### Android 向け
1. **Android Profiler** (Android Studio)
   - Memory: Heap dump取得、メモリリーク検出
   - CPU: Method tracing、Sampled profiling
   - Network: API呼び出しの監視

2. **Systrace**
   ```bash
   flutter systrace
   ```

### iOS 向け
1. **Instruments** (Xcode)
   - System Trace: 全体的なパフォーマンス分析
   - Allocations: メモリ割り当て追跡
   - Core Animation: UI 描画性能

2. **Metal System Trace**

## パフォーマンス最適化ガイドライン

### メモリ最適化
- [ ] 不要なリソース保持を削除
- [ ] 画像を適切にリサイズ
- [ ] WeakReferences の活用
- [ ] キャッシュサイズを制限

### CPU 最適化
- [ ] Expensive な処理の非同期化
- [ ] BuildContext.of のキャッシング
- [ ] const constructor の活用
- [ ] 不要な rebuild の削減

### ネットワーク最適化
- [ ] API レスポンスの圧縮
- [ ] Caching ヘッダーの設定
- [ ] HTTP/2 の活用
- [ ] 画像 CDN の利用

### ストレージ最適化
- [ ] Hive インデックスの活用
- [ ] 不要なキャッシュデータの削除
- [ ] データベーススキーマの最適化

## リグレッション検出

### ベースライン値の設定
- Phase 1 完了後に初期ベースラインを設定
- 毎週の性能テスト結果を記録
- 月次でトレンド分析を実施

### アラート基準
- 平均値が 10% 以上悪化した場合 → 警告
- 平均値が 20% 以上悪化した場合 → リリース阻止
- メモリ使用量が 150MB 以上 → リリース阻止

## ローカル性能テスト実行ガイド

### セットアップ
```bash
# 最新の依存関係取得
flutter pub get

# コード生成
flutter pub run build_runner build --delete-conflicting-outputs

# テストディレクトリの作成
mkdir -p test/performance_results
```

### テスト実行
```bash
# 全性能テスト実行
flutter test test/performance_test.dart --coverage

# 特定のテストのみ実行
flutter test test/performance_test.dart -k "Storage Performance"

# リリース版でテスト（より正確）
flutter test test/performance_test.dart --release
```

### 結果の解釈
- **PASS**: 目標値以下
- **WARNING**: 目標値の 110% 以下
- **FAIL**: 目標値の 110% を超過

## トラブルシューティング

### メモリ使用量が高い場合
1. メモリダンプを取得
2. Allocation スタックの確認
3. イメージキャッシュをクリア
4. 不要な Provider を削除

### 起動時間が長い場合
1. Cold start と Warm start を区別
2. 初期化処理を遅延化
3. アセット読み込みを非同期化
4. コード分割を検討

### ネットワーク遅延がある場合
1. API エンドポイントのレイテンシ計測
2. キャッシュ戦略の見直し
3. Gzip 圧縮の確認
4. CDN の活用を検討

## 参考リンク
- [Flutter パフォーマンス最適化ガイド](https://flutter.dev/docs/perf)
- [Dart パフォーマンス ガイド](https://dart.dev/guides/performance)
- [Firebase パフォーマンス モニタリング](https://firebase.google.com/docs/perf-mod)
