# In-App Purchase テストガイド

## 概要

このドキュメントは、小学コレ！道徳アプリの In-App Purchase 機能を各プラットフォームでテストする手順を説明します。

## iOS テスト（App Store Sandbox）

### 1. テスト用アカウントの作成

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. **Users and Access** → **Sandbox** をクリック
3. **+** ボタンで Sandbox Tester を作成
4. 以下の情報を入力：
   - **First Name**: テスト太郎
   - **Last Name**: テスト花子
   - **Email**: `test-monthly@example.com` など
   - **Password**: 自動生成
   - **Questions**: セキュリティ質問に回答

### 2. テスト用デバイスの設定

1. iOS デバイス（またはシミュレータ）で **Settings** を開く
2. **App Store** をタップ
3. 既にログインしているアカウントからログアウト
4. Sandbox Tester アカウントでログイン
5. アプリを起動

### 3. テストシナリオ

#### シナリオ1: 無料トライアル開始

```
期待される動作:
1. アプリを初回起動
2. ユーザー登録画面で新規ユーザーとして登録
3. 自動的に 14 日間の無料トライアルが開始
4. ホーム画面でトライアル状態バナーが表示
```

テスト手順:
1. アプリを起動
2. 新規登録フローを完了
3. トライアル状態バナーが表示されることを確認
4. `Navigator.pushNamed('/trial_status')` でトライアル状態画面に移動
5. 「あと 14 日」と表示されることを確認

#### シナリオ2: 月額プラン購入

```
期待される動作:
1. サブスクリプション画面で「月額プラン」を選択
2. 「購入する」ボタンをタップ
3. App Store の購入確認ダイアログが表示
4. 購入を完了
5. Firestore のサブスクリプション情報が更新
6. ホーム画面にサブスクリプション有効状態が表示
```

テスト手順:
1. ホーム画面で「購入」ボタンをタップ
2. `/subscription` ルートに遷移
3. 月額プランを選択
4. 「購入する」ボタンをタップ
5. App Store の確認ダイアログで「購入」をタップ
6. 購入成功メッセージが表示されることを確認
7. Firestore で `/users/{uid}/subscription/info` ドキュメントを確認
   - `status`: `'active'`
   - `plan`: `'monthly'`
   - `planType`: `'monthly'`
   - `subscriptionStartDate`: 現在時刻
   - `subscriptionEndDate`: 30日後

#### シナリオ3: 年額プラン購入

```
期待される動作:
シナリオ2と同様だが、年額プランが選択されることを確認
```

テスト手順:
1. 月額プラン購入後、キャンセルしてから年額プランを試す
2. または異なるテスト用アカウントで新規登録してから年額プランを購入
3. Firestore で確認：
   - `plan`: `'yearly'`
   - `planType`: `'yearly'`
   - `subscriptionEndDate`: 365日後

#### シナリオ4: 購入内容の復元

```
期待される動作:
1. 別のデバイス/セッションから同じアカウントでアプリ起動
2. 「前に購入した内容を復元」ボタンをタップ
3. 前回購入したサブスクリプション情報が復元
```

テスト手順:
1. 別のシミュレータ/デバイスで同じ Sandbox Tester アカウントでログイン
2. アプリを起動
3. サブスクリプション画面に移動
4. 「前に購入した内容を復元」をタップ
5. 復元成功メッセージが表示される
6. Firestore で subscription 情報が存在することを確認

#### シナリオ5: サブスクリプションキャンセル

```
期待される動作:
1. サブスクリプション管理画面でキャンセル操作
2. Firestore のステータスが 'cancelled' に変更
3. 次回更新日以降アクセスが制限される（実装により異なる）
```

テスト手順:
1. サブスクリプション管理画面で「キャンセル」ボタンをタップ
2. 確認ダイアログで「キャンセル」をタップ
3. Firestore で確認：
   - `status`: `'cancelled'`
   - `autoRenewalEnabled`: `false`

### 4. iOS シミュレータでのテスト

Sandbox テストは実デバイスでのみ可能です。シミュレータでは以下のような制限があります：

