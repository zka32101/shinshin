# 本番リリース手順書（最終版）

**小学コレ！道徳** - v1.0.0+

**最終更新**: 2026年9月1日  
**次回レビュー**: リリース後30日

---

## 概要

このドキュメントは、小学コレ！道徳アプリを App Store および Google Play に本番リリースする際の詳細な手順を定めています。

**リリース所要時間**: 約4-6時間（テスト含む）

---

## リリース前準備（リリース日の前日）

### 1.1 ステージング環境で最終テスト

```bash
# リリース対象ブランチをチェックアウト
git checkout release/v1.x.x

# 依存関係を更新
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# ビルドが成功するか確認
flutter build apk --release --no-shrink
flutter build ios --release

# ステージング環境で E2E テスト実行
flutter test integration_test -t staging
```

### 1.2 リリースノートの準備

**ファイル**: `docs/RELEASE_NOTES_v1.x.x.md`

```markdown
# v1.x.x リリースノート

## 新機能
- 機能 A
- 機能 B

## 改善
- パフォーマンス改善
- UI/UX 改善

## バグ修正
- 問題 A 修正
- 問題 B 修正

## 既知の問題
- なし

## アップグレード注記
- なし
```

### 1.3 バージョン番号の更新

#### 1.3.1 pubspec.yaml の更新

```yaml
version: 1.x.x+<build_number>
```

**ルール**:
- メジャー.マイナー.パッチ に従う
- ビルド番号は前回から +1

```bash
# 現在のバージョン確認
grep "^version:" pubspec.yaml
```

#### 1.3.2 iOS バージョン更新

**ファイル**: `ios/Runner.xcodeproj/project.pbxproj`

```
FLUTTER_BUILD_NAME = 1.x.x
FLUTTER_BUILD_NUMBER = <build_number>
```

**確認方法**:
```bash
# Xcode で確認
open ios/Runner.xcworkspace

# またはコマンドラインで確認
grep -A2 "FLUTTER_BUILD_NAME" ios/Runner.xcodeproj/project.pbxproj
```

#### 1.3.3 Android バージョン確認

**ファイル**: `android/app/build.gradle.kts`

```kotlin
android {
    defaultConfig {
        versionCode = flutter.versionCode  // pubspec.yaml から自動取得
        versionName = flutter.versionName  // pubspec.yaml から自動取得
    }
}
```

---

## リリース当日の手順

### フェーズ 1: リリース前の最終確認（リリース日 7:00-8:00）

#### チェックリスト

- [ ] Git リポジトリが clean 状態か確認
  ```bash
  git status
  ```

- [ ] すべてのテストが pass しているか確認
  ```bash
  flutter test --coverage
  
  # テストカバレッジ確認
  open coverage/index.html
  ```

- [ ] 静的解析でエラーなし
  ```bash
  flutter analyze --no-pub
  ```

- [ ] リリースノートが準備されているか

- [ ] 署名設定が正しいか確認
  ```bash
  # Android キーストア確認
  ls -la ~/.shougaku-kore-release.jks
  
  # iOS 証明書確認
  security find-identity -v -p codesigning
  ```

- [ ] Firebase Staging プロジェクト設定確認
  ```bash
  cat lib/config/firebase_config.dart
  ```

### フェーズ 2: ビルド & 署名（リリース日 8:00-9:00）

#### 2.1 Android APK/AAB ビルド

**Google Play では Android App Bundle (AAB) が必須**

```bash
# AAB ビルド（署名付き）
flutter build appbundle \
  --release \
  --build-number=<build_number>

# 出力確認
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**AAB 署名の詳細**:
```bash
# Google Play では環境変数から署名情報を読み込み
export KEYSTORE_PATH=/path/to/keystore
export KEYSTORE_PASSWORD=<password>
export KEYSTORE_ALIAS=shougaku-kore-key
export KEYSTORE_KEY_PASSWORD=<key_password>

