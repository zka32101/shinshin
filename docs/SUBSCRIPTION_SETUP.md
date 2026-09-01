# サブスクリプション機能 - セットアップガイド

## 概要

このドキュメントは、小学コレ！道徳アプリの2週間無料トライアルとサブスクリプション機能の実装手順を説明します。

## 前提条件

- Flutter 3.3.0以上
- Dart 3.3.0以上
- Firebase プロジェクトの作成完了
- App Store Connect アカウント（iOS版リリース時）
- Google Play Console アカウント（Android版リリース時）

## ステップ1: iOS App Store Connect での商品設定

### 1.1 App Store Connect へのログイン

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. **My Apps** をクリック
3. 小学コレ！道徳アプリを選択

### 1.2 In-App Purchase 商品の作成

#### 月額サブスクリプション（Monthly）

1. 左メニューから **In-App Purchases** をクリック
2. **+** ボタンから **Subscription** を選択
3. 以下の情報を入力：
   - **Reference Name**: Monthly Subscription JP
   - **Subscription Group**: `shougaku_kore_doutoku_subscriptions`
   - **Product ID**: `jp.petitworks.shougaku_kore_doutoku.monthly`
   - **Duration**: 1 Month
   - **Recurring Free Trial Period**: 2 weeks
   - **Price Tier**: JP Tier 3（250円）
   - **Localization**: 日本語で説明を追加

#### 年額サブスクリプション（Yearly）

1. 同様に **+** ボタンから **Subscription** を選択
2. 以下の情報を入力：
   - **Reference Name**: Yearly Subscription JP
   - **Subscription Group**: `shougaku_kore_doutoku_subscriptions`（同じグループを使用）
   - **Product ID**: `jp.petitworks.shougaku_kore_doutoku.yearly`
   - **Duration**: 1 Year
   - **Recurring Free Trial Period**: 2 weeks
   - **Price Tier**: JP Tier 30（2,500円）
   - **Localization**: 日本語で説明を追加

### 1.3 テスト用ユーザーの作成

1. 左メニューから **Users and Access** → **Sandbox** をクリック
2. **+** ボタンで Sandbox Tester を作成
3. テスト用メールアドレスを設定（複数作成可）

## ステップ2: Google Play Console での商品設定

### 2.1 Google Play Console へのログイン

