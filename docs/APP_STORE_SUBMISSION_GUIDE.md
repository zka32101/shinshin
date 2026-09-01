# App Store 申請ガイド

小学コレ！道徳を Apple App Store で申請・公開するための詳細なステップバイステップガイドです。

## 目次
1. [事前準備](#事前準備)
2. [Apple Developer アカウント設定](#apple-developer-アカウント設定)
3. [App ID 登録](#app-id-登録)
4. [サブスクリプション商品登録](#サブスクリプション商品登録)
5. [アプリケーション情報の入力](#アプリケーション情報の入力)
6. [スクリーンショット・プレビュー](#スクリーンショットプレビュー)
7. [価格・配布](#価格配布)
8. [TestFlight 配信](#testflight-配信)
9. [審査申請](#審査申請)
10. [公開](#公開)

---

## 事前準備

### 必要な情報・ファイル

- [ ] Apple Developer Program 登録（年額 $99）
- [ ] Bundle ID: `jp.petitworks.shougaku-kore-doutoku`
- [ ] 署名付きの IPA / XCArchive ファイル
- [ ] App Store Connect 管理者アカウント
- [ ] iOS アプリアイコン（1024x1024 pt、PNG形式）
- [ ] スクリーンショット
  - iPhone: 5.5" (iPhone 8 Plus) 推奨、または 6.7" (iPhone 14 Pro Max)
  - iPad: 12.9" (iPad Pro) 推奨
- [ ] プレビュー動画（オプション）
- [ ] プライバシーポリシー URL
- [ ] サポート URL
- [ ] メール連絡先

### iOS Development Team Identifier

```bash
# チーム ID を確認
security find-identity -v -p codesigning | grep "iPhone Developer"

# または Xcode から確認
Xcode > Preferences > Accounts > Team ID
```

---

## Apple Developer アカウント設定

### ステップ 1: Apple Developer Program の登録

1. **Apple Developer Program に登録**
   - URL: https://developer.apple.com/programs
   - メールアドレス、パスワード、セキュリティ質問を入力

2. **組織情報を入力**
   - 名前（個人またはビジネス）
   - 所在地
   - ビジネスカテゴリ

3. **登録料金を支払い**
   - 年額 $99
   - Apple ID で支払い処理

### ステップ 2: Certificates、Identifiers & Profiles の設定

1. **App Store Connect にログイン**
   - URL: https://appstoreconnect.apple.com

2. **「Certificates, Identifiers & Profiles」を選択**

3. **Certificates の登録**
   - 「Certificates」→「iOS App Development」
   - または「Apple Distribution」を選択
   - CSR ファイルをアップロード
   - ダウンロードして Keychain に追加

4. **Identifier（App ID）の登録**
   - [次のステップで詳述]

---

## App ID 登録

### ステップ 1: App ID の登録

1. **Apple Developer Account > Certificates, Identifiers & Profiles**

2. **「Identifiers」をクリック**

3. **「App IDs」を選択**

4. **「Register an App ID」をクリック**

5. **App ID の詳細を入力**
   - **Name**: Shougaku Kore Dotoku
   - **Bundle ID**: jp.petitworks.shougaku-kore-doutoku（Explicit ID）
   - **Description**: 小学コレ！道徳

6. **Capabilities を選択**
   - Push Notifications: ✓ チェック（親向けレポート通知用）
   - In-App Purchase: ✓ チェック（サブスクリプション用）
   - Sign in with Apple: （必要に応じて）

7. **「Continue」→「Register」をクリック**

### ステップ 2: Provisioning Profile の生成

1. **「Provisioning Profiles」→「App Store」をクリック**

2. **「Register a New Provisioning Profile」**

3. **App ID を選択**
   - `jp.petitworks.shougaku-kore-doutoku` を選択

4. **Certificates を選択**
   - 事前に登録した Apple Distribution Certificate を選択

5. **Devices を選択**
   - App Store 配信の場合は不要（スキップ）

6. **Provisioning Profile 名を入力**
   - `ShougakuKoreDotoku_AppStore`

7. **「Generate」→「Download」**

8. **Xcode に登録**
   - ダウンロードした `.mobileprovision` ファイルをダブルクリック
   - または Xcode > Preferences > Accounts から登録

---

## サブスクリプション商品登録

### ステップ 1: In-App Purchase 商品の登録

1. **App Store Connect にログイン**
   - https://appstoreconnect.apple.com

2. **「My Apps」をクリック**

3. **アプリケーション名を作成（まだ詳細を入力しない）**
   - 後述のステップで作成します

4. **アプリが作成されたら「In-App Purchase」を開く**

### ステップ 2: 月額サブスクリプション商品の登録

1. **「In-App Purchase」を選択**

2. **「Create a Subscription Group」をクリック**
   - **名前**: Main Subscription
   - **説明**: 主なサブスクリプション（月額・年額）

3. **「Create an Auto-Renewable Subscription」をクリック**

4. **基本情報を入力**
   - **Reference Name**: Monthly Subscription
   - **Product ID**: `monthly_subscription`
   - **Subscription Group**: Main Subscription（上記で作成したグループ）

5. **ローカライズ情報を入力**
   - **言語**: Japanese
   - **Display Name**: 月額プラン
   - **Description**: すべてのストーリーと月次成長レポートにアクセス可能

6. **Subscription Duration を設定**
   - **Duration**: 1 month
   - **Renewal Type**: Automatic (Standard Subscription)

7. **トライアル期間を設定**
   - **Free Trial Duration**: 14 days
   - **Renewal Period**: 1 month

8. **価格を設定**
   - **Price Tier**: Tier 480（≈ ¥500）
   - 各地域の価格は自動換算されます

9. **「Save」をクリック**

### ステップ 3: 年額サブスクリプション商品の登録

1. **同じ Subscription Group 内で「Create an Auto-Renewable Subscription」**

2. **基本情報を入力**
   - **Reference Name**: Yearly Subscription
   - **Product ID**: `yearly_subscription`
   - **Subscription Group**: Main Subscription

3. **ローカライズ情報を入力**
   - **言語**: Japanese
   - **Display Name**: 年額プラン
   - **Description**: すべてのストーリーと月次成長レポートに1年間アクセス可能

4. **Subscription Duration を設定**
   - **Duration**: 1 year
   - **Renewal Type**: Automatic (Standard Subscription)

5. **トライアル期間を設定**
   - **Free Trial Duration**: 14 days
   - **Renewal Period**: 1 year

6. **価格を設定**
   - **Price Tier**: Tier 4800（≈ ¥4,900）

7. **「Save」をクリック**

---

## アプリケーション情報の入力

### ステップ 1: App Store Connect でアプリを作成

1. **「My Apps」→「+ New App」をクリック**

2. **基本情報を入力**
   - **Name**: 小学コレ！道徳
   - **Primary Language**: Japanese
   - **Bundle ID**: jp.petitworks.shougaku-kore-doutoku（事前に登録した ID）
   - **SKU**: ShougakuKoreDotoku_001（ユニークな ID、変更不可）

3. **「Create」をクリック**

### ステップ 2: アプリ情報の入力

**位置**: App Store Connect → アプリ情報

1. **Subtitle（字幕）**
   - 最大 30 文字
   - 例: 親向けレポートで成長を見守る

2. **Privacy Policy URL**
   - https://shougaku-kore.jp/privacy
   - または https://shougaku-kore.jp/docs/privacy-policy.html

3. **Support URL**
   - https://shougaku-kore.jp/support
   - または contact@shougaku-kore.jp

4. **App Support Email**
   - support@shougaku-kore.jp

5. **Category**
   - **Primary**: Education
   - **Secondary**: Games（オプション）

6. **Content Rights**
   - 「This app does not contain, use, or reference third-party content.」を選択

### ステップ 3: 説明文の入力

**位置**: App Store Connect → ストア → App Store > 説明

1. **Brief Description（短い説明）**
   - 最大 30 文字
   - 例: 親向けレポートで成長を見守る

2. **Full Description（詳細な説明）**
   - 最大 4,000 文字
   - Markdown は使用不可

   ```
   【小学コレ！道徳について】
   毎日のジレンマを選択肢で体験。判断力・共感力を育みます。
   
   【主な機能】
   ◆ 日常のジレンマを選択肢型ストーリーで体験
   友達関係、家族の問題、学校での出来事など、小学生が実際に直面する場面を再現します。
   
   ◆ 月1回の親向け成長レポート
   子どもの選択パターンから「判断力」「共感力」「主体性」などを分析。成長曲線で月ごとの変化を見守れます。
   
   ◆ 楽しいバッジシステム
   ストーリー完了でバッジを獲得。学習のモチベーションを維持します。
   
   ◆ オフライン対応
   インターネット接続がない場所でもストーリーを読むことができます。
   
   【推奨対象】
   - 小学3～4年生のお子さんを持つ保護者
   - お子さんの社会性・倫理観の発達を見守りたい方
   
   【プライバシー・セキュリティ】
   - 子どもの個人情報は最小化（名前・学年のみ）
   - 親による同意メカニズムを実装
   - 保護者への管理ツール完備
   
   【料金プラン】
   - トライアル期間: 初回14日間無料
   - 月額: ¥500/月
   - 年額: ¥4,900/年
   - キャンセルはいつでも可能
   
   ご質問やご意見は support@shougaku-kore.jp までお気軽にお問い合わせください。
   ```

3. **Keywords（キーワード）**
   - 最大 100 文字（カンマ区切り）
   - 例: 道徳, 小学生, 親向け, 成長レポート, 教育アプリ, 判断力

4. **Release Notes（リリースノート）**
   - 例: Version 1.0.0 初版リリース

---

## スクリーンショット・プレビュー

### ステップ 1: スクリーンショットの仕様

**位置**: App Store Connect → ストア → App Store > スクリーンショット

iOS App Store の画面サイズ別スクリーンショット要件:

| デバイス | サイズ | アスペクト比 |
|---------|-------|-----------|
| iPhone 6.7" (14 Pro Max) | 1290 x 2796 px | 19.5:9 |
| iPhone 5.5" (8 Plus) | 1242 x 2208 px | 9:16 |
| iPad Pro 12.9" | 2048 x 2732 px | 4:3 |

**推奨**: iPhone 6.7" (最新モデル) で作成

### ステップ 2: スクリーンショット作成手順

1. **iOS Simulator で確認**
   ```bash
   flutter run -d iphone
   ```

2. **スクリーンショット撮影**
   - Simulator: ⌘ + S（スクリーンショット）
   - または、Xcode の Simulator > Device > Screenshot

3. **テキストオーバーレイを追加**
   - Figma、Sketch、またはコマンドラインツール（ImageMagick）を使用
   - フォント: SF Pro Display（システムフォント）
   - サイズ: 56-64 pt
   - 色: 白、黒、アプリカラーに応じて調整

### ステップ 3: 推奨スクリーンショット構成

| 順序 | スクリーンショット | タイトル |
|------|-------------------|----------|
| 1 | ホーム画面 | 毎日のジレンマで判断力を育む |
| 2 | ストーリー一覧 | 日常のジレンマを体験 |
| 3 | ストーリー読了画面 | 選択肢から判断力を養う |
| 4 | 親向けレポート | 月次成長レポートで見守る |
| 5 | バッジ画面（オプション） | 楽しいバッジで継続をサポート |

### ステップ 4: スクリーンショットをアップロード

1. **「スクリーンショット」をクリック**

2. **iPhone 6.7" のスクリーンショットを選択**
   - 5 枚を上記の推奨順で追加

3. **iPad Pro のスクリーンショット（オプション）**
   - iPad ユーザーにもアピール
   - iPhone と同じ 5 枚の構成で OK

4. **「Save」をクリック**

### ステップ 5: プレビュー動画（オプション）

1. **動画仕様**
   - 形式: MP4（H.264 コーデック）
   - 長さ: 15～30 秒
   - 解像度: 1290 x 2796 px（6.7" サイズに合わせる）
   - ファイルサイズ: 500 MB 以下

2. **動画コンテンツ（推奨）**
   - アプリロゴ＆タイトル表示（3 秒）
   - ホーム画面デモ（5 秒）
   - ストーリー体験デモ（5 秒）
   - レポート表示デモ（5 秒）
   - バッジ・達成感表現（2 秒）
   - CTA: 「今すぐダウンロード」（1 秒）

3. **アップロード**
   - App Store Connect → プレビュー動画をアップロード

---

## 価格・配布

### ステップ 1: 価格と配布情報

**位置**: App Store Connect → ストア → App Store > 価格と配布

1. **Price Tier**
   - サブスクリプション商品を販売するため、基本は「Free」を選択

2. **Availability**
   - **日本**: ✓ チェック（App Store Japan から配布）
   - 他国: 必要に応じて追加

3. **Content Rights Declaration**
   - 「This app does not contain, use, or reference third-party content.」を選択

4. **Age Rating**
   - 以下のセクションを参照

### ステップ 2: Age Rating 設定

**位置**: App Store Connect → ストア → App Store > 一般情報

1. **「Edit Content Rating」をクリック**

2. **Questionnaire に回答**

   | カテゴリ | 質問 | 回答 |
   |---------|------|------|
   | Violence | 暴力描写 | None |
   | Graphic Violence | グラフィック暴力 | None |
   | Adult Content | 成人コンテンツ | None |
   | Gambling | ギャンブル | None |
   | Drug Use | 薬物使用 | None |
   | Medical Information | 医学情報 | None |
   | Horror/Fear | ホラー | None |
   | Sexual Content | 性的コンテンツ | None |
   | Profanity | 悪言葉 | None |
   | Mature/Suggestive Themes | 成人向けテーマ | None |

3. **「Save」をクリック**

4. **自動計算される Rating を確認**
   - App Store で 4+ (全年齢対象) に分類されることを確認

### ステップ 3: COPPA・プライバシー設定

**位置**: App Store Connect → 一般情報 > App Privacy

1. **「App Privacy」をクリック**

2. **Data Types を記入**

   | データ種 | 収集 | リンク可能 | トラッキング | 用途 |
   |---------|------|-----------|------------|------|
   | User ID | ✓ | ✓ | No | App Functionality |
   | Email Address | - | - | - | - |
   | Name | ✓ | ✓ | No | App Functionality |
   | Grade (学年) | ✓ | ✓ | No | App Functionality |
   | Crashes | ✓ | No | No | App Support |

3. **Third-Party Sharing**
   - 「No」を選択（個人情報を第三者と共有しない）

4. **Tracking**
   - 「No」を選択（ユーザーをトラッキングしない）

5. **Save」をクリック**

---

## TestFlight 配信

### ステップ 1: iOS ビルドの準備

1. **Xcode で署名を設定**
   ```
   Xcode > Signing & Capabilities
   - Team: [登録した Apple Developer Team]
   - Signing Certificate: Apple Distribution
   - Provisioning Profile: ShougakuKoreDotoku_AppStore
   ```

2. **ビルド設定を確認**
   ```
   Build Settings:
   - Code Signing Identity: Apple Distribution
   - Development Team: [Team ID]
   - Provisioning Profile: ShougakuKoreDotoku_AppStore
   ```

3. **ビルドをアーカイブ**
   ```bash
   flutter build ios --release
   ```

   または Xcode から:
   ```
   Product > Archive
   ```

### ステップ 2: Transporter でビルドをアップロード

1. **App Store Connect から Transporter をダウンロード**
   - 自動的に Mac にインストールされる場合もあります

2. **XCArchive → IPA に変換**
   - Xcode: Window > Organizer > Archives
   - 「Distribute App」をクリック
   - 「App Store Connect」を選択
   - 「Upload」をクリック

   または、コマンドラインから:
   ```bash
   xcodebuild -exportArchive \
     -archivePath "path/to/archive.xcarchive" \
     -exportPath "path/to/export" \
     -exportOptionsPlist "exportOptions.plist"
   ```

3. **IPA ファイルが生成されたことを確認**

### ステップ 3: TestFlight に配信

1. **App Store Connect でビルドを確認**
   - ビルドが Processing 中であることを確認
   - 処理完了待ち（通常 10～20 分）

2. **Build が Ready for TestFlight になったことを確認**
   - App Store Connect → Builds → Build number

3. **Internal Testers にリリース**
   - 「TestFlight」→「Internal Testing」をクリック
   - ビルドを選択
   - Testers 一覧を編集
   - 「Save」をクリック

4. **テスター招待メールが送信される**
   - テスターが TestFlight アプリをインストール
   - アプリをテストできるようになる

### ステップ 4: External Testers に配信（オプション）

1. **「External Testing」をクリック**

2. **Testers を追加**
   - メールアドレスを入力
   - 「Send Invite」をクリック

3. **審査待ち状態に移行**
   - Apple が External Tester ビルドを審査（1～3 日）

4. **「Ready to Test」になったらテスト開始**

---

## 審査申請

### ステップ 1: 審査前の最終チェック

以下のチェックリストを確認してから申請してください:

- [ ] すべてのメタデータが入力済み
- [ ] スクリーンショットがすべての言語・デバイスでアップロード済み
- [ ] プライバシーポリシー・サポート URL が有効
- [ ] Age Rating が適切に設定されている
- [ ] App Privacy が完全に入力されている
- [ ] In-App Purchase（サブスクリプション）が登録されている
- [ ] TestFlight で基本機能が動作確認済み
- [ ] テストから少なくとも 1 週間の期間を設けている
- [ ] ビルドが「Ready for Submission」状態である

詳細は **PRE_SUBMISSION_CHECKLIST.md** を参照してください。

### ステップ 2: ビルドを選択して申請

1. **App Store Connect > Builds > iOS**

2. **最新ビルドを選択**
   - TestFlight で十分にテストされたビルド

3. **「Select a build for this submission」をクリック**
   - ビルドの ITC Identifier を確認

4. **「Save」をクリック**

### ステップ 3: App Store Connect で申請

1. **左側メニュー → 「Submit for Review」**

2. **以下の情報を確認・入力**
   - **Content Rights**: 権利に関する宣言
     - 「This app does not contain, use, or reference third-party content.」を選択
   - **Advertising**: 広告について
     - 「Does this app use advertising?」 → No
   - **Alcohol, Tobacco, Gambling**: 対象外
     - すべて「No」
   - **IDFA（ID for Advertisers）**: トラッキング
     - 「Does this app or its third-party SDK(s) use the Advertising Identifier (IDFA)?」 → No
   - **Medical**: 医療情報
     - 「Does this app contain medical functionality?」 → No
   - **Kids Category**: 子ども向け指定
     - 「Is this app in the Kids Category?」 → Yes
   - **Export Compliance**: 輸出規制
     - 「Is your app designed to use cryptography or does it contain or incorporate cryptography?」 → No
   - **Third Party Content**: 第三者コンテンツ
     - 「Does this app contain, use, or reference third-party content?」 → No

3. **「Submission」セクションで確認**
   - Version number（例: 1.0）
   - Build number
   - Date Available（公開予定日）

4. **「Submit」をクリック**

---

## App Store 審査基準

小学コレ！道徳が特に注意すべき審査基準:

### Kids Category (COPPA)

Apple は Kids Category アプリに厳しい要件を課しています。

**チェック項目**:
- [ ] プライバシーポリシーが完全である
- [ ] App Privacy で すべてのデータが正確に報告されている
- [ ] 子どもに不適切な広告・分析トラッキングがない
- [ ] In-App Purchase が安全に実装されている（誤購入防止など）
- [ ] 親の同意メカニズムが機能している
- [ ] 有害コンテンツが含まれていない
- [ ] リンク先（外部 Web サイト）が子ども向けでない場合は警告表示

### In-App Purchase 関連

- [ ] サブスクリプション説明が明確である
- [ ] キャンセル・解約方法が簡単に見つかる
- [ ] トライアル期間について明確に表示
- [ ] 課金前に確認ダイアログが表示される
- [ ] Refund 請求に対応できる体制がある

### プライバシー・セキュリティ

- [ ] HTTPS 通信を使用している
- [ ] データ暗号化が実装されている
- [ ] App Tracking Transparency (ATT) に準拠している（ユーザー追跡がない）
- [ ] Sign in with Apple の実装（個人情報保護）

---

## 公開

### ステップ 1: 審査結果の確認

1. **App Store Connect で審査状況を確認**
   - 「Submission」セクションを確認
   - ステータス: 「In Review」→「Ready for Sale」

2. **メール通知を受け取る**
   - Apple Developer メールアドレス宛に通知が届きます

### ステップ 2: アプリの公開

**Approved Status になった場合:**

1. **App Store Connect で「Release」をクリック**
   - または、自動公開設定を事前に指定した場合は自動で公開

2. **アプリが App Store に表示されることを確認**
   - 検索で検索可能になるまで数時間～24 時間待つ

3. **URL を取得**
   - App Store Connect > App Information > App URL
   - 例: https://apps.apple.com/jp/app/小学コレ！道徳/id1234567890

### ステップ 3: 公開後の監視

1. **ユーザーレビューを監視**
   - App Store Connect で毎日レビューを確認
   - 低評価の場合は理由を分析・対応

2. **クラッシュレポートを確認**
   - App Store Connect > Metrics > Crashes
   - 異常があれば速やかにホットフィックスをリリース

3. **ユーザー統計を分析**
   - インストール数、アクティブユーザー数、リテンション率を確認
   - 必要に応じてマーケティング施策を調整

---

## トラブルシューティング

### ビルドアップロード時のエラー

| エラー | 原因 | 解決方法 |
|--------|------|---------|
| `Invalid Signature` | 署名が無効 | 署名設定を再確認、再ビルド |
| `Missing provisioning profile` | Provisioning Profile がない | Xcode に .mobileprovision ファイルを登録 |
| `Bundle ID mismatch` | Bundle ID が不一致 | Xcode の Bundle ID を確認 |
| `Bitcode Compilation Error` | bitcode が有効 | Xcode > Build Settings > Bitcode を Disable |

### 審査落ちの一般的な理由

| 理由 | 対応方法 |
|------|---------|
| COPPA 非準拠 | プライバシーポリシーを詳細化、App Privacy を正確に入力 |
| In-App Purchase の説明不足 | サブスクリプション説明の詳細を画面内に表示 |
| 子ども向けコンテンツに不適切な表現 | コンテンツをレビュー、不適切な表現を削除 |
| 誤購入防止機構がない | 親パスワード機能を実装 |
| クラッシュレポート | テストを厳密化、デバッグを実施 |

詳細は **APP_REVIEW_RESPONSE_GUIDE.md** を参照してください。

---

## 参考資料

- Apple Developer Documentation: https://developer.apple.com/documentation/
- App Store Connect Help: https://help.apple.com/app-store-connect/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- COPPA について: https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy
- In-App Purchase: https://developer.apple.com/documentation/storekit

---

## チェックリスト

申請前に必ず確認してください:

- [ ] Apple Developer Program 登録が完了している
- [ ] App ID が正しく登録されている
- [ ] Provisioning Profile が生成・登録されている
- [ ] サブスクリプション商品（月額・年額）が登録されている
- [ ] アプリケーション情報がすべて入力されている
- [ ] スクリーンショット・プレビュー動画がアップロードされている
- [ ] プライバシーポリシー・サポート URL が有効である
- [ ] Age Rating が設定されている
- [ ] App Privacy が完全に入力されている
- [ ] TestFlight で基本機能が動作確認されている
- [ ] ビルドが「Ready for Submission」状態である
- [ ] 申請内容の最終確認が完了している

---

**最終更新日**: 2026-09-01
**ステータス**: ドラフト
**次のステップ**: TestFlight テスト配信開始
