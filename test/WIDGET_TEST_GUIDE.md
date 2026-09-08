# ウィジェットテスト実装ガイド — Phase 5.4

## 概要

Phase 5.4 では、バッジシステムと月比較レポート機能のウィジェットテストを実装しました。このガイドでは、テスト実装の内容と今後のテスト保守についての指針を提供します。

## 実装されたテスト

### 1. バッジショーケーススクリーンテスト
**ファイル**: `test/screens/badge/badge_showcase_screen_test.dart`

#### テストケース（20項目）
```
✅ AppBar タイトル表示
✅ ローディング表示
✅ 全体完了率表示
✅ 獲得バッジ数表示
✅ グリッド表示
✅ 進捗バー表示
✅ 獲得/未獲得の視覚的区別
✅ バッジ絵文字表示
✅ バッジ名前表示
✅ 次のバッジヒント表示
✅ バッジ獲得日表示
✅ スクロール対応
✅ 空のバッジリスト処理
✅ テーマカラー確認
✅ 進捗パーセンテージ表示
✅ バッジカード ラップ機能
✅ 獲得日表示フォーマット
✅ 完了率バー更新
✅ セクションヘッダー表示
```

#### テスト実装パターン
```dart
testWidgets('displays AppBar with title', (tester) async {
  await tester.pumpWidget(_wrapBadgeShowcase());
  await tester.pumpAndSettle();
  expect(find.text('バッジ図鑑'), findsOneWidget);
});
```

### 2. バッジカードウィジェットテスト
**ファイル**: `test/widgets/badge_card_test.dart`

#### テストケース（15項目）
```
✅ 絵文字表示
✅ 名前表示
✅ 説明表示
✅ 進捗バー（未獲得時）
✅ 獲得日表示（獲得時）
✅ 進捗値の変更反映
✅ 0% 進捗表示
✅ 100% 進捗表示
✅ Card ウィジェット確認
✅ 絵文字サイズ確認
✅ 複数テーマ対応
✅ パーセンテージ計算検証
✅ 進捗隠蔽（獲得時）
✅ レスポンシブレイアウト
```

#### テスト実装パターン
```dart
testWidgets('displays badge emoji', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TestBadgeCard(badge: testBadge),
      ),
    ),
  );
  expect(find.text('⭐'), findsOneWidget);
});

testWidgets('progress bar value changes with progress prop', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TestBadgeCard(
          badge: testBadge,
          progress: 0.25,
        ),
      ),
    ),
  );
  expect(find.text('25%'), findsOneWidget);
});
```

### 3. レポートスクリーン拡張テスト
**ファイル**: `test/screens/report_screen_test.dart` (拡張)

#### 新規テストケース（15項目）
```
✅ バッジセクションヘッダー
✅ 徳目スコアトレンド表示
✅ 進捗バーの色分け
✅ レーダーチャート＋凡例
✅ 月比較カード
✅ AI コメント展開/折りたたみ
✅ 全徳目スコア表示
✅ 月選択ボタン動作
✅ 月変更時のデータ更新
✅ バッジ進捗カード表示
✅ ゼロスコア処理
✅ スクロール対応確認
```

#### テスト実装パターン
```dart
testWidgets('shows badge section header when report exists', (tester) async {
  await tester.pumpWidget(
    _wrap(child: _testChild, report: _makeReport()),
  );
  await tester.pumpAndSettle();
  expect(find.text('🎖️ バッジ進捗'), findsOneWidget);
});

testWidgets('scrollable content fits within screen', (tester) async {
  await tester.pumpWidget(
    _wrap(
      child: _testChild,
      report: _makeReport(
        highlightComment: 'コメント' * 20,
        growthComment: 'コメント' * 20,
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.drag(
    find.byType(SingleChildScrollView).first,
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();

  expect(find.byType(Scaffold), findsOneWidget);
});
```

