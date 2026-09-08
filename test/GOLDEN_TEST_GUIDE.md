# Golden テスト実装ガイド — Phase 5.5

## Golden テストとは

Golden テスト（スナップショットテスト）は、ウィジェットをスクリーンショット画像として保存し、将来の変更時にそのスクリーンショットと比較することで、視覚的な回帰を検出するテスト手法です。

### 主な利点

✅ **視覚的回帰検出**
- UIコンポーネントの予期しない変更を即座に検出
- デザイン・カラー・レイアウトの変更を自動検出

✅ **ドキュメンテーション**
- UIの外観を画像として記録
- 開発者間での共通理解の形成

✅ **リファクタリング安全性**
- コード変更後も視覚的に同一であることを確保
- 安心してコードを最適化できる

## 実装されたGolden テスト

### 1. バッジショーケーススクリーンテスト
**ファイル**: `test/screens/badge/badge_showcase_screen_golden_test.dart`

#### テストケース（5種類）
```
✅ badge_showcase_initial_state.png
   - バッジなし、完了率 0% の初期状態

✅ badge_showcase_with_earned_badges.png
   - 3つのバッジ獲得、複数進捗状態

✅ badge_showcase_mixed_progress.png
   - 混合プログレス状態（0%, 25%, 50%, 75%, 100%）

✅ badge_showcase_all_earned.png
   - すべてのバッジ獲得、完了率 100%

✅ badge_showcase_scrolled.png
   - スクロール後の表示状態
```

### 2. レポートスクリーンテスト
**ファイル**: `test/screens/report_screen_golden_test.dart`

#### テストケース（8種類）
```
✅ report_screen_no_report.png
   - レポート未生成状態

✅ report_screen_full_data.png
   - 標準的なレポートデータ（すべて中程度スコア）

✅ report_screen_low_scores.png
   - 低スコア状態（赤色の警告表示）

✅ report_screen_high_scores.png
   - 高スコア状態（緑色の成功表示）

✅ report_screen_with_comparison.png
   - 先月比較表示付き（月別の成長トレンド）

✅ report_screen_with_parent_message.png
   - 保護者メッセージ付き

✅ report_screen_scrolled_badges.png
   - スクロール後のバッジセクション

✅ report_screen_unbalanced_scores.png
   - 徳目別スコアのバランス不均衡
```

## Golden テスト実行方法

### 初回実行（Golden ファイル生成）

```bash
# すべての Golden テストを実行（ファイル生成）
flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart
flutter test --update-goldens test/screens/report_screen_golden_test.dart

# または特定のテストのみ
flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart -k "initial_state"
```

### 通常実行（回帰検出）

```bash
# Golden テストを実行（スナップショット比較）
flutter test test/screens/badge/badge_showcase_screen_golden_test.dart
flutter test test/screens/report_screen_golden_test.dart

# すべてのテストを実行
flutter test
```

### Golden ファイル表示確認

```bash
# 生成されたファイル確認
ls test/screens/badge/goldens/
ls test/screens/report_screen/goldens/

# または
find test -name "goldens" -type d
```

## Golden テストの保守

### スナップショット更新（意図的な変更時）

UI デザインやレイアウトを意図的に変更した場合、新しいスナップショットで更新します：

```bash
# 変更内容を確認した後、Golden を更新
flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart

# Git で変更を確認
git diff test/screens/badge/goldens/
```

### 更新前チェックリスト

変更を確認してから Golden を更新するプロセス：

1. **コード変更を確認**
   ```bash
   git diff lib/screens/badge/
   git diff lib/screens/report/
   ```

2. **通常のテスト実行**
   ```bash
   flutter test test/screens/badge/badge_showcase_screen_test.dart
   flutter test test/screens/report_screen_test.dart
   ```

3. **アプリで手動確認**
   ```bash
   flutter run
   # 実際の画面で視覚的に確認
   ```

4. **Golden ファイル生成**
   ```bash
   flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart
   ```

5. **変更をレビュー**
   ```bash
   git diff test/screens/badge/goldens/
   ```

6. **コミット**
   ```bash
   git add test/screens/badge/goldens/
   git commit -m "Update golden tests for badge showcase changes"
   ```

## Golden ファイル構造