flutter build appbundle --release
```

#### 2.2 iOS ビルド

```bash
# Pod 依存関係をアップデート
cd ios && pod update && cd ..

# iOS ビルド（リリース用）
flutter build ios --release \
  --build-number=<build_number>

# xcarchive を生成
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/runner.xcarchive \
  -derivedDataPath build/ios_derived_data
```

**ビルド検証**:
```bash
# iOS ビルド成功確認
ls -la build/ios/runner.xcarchive

# ファイルサイズ確認（通常 50-150MB）
du -sh build/ios/runner.xcarchive
```

### フェーズ 3: Google Play アップロード（リリース日 9:00-10:30）

#### 3.1 Google Play Console へのアップロード

1. **Google Play Console にログイン**
   - https://play.google.com/console
   - アプリ: 小学コレ！道徳

2. **リリース > テスト > 本番環境**

3. **新しいリリースを作成**
   - "新しいリリース"をクリック
   - AAB ファイルをアップロード:
     ```
     build/app/outputs/bundle/release/app-release.aab
     ```

4. **リリース情報を入力**
   ```
   リリース名: v1.x.x
   リリースノート:
   - 新機能 A を追加しました
   - パフォーマンスを改善しました
   - バグを修正しました
   
   言語: 日本語
   ```

5. **国/地域を確認**
   - 対象国: 日本
   - その他の国への段階的ロールアウトオプション

#### 3.2 段階的ロールアウト設定（重要）

**リリース リスク管理**:

```
段階 1: 25% ユーザー (1日目)
  - 内部テスト用途
  - クラッシュレート監視

段階 2: 50% ユーザー (2-3日目)
  - ANR、メモリリーク監視

段階 3: 100% ユーザー (4日目)
  - 段階1-2で問題がなければ実施
```

**Google Play Console での設定**:

```
テスト > 本番環境 > リリース > "段階的なロールアウト"

段階 1:
- % ユーザー: 25
- 期間: 1 日

段階 2:
- % ユーザー: 50
- 期間: 2 日

段階 3:
- % ユーザー: 100
- 期間: 即時
```

**ロールアウト中止手順**:
```
もし P1 レベルのバグが検出されたら:

1. Google Play Console で "ロールアウト中止"をクリック
2. 原因特定
3. ホットフィックス対応（docs/HOTFIX_RESPONSE_PLAN.md 参照）
```

#### 3.3 Google Play アップロード後のチェック

```bash
# Google Play Console で以下を確認
- [ ] AAB がアップロードされた
- [ ] 署名設定が正しい
- [ ] リリースノートが表示される
- [ ] ステータスが "レビュー中" → "公開準備完了"
```

**公開をリリース方法の選択**:
- "自動的に公開する" ✅ (24時間後に自動公開)
- または
- "手動公開" (レビュー完了後に手動で公開)

### フェーズ 4: App Store アップロード（リリース日 10:30-12:00）

#### 4.1 TestFlight へのアップロード（本番検証用）

```bash
# ipa ファイルを生成
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates

# ipa ファイル確認
ls -lh build/ios/ipa/runner.ipa
```

**ExportOptions.plist の例**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>TEAM_ID</string>
</dict>
</plist>
```

#### 4.2 Transporter で App Store に提出

```bash
# Apple Developer アカウントで Transporter にログイン
# または

# コマンドラインから提出
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/runner.ipa \
  --username apple_id@example.com \
  --password app_specific_password

# または最新の Transporter CLI を使用
cd build/ios/ipa
open /Applications/Transporter.app
# GUI で runner.ipa をドラッグ&ドロップ
```

#### 4.3 App Store Connect での設定

1. **App Store Connect にログイン**
   - https://appstoreconnect.apple.com

2. **My Apps > 小学コレ！道徳 > iOS App**

3. **バージョンまたは ビルド**
   - "新しいバージョンを作成"