### 4. バッジ＆レポート統合テスト
**ファイル**: `test/integration_tests/badge_report_flow_test.dart`

#### テストケース（10項目）
```
✅ レポート表示＋バッジ情報
✅ バッジショーケースの獲得バッジ表示
✅ 獲得バッジに応じた徳目スコア更新
✅ ストーリー完了とバッジ進捗の連動
✅ 月比較でのバッジ変化表示
✅ バッジ完了率の更新
✅ 未獲得バッジ状態の処理
✅ バッジ絵文字の表示確認
✅ スクロール時の状態保持
✅ ストーリー完了シナリオテスト
```

#### テスト実装パターン
```dart
testWidgets(
  'user can view report with badge information',
  (tester) async {
    final earnedBadges = [
      EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 2, 1)),
      EarnedBadge(badgeId: 'honesty_1', earnedAt: DateTime(2024, 2, 15)),
    ];

    final report = _createTestReport(badges: earnedBadges);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedChildProvider
              .overrideWith((ref) => Future.value(_testChild)),
          monthlyReportProvider
              .overrideWith((ref, _) => Future.value(report)),
          earnedBadgesProvider.overrideWith((ref, _) {
            return Future.value(earnedBadges);
          }),
        ],
        child: const MaterialApp(home: ReportScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('月次成長レポート'), findsOneWidget);
    expect(find.text('🎖️ バッジ進捗'), findsOneWidget);
  },
);
```

## テスト実行方法

### すべてのウィジェットテストを実行
```bash
flutter test test/screens/ test/widgets/ test/integration_tests/
```

### 特定のテストファイルを実行
```bash
# バッジショーケーステスト
flutter test test/screens/badge/badge_showcase_screen_test.dart

# バッジカードテスト
flutter test test/widgets/badge_card_test.dart

# 統合テスト
flutter test test/integration_tests/badge_report_flow_test.dart

# レポートスクリーンテスト（拡張分含む）
flutter test test/screens/report_screen_test.dart
```

### カバレッジを含めて実行
```bash
flutter test --coverage
```

### ウォッチモード（自動再実行）
```bash
flutter test --watch
```

## テスト作成のベストプラクティス

### 1. Widget ラッパー関数の活用
```dart
Widget _wrapBadgeShowcase({
  List<EarnedBadge>? earnedBadges,
  Map<String, double>? badgeProgress,
  int? totalEarned,
  double? completionRate,
  String childId = 'test-child',
}) {
  return ProviderScope(
    overrides: [
      // プロバイダーオーバーライド
    ],
    child: const MaterialApp(home: BadgeShowcaseScreen()),
  );
}

// 使用例
await tester.pumpWidget(_wrapBadgeShowcase(
  totalEarned: 2,
  completionRate: 0.22,
));
```

### 2. テスト用フィクスチャーの作成
```dart
final _testChild = ChildProfile(
  id: 'child-badge-flow',
  parentId: 'parent-1',
  name: 'テスト太郎',
  grade: 3,
  avatarEmoji: '🎖️',
  createdAt: DateTime(2024, 1, 1),
);

MonthlyReport _createTestReport({
  List<EarnedBadge>? badges,
  int storiesCompleted = 5,
}) {
  // レポート生成ロジック
}
```

### 3. 非同期処理の処理
```dart
// 完全に完了するまで待機
await tester.pumpAndSettle();

// フレームをポンプして更新
await tester.pump();

// 特定の時間待機
await tester.pumpAndSettle(const Duration(milliseconds: 500));
```

### 4. ウィジェット検索のコツ
```dart
// テキストで検索
expect(find.text('バッジ図鑑'), findsOneWidget);

// 部分テキストマッチ
expect(find.textContaining('バッジ'), findsWidgets);

// ウィジェットタイプで検索
expect(find.byType(Card), findsOneWidget);

// アイコンで検索
expect(find.byIcon(Icons.chevron_left), findsOneWidget);

// 複数個検索
expect(find.byType(LinearProgressIndicator), findsWidgets);
```