- In-App Purchase フローはシミュレートできない
- ただし、Mock を使ってロジックをテスト可能

シミュレータでテストする場合：

```bash
flutter run -d iPhone_15 --flavor development
```

その後、Mock を使ってテストコードを実装：

```dart
testWidgets('Trial status screen displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  expect(find.text('トライアル期間中'), findsOneWidget);
  expect(find.text('あと 14 日'), findsOneWidget);
});
```

## Android テスト（Google Play License Testing）

### 1. テスト用アカウントの追加

1. [Google Play Console](https://play.google.com/console) にログイン
2. **Settings** → **License Testing** をクリック
3. **Gmail accounts** に Google アカウントを追加（複数可）
4. 変更を保存

### 2. テスト用デバイスの設定

1. Android デバイス/エミュレータで **Settings** を開く
2. **Google** → **Manage your Google Account** をクリック
3. テスト用 Google アカウントを追加
4. **Play Store** アプリで新規インストール

### 3. iOS と同じテストシナリオを実行

#### テスト用アカウントでのみ利用可能な機能

Google Play では特別なテスト Product ID が用意されています：

```
com.android.vending.managed.test.purchased
com.android.vending.managed.test.canceled
com.android.vending.managed.test.refunded
com.android.vending.managed.test.item_unavailable
```

これらで実装をテスト可能ですが、実際の商品 ID でテストすることを推奨します。

### 4. Android エミュレータでのテスト

Android エミュレータは Google Play Services を持つ image が必要です：

```bash
# Google Play Services 対応 image でエミュレータを実行
flutter run -d emulator-5554
```

エミュレータで License Testing アカウントを使用してテスト。

## テストチェックリスト

### 共通

- [ ] 新規ユーザー登録時に自動的に Trial が開始される
- [ ] Trial 期間中のバナーが表示される
- [ ] Trial 残り日数が正確に表示される
- [ ] サブスクリプション画面が正常に読み込まれる
- [ ] 商品情報が正確に表示される

### iOS 固有

- [ ] App Store Sandbox アカウントで購入可能
- [ ] Sandbox Tester でのみ購入フローが動作
- [ ] Receipt が正常に検証される
- [ ] 複数デバイスでの復元が機能

### Android 固有

- [ ] Google Play License Testing アカウントで購入可能
- [ ] License Testing アカウントでのみ購入フローが動作
- [ ] Google Play Billing Library が正常に動作
- [ ] Play Store での購入履歴に反映される

## デバッグログの確認

### iOS

```bash
# Xcode の Console でログを確認
# または
flutter logs
```

### Android

```bash
flutter logs
# または
adb logcat | grep -i "iap\|purchase"
```

## トラブルシューティング

### 商品が見つからない

**原因**: Product ID が一致していない

**解決策**:
1. App Store Connect / Google Play Console で Product ID を確認
2. `payment_service.dart` の Product ID と一致することを確認
3. 大文字小文字を正確に入力

### 購入ダイアログが表示されない

**原因**: テスト用アカウントが正しくセットアップされていない

**解決策**:
1. テスト用アカウントが有効な状態か確認
2. デバイス/シミュレータのアカウントを再度確認
3. アプリを再起動

### Receipt 検証エラー

**原因**: バックエンド API が正常に機能していない

**解決策**:
1. バックエンド API のエンドポイントが正しいか確認
2. Firebase 認証情報が正しいか確認
3. ネットワーク接続を確認

### 購入後 Firestore が更新されない

**原因**: `handlePurchaseUpdate` が呼ばれていない、または Receipt 検証に失敗

**解決策**:
1. Flutter ログで `handlePurchaseUpdate` が呼ばれているか確認
2. Receipt 検証エラーがないか確認
3. Firestore セキュリティルールで書き込み権限があるか確認

## 参考資料

- [In-App Purchase: Testing](https://pub.dev/packages/in_app_purchase#testing)
- [App Store Server API Documentation](https://developer.apple.com/documentation/appstoreserverapi)
- [Google Play Billing Library: Testing](https://developer.android.com/google/play/billing/test)