1. [Google Play Console](https://play.google.com/console) にログイン
2. 小学コレ！道徳アプリを選択

### 2.2 In-App Product の作成

#### 月額サブスクリプション（Monthly）

1. 左メニューから **Products** → **Subscriptions** をクリック
2. **Create subscription** をクリック
3. 以下の情報を入力：
   - **Product ID**: `jp.petitworks.shougaku_kore_doutoku.monthly`
   - **Default language title**: "月額サブスクリプション"
   - **Default language description**: "毎月自動更新される月額サブスクリプションです"
   - **Billing period**: Monthly
   - **Free trial period**: 14 days
   - **Price**: ¥250

#### 年額サブスクリプション（Yearly）

1. 同様に **Create subscription** をクリック
2. 以下の情報を入力：
   - **Product ID**: `jp.petitworks.shougaku_kore_doutoku.yearly`
   - **Default language title**: "年額サブスクリプション"
   - **Default language description**: "毎年自動更新される年額サブスクリプションです"
   - **Billing period**: Yearly
   - **Free trial period**: 14 days
   - **Price**: ¥2,500

### 2.3 テスト用ユーザーの追加

1. 左メニューから **Settings** → **License Testing** をクリック
2. **Gmail account** に Google アカウントを追加（複数追加可）

## ステップ3: Flutter プロジェクトの設定

### 3.1 依存パッケージの確認

`pubspec.yaml` に以下が含まれていることを確認：

```yaml
dependencies:
  in_app_purchase: ^3.1.0
  in_app_purchase_android: ^0.3.3
  in_app_purchase_storekit: ^0.3.10
```

### 3.2 iOS の設定

#### 3.2.1 Xcode での設定

1. Xcode で `ios/Runner.xcworkspace` を開く
2. **Runner** プロジェクトを選択
3. **Capabilities** タブで **In-App Purchase** を有効化

#### 3.2.2 Info.plist の確認

`ios/Runner/Info.plist` に以下が含まれていることを確認：

```xml
<key>SKAdNetworkItems</key>
<array/>
```

### 3.3 Android の設定

#### 3.3.1 build.gradle の確認

`android/app/build.gradle` で `minSdkVersion` が 21 以上であることを確認：

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

#### 3.3.2 AndroidManifest.xml の確認

`android/app/src/main/AndroidManifest.xml` に以下が含まれていることを確認：

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### 3.4 Flutter パッケージの取得

```bash
flutter pub get
flutter pub run build_runner build
```

## ステップ4: Firebase Firestore スキーマ

### 4.1 Firestore Collections

ユーザーのサブスクリプション情報は以下の構造で保存されます：

```
/users/{userId}/
  └── subscription/
      └── info {
          status: 'trial' | 'active' | 'expired' | 'cancelled',
          plan: 'trial' | 'monthly' | 'yearly',
          trialStartDate: Timestamp,
          trialEndDate: Timestamp,
          subscriptionStartDate: Timestamp,
          subscriptionEndDate: Timestamp,
          planType: 'monthly' | 'yearly' | null,
          lastPaymentDate: Timestamp | null,
          autoRenewalEnabled: boolean,
          transactionId: string | null,
        }
```

## ステップ5: バックエンド検証エンドポイント

### 5.1 Apple App Store Server API の設定

1. App Store Connect で **API Keys** を作成
2. Private Key をダウンロード
3. Backend で以下の環境変数を設定：
   ```
   APPLE_BUNDLE_ID=jp.petitworks.shougaku_kore_doutoku
   APPLE_KEY_ID=<Key ID>
   APPLE_ISSUER_ID=<Issuer ID>
   APPLE_PRIVATE_KEY_PATH=/path/to/private/key.p8
   ```

### 5.2 Google Play Billing API の設定

1. Google Play Console で Service Account を作成
2. JSON キーをダウンロード
3. Backend で以下の環境変数を設定：
   ```
   GOOGLE_PLAY_PACKAGE_NAME=jp.petitworks.shougaku_kore_doutoku
   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH=/path/to/service-account.json
   ```

## ステップ6: ローカルテスト

### テスト用デバイスの設定

**iOS (Sandbox Tester)**
1. Settings → App Store でテスト用アカウントでログイン
2. アプリを起動して購入フローをテスト

**Android (License Testing)**
1. Settings → Google Play でテスト用アカウントでログイン
2. アプリを起動して購入フローをテスト

詳細は [IN_APP_PURCHASE_TESTING.md](./IN_APP_PURCHASE_TESTING.md) を参照

## ステップ7: Production での設定

### 7.1 App Store

1. Build Version を上げる
2. In-App Purchase 商品が有効化されていることを確認
3. テストを完了してから申請

### 7.2 Google Play

1. `versionCode` を上げる
2. In-App Product が有効化されていることを確認
3. テストを完了してから申請

## トラブルシューティング

### 商品が取得できない
- Firebase Firestore にアクセス権限があるか確認
- Product ID が正確か確認（大文字小文字を区別）
- App Store Connect / Google Play Console で商品が有効化されているか確認

### 購入フローでエラーが出る
- インターネット接続を確認
- テスト用アカウントが正しくセットアップされているか確認
- Sandbox / License Testing 環境を使用しているか確認

### Firestore への保存が失敗する
- ユーザーがログインしているか確認
- Firestore セキュリティルールで書き込み権限があるか確認
- Firebase プロジェクトが正しく初期化されているか確認

## 参考資料

- [In-App Purchase Documentation](https://pub.dev/packages/in_app_purchase)
- [Apple App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [Google Play Billing Library](https://developer.android.com/google/play/billing)
- [Firebase Firestore Documentation](https://firebase.google.com/docs/firestore)