4. **バージョン情報**
   ```
   バージョン番号: 1.x.x
   ビルド番号: <build_number> (TestFlight でアップロードしたものと同じ)
   ```

5. **リリースノートを入力**
   ```
   このリリースの内容:
   - 新機能 A を追加しました
   - パフォーマンスを改善しました
   - バグを修正しました
   ```

6. **App Store での表示**
   - スクリーンショット: 確認
   - プレビュー動画: あれば追加
   - キーワード: 確認
   - 説明: 確認
   - サポート URL: 確認
   - プライバシーポリシー URL: 確認

7. **審査情報**
   ```
   テスト用 アカウント情報:
   - メール: test_parent@example.com
   - パスワード: (テスト用パスワード)
   
   アプリ内課金テスト設定:
   - テスト用 Apple ID を登録
   ```

8. **リリース方法の選択**
   ```
   ☐ 自動的にリリース (Apple の審査完了後)
   ☑ 手動でリリース (レビュー完了後に確認してからリリース)
   ```

---

## リリース後の監視（リリース日 + 24時間）

### フェーズ 5: リリース直後の監視（リリース日 12:00-20:00）

#### 5.1 ダッシュボード監視

**Firebase Console で監視**:
```
Analytics > Dashboards > (リアルタイムユーザー)
- ユーザー数
- クラッシュレート
- セッション継続時間

Crashlytics > Issues
- クラッシュレート (目標: < 0.5%)
- トップのクラッシュ
```

**監視スケジュール**:
- リリース直後: 15分ごと
- 1時間経過: 30分ごと
- 3時間経過: 1時間ごと
- 6時間経過: 2時間ごと

#### 5.2 主要メトリクスの確認

| メトリクス | 目標値 | 閾値（アラート） |
|-----------|-------|----------------|
| クラッシュレート | < 0.5% | > 1% 🚨 |
| ANR レート | < 0.1% | > 0.5% 🚨 |
| 起動時間 | < 3秒 | > 5秒 ⚠️ |
| API 応答時間 | < 500ms | > 1000ms ⚠️ |

#### 5.3 Google Play/App Store での自動署名確認

```bash
# Google Play でビルド署名を確認
# Play Console > テスト > 本番環境 > "app-release.aab"

# 署名フィンガープリント確認
keytool -list -v -keystore ~/.shougaku-kore-release.jks

# App Store でのビルド署名確認
# App Store Connect > MyApps > ビルド > (アップロード済みビルド)
```

#### 5.4 ユーザー反応の監視

- **App Store/Google Play レビュー**: 1時間ごと確認
  - クラッシュレポート件数
  - ネガティブレビュー
  
- **Firebase Messaging**: プッシュ通知監視
  - 送信成功率

- **Slack 通知設定**: アラート受信確認

---

## リリース後の段階的ロールアウト（Day 2-3）

### フェーズ 6: 段階的ロールアウト管理

**Google Play での段階的ロールアウト**:

```
【Day 1: 25% ロールアウト】
時刻: リリース完了から 24時間後
手順:
1. Google Play Console にログイン
2. "テスト > 本番環境"
3. "段階的なロールアウト"から "段階 1 を開始"

監視: クラッシュレート、ANR
目標値: < 0.5%
条件: この値に留まっていれば次段階へ

【Day 2-3: 50% ロールアウト】
時刻: Day 1 から 24-48時間後
手順:
1. 25% グループの監視データを確認
2. 問題がなければ "段階 2 を開始"

【Day 4: 100% ロールアウト】
時刻: Day 2-3 から 48時間後
手順:
1. 50% グループの監視データを確認
2. 問題がなければ "段階 3 を開始"（全ユーザーへリリース）
```

**App Store での自動リリース**:
- Apple のレビュー完了後、自動的に App Store で公開

---

## トラブルシューティング

### リリース中に問題が発生した場合

#### 症状: "ビルドがリジェクトされた"