```
test/
├── screens/
│   ├── badge/
│   │   ├── badge_showcase_screen_golden_test.dart
│   │   └── goldens/
│   │       ├── badge_showcase_initial_state.png
│   │       ├── badge_showcase_with_earned_badges.png
│   │       ├── badge_showcase_mixed_progress.png
│   │       ├── badge_showcase_all_earned.png
│   │       └── badge_showcase_scrolled.png
│   │
│   ├── report_screen_golden_test.dart
│   └── goldens/
│       ├── report_screen_no_report.png
│       ├── report_screen_full_data.png
│       ├── report_screen_low_scores.png
│       ├── report_screen_high_scores.png
│       ├── report_screen_with_comparison.png
│       ├── report_screen_with_parent_message.png
│       ├── report_screen_scrolled_badges.png
│       └── report_screen_unbalanced_scores.png
```

## よくある問題と対処法

### 問題1: Golden ファイルが見つからない
```
Error: Unable to find golden file: goldens/badge_showcase_initial_state.png
```

**原因**: 初回実行時にファイルが生成されていない

**対処**:
```bash
flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart
```

### 問題2: Golden テストが失敗する
```
Image differs from golden baseline
```

**原因**: UI が予期せず変更された、またはテスト環境が異なる

**対処**:
1. 変更内容を確認
2. 意図的な変更なら Golden を更新
3. 予期しない変更なら該当コードを修正

```bash
# 変更を確認
flutter test test/screens/badge/badge_showcase_screen_golden_test.dart -v

# 意図的な変更なら更新
flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart
```

### 問題3: 異なる環境で Golden が異なる
**原因**: 異なる画面サイズやフォントで実行

**対処**: テスト内でウィンドウサイズを固定
```dart
await tester.binding.window.physicalSizeTestValue = const Size(540, 960);
addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
```

### 問題4: Golden ファイルのマージコンフリクト
```
CONFLICT (content): Merge conflict in test/screens/badge/goldens/...
```

**対処**:
1. コンフリクト側を確認
2. 正しいバージョンの Golden を実行で生成
3. 両方のテストが通ることを確認

```bash
flutter test --update-goldens test/screens/badge/badge_showcase_screen_golden_test.dart
git add test/screens/badge/goldens/
```

## Golden テスト作成のベストプラクティス

### 1. 固定サイズでテストする
```dart
await tester.binding.window.physicalSizeTestValue = const Size(540, 960);
addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
```

### 2. 完全にレンダリングされるまで待機
```dart
await tester.pumpAndSettle();
```

### 3. テストデータを明確に指定
```dart
final report = _makeReport(
  storiesCompleted: 8,
  kindnessScore: 80.0,
  honestyScore: 75.0,
  // ... 明示的にスコアを指定
);
```

### 4. 複数の状態をカバー
- 初期状態
- 通常データ
- エッジケース（0%, 100%）
- スクロール状態

### 5. テスト名を明確に
```dart
testWidgets(
  'golden: badge showcase with earned badges',
  (tester) async { ... },
);
```

## CI/CD での Golden テスト

### GitHub Actions での実行例
```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter test test/screens/ --update-goldens
    - uses: actions/upload-artifact@v2
      if: failure()
      with:
        name: golden-failures
        path: test/screens/goldens/
```

### 注意点
- CI での Golden テストは手動で確認が必要
- 画像生成環境が異なるため、CI では生成しない方が良い
- ローカルで確認→CI で検証というフロー推奨

## テスト品質の継続的改善

### 1. カバレッジの拡大
```
現在: 13 Golden テスト
目標: 25+ Golden テスト（全主要スクリーン）
```

### 2. 対象スクリーンの追加
- [ ] ホーム画面
- [ ] ライブラリ画面
- [ ] ストーリー学習画面
- [ ] ダッシュボード画面
- [ ] ランキング画面

### 3. 多言語テスト
```dart
// 日本語テスト（現在）
// 英語テスト（今後）
```

### 4. ダークモードテスト
```dart
// ライトモードテスト（現在）
// ダークモードテスト（今後）
```

## Golden テスト実行フロー

```
開発 → テスト実行 → Golden 失敗
  ↓
UI 変更を確認
  ↓
意図的な変更？ → YES → Golden 更新 → コミット
  ↓ NO
バグを修正 → テスト再実行 → 成功 → コミット
```

## パフォーマンス考慮事項

### ファイルサイズ
- 各 Golden 画像: 50-200 KB
- 合計（13テスト）: 1-2 MB
- Git リポジトリへの影響は最小限

### テスト実行時間
- Golden テスト単体: 30-60秒
- 他のテストと並行: 1-2分

### 最適化方法
```bash
# 並列実行でテスト高速化
flutter test --test-randomize-ordering-seed=random

# 特定テストのみ実行
flutter test test/screens/badge/badge_showcase_screen_golden_test.dart
```

---

**次のステップ**: CI/CD パイプラインに Golden テストを統合し、自動的な視覚的回帰検出を実現します。