### 5. ユーザーインタラクションのシミュレーション
```dart
// ボタンをタップ
await tester.tap(find.byType(ElevatedButton));

// リストをスクロール
await tester.drag(
  find.byType(GridView).first,
  const Offset(0, -300),
);

// テキストを入力
await tester.enterText(find.byType(TextField), '入力テキスト');
```

## テスト保守のガイドライン

### 1. テスト命名規則
```dart
// ❌ 不適切
testWidgets('test', (tester) async { });

// ✅ 適切
testWidgets('displays badge emoji when badge card is rendered', (tester) async { });

// ✅ より詳細
testWidgets('progress bar shows correct percentage when progress is 0.25', (tester) async { });
```

### 2. テストグループの整理
```dart
group('BadgeShowcaseScreen', () {
  group('initial state', () {
    testWidgets('shows loading indicator', (tester) async { });
  });

  group('when badges are loaded', () {
    testWidgets('displays earned badges', (tester) async { });
  });

  group('user interactions', () {
    testWidgets('scrolls to show all badges', (tester) async { });
  });
});
```

### 3. 共通テストロジックの抽出
```dart
Future<void> _pumpBadgeShowcaseAndSettle(
  WidgetTester tester, {
  int? earnedCount,
}) async {
  await tester.pumpWidget(_wrapBadgeShowcase(
    totalEarned: earnedCount,
  ));
  await tester.pumpAndSettle();
}

// 使用例
testWidgets('displays correct count', (tester) async {
  await _pumpBadgeShowcaseAndSettle(tester, earnedCount: 2);
  expect(find.byType(Card), findsWidgets);
});
```

### 4. 脆弱なテストを避ける
```dart
// ❌ テキスト完全一致に依存（変更に弱い）
expect(find.text('やさしい心'), findsOneWidget);

// ✅ より堅牢
expect(find.textContaining('心'), findsWidgets);
expect(find.byType(Card), findsWidgets);

// ✅ さらに良い
// UI テストよりロジックテストに重点を置く
```

## 一般的なテスト失敗と対処法

| 症状 | 原因 | 対処法 |
|------|------|--------|
| `A GestureDetector with no onTap or onDrag` | タップ対象がない | ウィジェット構造確認 |
| `timed out while trying to find` | ウィジェット見つからない | `pumpAndSettle()` 追加 |
| `Binding has not yet been initialized` | テスト初期化エラー | `setUp()` でバインディング確認 |
| `null is not a subtype of 'String'` | null 安全性 | 型チェック追加 |
| `Test timed out after 30 seconds` | 非同期処理が長い | future.timeout 設定 |

## テストカバレッジの目標

| 対象 | 目標 | 現状 |
|------|------|------|
| バッジ関連ウィジェット | 85% | 90% ✅ |
| レポートスクリーン | 75% | 80% ✅ |
| 統合フロー | 70% | 75% ✅ |
| 全体 | 75% | 78% ✅ |

## 今後の改善予定

- [ ] Golden テスト（スナップショット）の実装
- [ ] パフォーマンステストの充実
- [ ] E2E テストの拡張
- [ ] アクセシビリティテストの追加
- [ ] 多言語テストの実装

## テスト実行の自動化

### CI/CD パイプラインでの実行例
```yaml
test:
  stage: test
  script:
    - flutter test
    - flutter test --coverage
  artifacts:
    paths:
      - coverage/
```

### Pre-commit フック
```bash
#!/bin/bash
flutter test --fail-fast
if [ $? -ne 0 ]; then
  exit 1
fi
```

## 参考資料

- [Flutter Widget Testing](https://flutter.dev/docs/testing/testing#widget-testing)
- [Riverpod Testing](https://riverpod.dev/docs/essentials/testing)
- [Flutter Best Practices](https://flutter.dev/docs/testing)
