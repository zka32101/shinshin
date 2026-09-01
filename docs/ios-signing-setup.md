# iOS リリース署名設定ガイド

## 概要

小学コレ！道徳アプリ (jp.petitworks.shougaku_kore_doutoku) の iOS リリース署名設定ガイドです。

## Apple アカウント準備

### 1. Apple Developer Program への登録

1. [Apple Developer Program](https://developer.apple.com/programs/) に登録
2. 組織情報を設定
3. Team ID を控える（例: `ABCDEFG123`）

### 2. App Store Connect でのアプリ設定

1. [App Store Connect](https://appstoreconnect.apple.com/) にログイン
2. **My Apps** で新しいアプリを作成
   - アプリ名: `小学コレ！道徳`
   - Bundle ID: `jp.petitworks.shougaku_kore_doutoku`
   - SKU: `shougaku-kore-doutoku`
   - プラットフォーム: iOS

### 3. Bundle ID 設定

1. App Store Connect で Bundle ID を確認
2. Xcode で Signing & Capabilities を設定:
   - Team ID: Apple Developer Team ID
   - Bundle Identifier: `jp.petitworks.shougaku_kore_doutoku`

## Xcode での署名設定

### 自動署名（推奨）

最もシンプルな方法は Xcode の自動署名を使用することです。

1. Xcode で `ios/Runner.xcworkspace` を開く
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Runner プロジェクトを選択
3. Runner ターゲットを選択
4. **Signing & Capabilities** タブを開く

5. 以下を設定:
   - **Team**: Apple Developer Team を選択
   - **Automatically manage signing**: ✓ (チェック)
   - **Bundle Identifier**: `jp.petitworks.shougaku_kore_doutoku`

### 手動署名（高度な設定）

CI/CD パイプラインで手動署名を使用する場合:

1. **Signing & Capabilities** タブで自動署名を **OFF** に
2. Release ビルド設定で署名証明書とプロビジョニングプロファイルを指定:
   ```
   Code Signing Identity: Apple Distribution: [Your Team Name]
   Provisioning Profile: [App Store プロビジョニングプロファイル]
   ```

## GitHub Actions での自動署名

### 1. 証明書とプロビジョニングプロファイルの準備

#### 開発用証明書（Development Certificate）

1. Xcode で キーチェーン > 証明書要求助手
2. Apple Developer アカウントでサイン
3. 証明書をダウンロード (.cer)

#### App Store 配布用証明書（Distribution Certificate）

1. [Apple Developer](https://developer.apple.com/account/resources/certificates/list) で作成
2. p12 形式でダウンロード:
   ```bash
   # .cer を .p12 に変換
   openssl pkcs12 -export -in certificate.cer -inkey private_key.key -out certificate.p12
   ```

#### プロビジョニングプロファイル

1. [Apple Developer](https://developer.apple.com/account/resources/profiles/list) から:
   - **App Store** プロビジョニングプロファイルをダウンロード (.mobileprovision)

### 2. GitHub Secrets 設定

以下を GitHub リポジトリの **Settings > Secrets and variables > Actions** に追加:

```
IOS_CERTIFICATE_P12_BASE64
  値: (Base64 エンコードされた .p12 ファイル)
  
  # 作成方法:
  base64 -i certificate.p12 | tr -d '\n'

IOS_PROVISIONING_PROFILE_BASE64
  値: (Base64 エンコードされた .mobileprovision ファイル)
  
  # 作成方法:
  base64 -i Provisioning_Profile_Name.mobileprovision | tr -d '\n'

IOS_CERTIFICATE_PASSWORD
  値: (p12 ファイルのパスワード)

IOS_TEAM_ID
  値: (Apple Developer Team ID, 例: ABCDEFG123)

IOS_BUNDLE_ID
  値: jp.petitworks.shougaku_kore_doutoku
```

### 3. GitHub Actions ワークフロー例

```yaml
name: Build iOS Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      # 証明書をインストール
      - name: Install Apple Certificate
        env:
          CERT_DATA: ${{ secrets.IOS_CERTIFICATE_P12_BASE64 }}
          CERT_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
        run: |
          # Base64 をデコード
          echo $CERT_DATA | base64 --decode > certificate.p12
          
          # キーチェーンにインポート
          security create-keychain -p ${{ secrets.IOS_KEYCHAIN_PASSWORD }} build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p ${{ secrets.IOS_KEYCHAIN_PASSWORD }} build.keychain
          security import certificate.p12 -k build.keychain -P "$CERT_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -k ${{ secrets.IOS_KEYCHAIN_PASSWORD }} build.keychain
      
      # プロビジョニングプロファイルをインストール
      - name: Install Provisioning Profile
        env:
          PROFILE_DATA: ${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}
        run: |
          echo $PROFILE_DATA | base64 --decode > profile.mobileprovision
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
      
      # iOS ビルド
      - name: Build iOS Release
        run: |
          flutter build ios --release \
            --dart-define=FLUTTER_BUILD_NAME=1.0.0 \
            --dart-define=FLUTTER_BUILD_NUMBER=1
      
      # IPA をエクスポート
      - name: Build IPA
        run: |
          cd ios
          xcodebuild -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -derivedDataPath build \
            -allowProvisioningUpdates \
            -archivePath build/Runner.xcarchive \
            archive
          
          xcodebuild -exportArchive \
            -archivePath build/Runner.xcarchive \
            -exportPath build/Release \
            -exportOptionsPlist ExportOptions.plist
```

## Fastlane を使用した自動化（推奨）

より高度な自動化には [Fastlane](https://fastlane.tools/) の使用を推奨します。

### Fastlane セットアップ

```bash
# Fastlane をインストール
sudo gem install fastlane

# ios ディレクトリで初期化
cd ios
fastlane init
```

### Fastlane ファイル設定例

```ruby
# ios/fastlane/Fastfile

default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      export_options: {
        provisioningProfileName: "Shougaku Kore Doutoku AppStore",
        signingStyle: "automatic"
      }
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  desc "Build and upload to App Store"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store"
    )
    
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: false
    )
  end
end
```

## トラブルシューティング

### 署名エラーが発生する場合

1. Xcode をリセット
   ```bash
   xcode-select --reset
   ```

2. キーチェーンをリセット
   ```bash
   security delete-keychain build.keychain
   ```

3. 証明書を再ダウンロード（Apple Developer から）

### プロビジョニングプロファイルが見つからない

```bash
# インストール済みプロファイルの確認
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# プロファイルをリフレッシュ
xcrun -sdk iphoneos security find-identity -a -p codesigning -v | head -5
```

## Info.plist の確認

Flutter アプリの `ios/Runner/Info.plist` には以下が設定されています:

```xml
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>
<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
```

これらはビルド時に自動的に設定されます。

## 参考資料

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Apple App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Xcode Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html)

## 次のステップ

1. ✅ Apple Developer アカウントを準備
2. ✅ App Store Connect でアプリを設定
3. ✅ Xcode で署名設定
4. ✅ テストフライトでテスト
5. ✅ App Store に申請

---

**最後更新**: 2026-09-01  
**対象バージョン**: v1.0.0+