```
【Google Play】
- AAB に無効な署名がある
  → 解決: keystore ファイルが正しいか確認

- minSdk が要件を満たしていない
  → 解決: android/app/build.gradle.kts で minSdk を確認

【App Store】
- ビルドステータスが "Invalid"
  → 解決: Apple の審査中にビルドを削除していないか確認
  
- ビットコード サポート が必須
  → 解決: Xcode > Build Settings > Enable Bitcode = Yes
```

#### 症状: "リリース後にクラッシュが増加した"

**対応**:
1. ロールアウトを中止（Google Play: "ロールアウト中止"をクリック）
2. ホットフィックス対応（docs/HOTFIX_RESPONSE_PLAN.md）
3. ロールバック（前のバージョンに戻す）

#### 症状: "App Store でのレビューが却下された"

**一般的な却下理由**:
- COPPA 違反（子ども向けアプリの規制）
  → docs/COPPA_COMPLIANCE_CHECKLIST.md を確認
  
- 課金機能の不適切な表示
  → docs/PAYMENT_INTEGRATION.md を確認
  
- プライバシーの不透明性
  → App Store Connect > プライバシー ラベルを確認

---

## リリース後チェックリスト（Day 1-4）

### リリース Day 1

- [ ] クラッシュレート確認（< 0.5%）
- [ ] ユーザー コメント確認
- [ ] Google Play でのダウンロード数確認
- [ ] API エラーログ確認
- [ ] Firebase Crashlytics でトップ クラッシュを確認

### リリース Day 2

- [ ] 25% ロールアウト監視データ確認
- [ ] ユーザー フィードバック確認
- [ ] セッション継続時間確認（> 5分）
- [ ] App Store での審査ステータス確認

### リリース Day 3-4

- [ ] 50% → 100% ロールアウト判定
- [ ] ファイナル メトリクス確認
- [ ] リリース後ドキュメント アップデート

---

## ロールバック手順

**緊急時のロールバック**:

```bash
# 前のバージョンのタグを確認
git tag -l | grep "v1\." | sort -V | tail -3

# 前のバージョンをチェックアウト
git checkout v1.x.x-previous

# Google Play でのロールバック
# Play Console > 本番環境 > "ロールアウト中止"
# 前のバージョンを手動で再度アップロード

# App Store でのロールバック
# App Store Connect > MyApps > 削除する予定のバージョン > "このバージョンを削除"
# 前のバージョンを再度アップロード
```

---

## GitHub Actions によるリリース自動化

**ファイル**: `.github/workflows/release.yml`

```yaml
name: Release to Production

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., 1.0.1)'
        required: true

jobs:
  build-and-release:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x.x'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Build Android AAB
        run: |
          flutter build appbundle \
            --release \
            --build-number=${{ github.run_number }}
        env:
          KEYSTORE_PATH: ${{ secrets.KEYSTORE_PATH }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
      
      - name: Build iOS
        run: |
          flutter build ios --release \
            --build-number=${{ github.run_number }}
      
      - name: Upload to Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: jp.petitworks.shougaku_kore_doutoku
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production
          userFraction: 0.25  # 25% ロールアウト
      
      - name: Create GitHub Release
        uses: actions/create-release@v1
        with:
          tag_name: v${{ github.event.inputs.version }}
          release_name: Release v${{ github.event.inputs.version }}
          body_path: docs/RELEASE_NOTES_${{ github.event.inputs.version }}.md
```

---

## 参考資料

- [Google Play コンソール ヘルプ](https://support.google.com/googleplay/android-developer)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect)
- [Flutter 本番ガイド](https://flutter.dev/docs/deployment)
- [docs/HOTFIX_RESPONSE_PLAN.md](HOTFIX_RESPONSE_PLAN.md)
- [docs/PRODUCTION_MONITORING_SETUP.md](PRODUCTION_MONITORING_SETUP.md)
