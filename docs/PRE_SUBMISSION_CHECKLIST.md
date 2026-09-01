# 申請前チェックリスト

小学コレ！道徳の App Store・Google Play 申請前の最終確認事項です。このリストをすべて完了してから申請を開始してください。

## 概要

このチェックリストは以下の段階に分かれています:

1. **準備フェーズ（1 週間前）**: 基本設定・メタデータ入力
2. **テストフェーズ（3～7 日前）**: 内部・外部テスト実施
3. **最終確認フェーズ（申請 1 日前）**: 最後の確認・修正
4. **申請フェーズ（申請当日）**: 申請手続き実行

---

## Phase 1: 準備フェーズ（1 週間前）

### 1-1: アカウント・環境整備

- [ ] **Apple Developer Program**
  - [ ] 登録完了（年額 $99 支払い済み）
  - [ ] Certificates, Identifiers & Profiles 設定済み
  - [ ] Provisioning Profile が Xcode に登録済み
  - [ ] Team ID が確認済み

- [ ] **Google Play Developer Account**
  - [ ] 登録完了（$25 支払い済み）
  - [ ] 税金・銀行口座情報が入力済み
  - [ ] デベロッパー情報が完成
  - [ ] Bundle ID が登録済み

- [ ] **Firebase 環境**
  - [ ] Firebase Project が作成済み
  - [ ] iOS・Android アプリが登録済み
  - [ ] サービスアカウント JSON ダウンロード済み
  - [ ] 本番環境の認証設定完了

### 1-2: ビルド・署名設定

- [ ] **iOS 署名設定**
  - [ ] Apple Distribution Certificate 取得済み
  - [ ] App ID 登録完了（Bundle ID: jp.petitworks.shougaku-kore-doutoku）
  - [ ] App Store Provisioning Profile 生成・登録済み
  - [ ] Xcode の Signing & Capabilities で正しい Team・Profile が設定済み

- [ ] **Android 署名設定**
  - [ ] Release キーストア作成済み
  - [ ] キーストアパスワード・キー別名・キーパスワード が記録済み
  - [ ] build.gradle で signingConfigs 設定済み
  - [ ] keystore.jks が安全に保管済み

### 1-3: メタデータ入力（Google Play）

- [ ] **基本情報**
  - [ ] アプリ名: 小学コレ！道徳
  - [ ] デベロッパー名: [正式名称]
  - [ ] サポートメール: support@shougaku-kore.jp
  - [ ] デフォルト言語: 日本語

- [ ] **ストア掲載情報**
  - [ ] 短い説明: 「親向けレポートで成長が見える、小学生の道徳学習アプリ」
  - [ ] 詳細な説明: 400～450 文字、機能説明・対象層・料金明記
  - [ ] プライバシーポリシー URL: https://shougaku-kore.jp/privacy
  - [ ] サポート URL: https://shougaku-kore.jp/support
  - [ ] メールアドレス: support@shougaku-kore.jp

- [ ] **商品登録（In-App Products）**
  - [ ] 月額プラン
    - [ ] 商品 ID: monthly_subscription
    - [ ] 商品名: 月額プラン
    - [ ] 説明: すべてのストーリーと月次成長レポートにアクセス
    - [ ] 価格: ¥500/月
    - [ ] トライアル期間: 14 日（無料）
  - [ ] 年額プラン（オプション）
    - [ ] 商品 ID: yearly_subscription
    - [ ] 商品名: 年額プラン
    - [ ] 説明: すべてのストーリーと月次成長レポートに1年間アクセス
    - [ ] 価格: ¥4,900/年
    - [ ] トライアル期間: 14 日（無料）

- [ ] **コンテンツレーティング**
  - [ ] Google Play コンテンツレーティング質問票完了
  - [ ] 広告: 有（In-App Purchase）
  - [ ] 暴力・性的コンテンツ: なし
  - [ ] 自動計算レーティング確認（通常 4+ または 7+）

- [ ] **プライバシー・セキュリティ**
  - [ ] プライバシーポリシー URL が機能（アクセス可能）
  - [ ] Data Safety が完全に入力済み
    - [ ] 収集データ: ユーザー ID（匿名化）、学年
    - [ ] 子どもに関連: はい
    - [ ] COPPA 準拠: はい
    - [ ] 第三者共有: いいえ
    - [ ] 暗号化: はい

### 1-4: メタデータ入力（App Store）

- [ ] **基本情報**
  - [ ] アプリ名: 小学コレ！道徳
  - [ ] プライマリ言語: 日本語
  - [ ] Bundle ID: jp.petitworks.shougaku-kore-doutoku
  - [ ] SKU: ShougakuKoreDotoku_001

- [ ] **ストア情報**
  - [ ] Subtitle: 親向けレポートで成長を見守る
  - [ ] Short Description: 「親向けレポートで成長が見える、小学生の道徳学習アプリ」
  - [ ] Full Description: 
    - [ ] 機能説明（3 要素以上）
    - [ ] 対象層明記
    - [ ] 料金プラン明記
    - [ ] COPPA 準拠明記
  - [ ] Keywords: 道徳, 小学生, 親向け, 成長レポート, 教育アプリ, 判断力
  - [ ] Support URL: https://shougaku-kore.jp/support
  - [ ] Privacy Policy URL: https://shougaku-kore.jp/privacy
  - [ ] Primary Category: Education

- [ ] **In-App Purchase 登録**
  - [ ] Subscription Group 作成: Main Subscription
  - [ ] 月額プラン
    - [ ] Product ID: monthly_subscription
    - [ ] Display Name: 月額プラン
    - [ ] Description: すべてのストーリーと月次成長レポートにアクセス可能
    - [ ] Duration: 1 month
    - [ ] Trial Duration: 14 days
    - [ ] Trial Price: 無料
    - [ ] Price Tier: 480（≈ ¥500）
  - [ ] 年額プラン
    - [ ] Product ID: yearly_subscription
    - [ ] Display Name: 年額プラン
    - [ ] Description: すべてのストーリーと月次成長レポートに1年間アクセス可能
    - [ ] Duration: 1 year
    - [ ] Trial Duration: 14 days
    - [ ] Price Tier: 4800（≈ ¥4,900）

- [ ] **Age Rating**
  - [ ] Content Rating 質問票完了
  - [ ] 最終レーティング: 4+（全年齢）

- [ ] **App Privacy**
  - [ ] Data Types:
    - [ ] User ID: ✓ 収集, ✓ リンク可能, App Functionality
    - [ ] Name: ✓ 収集, ✓ リンク可能, App Functionality
    - [ ] Grade: ✓ 収集, ✓ リンク可能, App Functionality
    - [ ] Crashes: ✓ 収集, リンク不可, App Support
  - [ ] Tracking: なし
  - [ ] Third-Party Sharing: なし

---

## Phase 2: テストフェーズ（3～7 日前）

### 2-1: TestFlight（Apple）テスト

- [ ] **ビルドアップロード**
  - [ ] iOS ビルド成功（flutter build ios --release）
  - [ ] App Store Connect でビルドアップロード完了
  - [ ] ビルドが Processing 完了 → Ready for TestFlight 状態
  - [ ] ビルド番号確認（例: v1.0.0）

- [ ] **Internal Testing**
  - [ ] Internal Testers に配信
  - [ ] 3～5 人の内部テスター確認
  - [ ] テスト期間: 最低 3 日以上

- [ ] **External Testing**（推奨）
  - [ ] External Testers を 10 人以上追加
  - [ ] Beta App Review 情報入力完了
  - [ ] Apple 審査完了（1～3 日）
  - [ ] テスター群に配信開始
  - [ ] テスト期間: 1～2 週間

- [ ] **テスト実施**
  - [ ] ホーム画面動作確認: ✓
  - [ ] ストーリー選択・読了: ✓
  - [ ] バッジシステム: ✓
  - [ ] サブスクリプション試用: ✓
  - [ ] 月次レポート表示: ✓
  - [ ] オフライン機能: ✓
  - [ ] クラッシュなし: ✓
  - [ ] 起動時間 3 秒以内: ✓

- [ ] **テスターフィードバック**
  - [ ] フィードバック収集完了
  - [ ] 高優先度バグすべて修正
  - [ ] テスター了承メッセージ受領: ✓

### 2-2: Google Play 内部テスト

- [ ] **ビルドアップロード**
  - [ ] Android ビルド成功（flutter build appbundle --release）
  - [ ] Google Play Console でビルドアップロード完了
  - [ ] ビルド番号確認（例: v1.0.0-internal-001）

- [ ] **Internal Testing**
  - [ ] Internal Testers 招待リンク生成
  - [ ] テスター 5～10 人追加
  - [ ] テスト期間: 最低 3 日以上

- [ ] **テスト実施**
  - [ ] ホーム画面動作確認: ✓
  - [ ] ストーリー選択・読了: ✓
  - [ ] バッジシステム: ✓
  - [ ] サブスクリプション試用: ✓
  - [ ] 月次レポート表示: ✓
  - [ ] オフライン機能: ✓
  - [ ] クラッシュなし: ✓
  - [ ] 複数デバイスで確認（Pixel 6a, Galaxy A52 など）

- [ ] **テスターフィードバック**
  - [ ] フィードバック収集完了（Google Forms など）
  - [ ] 高優先度バグすべて修正
  - [ ] テスター確認完了: ✓

### 2-3: バグ・クラッシュ確認

- [ ] **クラッシュレポート**
  - [ ] TestFlight Crashes: 0
  - [ ] Google Play Crashes: 0
  - [ ] Android Vitals ANR: 0

- [ ] **ネットワーク接続**
  - [ ] インターネット接続なし時の処理確認
  - [ ] 接続復帰時のデータ同期確認
  - [ ] エラーメッセージが適切に表示される

- [ ] **データ保存・読み込み**
  - [ ] 設定が保存される
  - [ ] アプリ再起動後も設定が復帰
  - [ ] 選択履歴が正しく保存される

---

## Phase 3: 最終確認フェーズ（申請 1 日前）

### 3-1: ビジュアルアセット確認

- [ ] **App Store スクリーンショット**
  - [ ] iPhone 6.7" スクリーンショット: 5 枚 ✓
    - [ ] 解像度: 1290 x 2796 px
    - [ ] PNG 形式
    - [ ] テキストオーバーレイあり
    - [ ] ファイルサイズ: 1～2 MB 以下
  - [ ] iPad 12.9" スクリーンショット（オプション）: 5 枚
    - [ ] 解像度: 2048 x 2732 px

- [ ] **Google Play スクリーンショット**
  - [ ] 1080 x 1920 px: 6-8 枚 ✓
    - [ ] PNG 形式
    - [ ] テキストオーバーレイあり
  - [ ] Google Play フィーチャーグラフィック: 1 枚
    - [ ] 解像度: 1024 x 500 px
    - [ ] PNG 形式

- [ ] **アプリアイコン**
  - [ ] App Store: 1024 x 1024 pt（PNG、透明背景）✓
  - [ ] Google Play: 512 x 512 px（PNG、背景あり）✓
  - [ ] 複数サイズでテスト（192 x 192 px で確認）

- [ ] **プレビュー動画（App Store、オプション）**
  - [ ] 形式: MP4（H.264 + AAC）
  - [ ] 解像度: 1290 x 2796 px
  - [ ] 長さ: 15～30 秒
  - [ ] ビットレート: 10～25 Mbps

### 3-2: メタデータ最終チェック

- [ ] **Google Play**
  - [ ] 短い説明: 必須、80 文字以下 ✓
  - [ ] 詳細な説明: 必須、4000 文字以下 ✓
  - [ ] すべての説明文に誤字・脱字なし: ✓
  - [ ] プライバシーポリシー URL リンク確認: ✓
  - [ ] サポート URL リンク確認: ✓
  - [ ] メールアドレス有効: ✓
  - [ ] 料金表示明確: ✓
  - [ ] COPPA 準拠表示あり: ✓

- [ ] **App Store**
  - [ ] Subtitle: 必須、30 文字以下 ✓
  - [ ] Short Description: 必須、30 文字以下 ✓
  - [ ] Full Description: 必須、4000 文字以下 ✓
  - [ ] Keywords: 必須、100 文字以下 ✓
  - [ ] すべてのテキストに誤字・脱字なし: ✓
  - [ ] プライバシーポリシー URL リンク確認: ✓
  - [ ] サポート URL リンク確認: ✓
  - [ ] 料金表示明確: ✓
  - [ ] COPPA 準拠表示あり: ✓

### 3-3: In-App Purchase 確認

- [ ] **Google Play**
  - [ ] 月額プラン登録完了
    - [ ] 商品 ID: monthly_subscription
    - [ ] 価格: ¥500/月
    - [ ] トライアル: 14 日無料
    - [ ] 説明: 明확 ✓
  - [ ] 年額プラン登録完了（オプション）
    - [ ] 商品 ID: yearly_subscription
    - [ ] 価格: ¥4,900/年
    - [ ] トライアル: 14 日無料

- [ ] **App Store**
  - [ ] Subscription Group: Main Subscription
  - [ ] 月額プラン
    - [ ] Product ID: monthly_subscription
    - [ ] Display Name: 月額プラン
    - [ ] Trial: 14 days (free)
    - [ ] Price: Tier 480
  - [ ] 年額プラン
    - [ ] Product ID: yearly_subscription
    - [ ] Display Name: 年額プラン
    - [ ] Trial: 14 days (free)
    - [ ] Price: Tier 4800

### 3-4: プライバシー・セキュリティ確認

- [ ] **Web サイト**
  - [ ] プライバシーポリシーページ
    - [ ] URL: https://shougaku-kore.jp/privacy
    - [ ] アクセス可能: ✓
    - [ ] 日本語表記: ✓
    - [ ] 以下を明記:
      - [ ] 子ども向けアプリであること
      - [ ] COPPA 準拠
      - [ ] 収集データ（ユーザー ID、学年）
      - [ ] データ暗号化
      - [ ] 第三者共有なし
      - [ ] 親による同意メカニズム
  - [ ] サポートページ
    - [ ] URL: https://shougaku-kore.jp/support
    - [ ] アクセス可能: ✓
    - [ ] 問い合わせ方法明記: ✓

- [ ] **アプリケーション**
  - [ ] HTTPS 通信確認: ✓
  - [ ] ローカルデータ暗号化: ✓
  - [ ] プライバシーポリシーリンク表示: ✓
  - [ ] 親向け同意画面実装: ✓
  - [ ] COPPA 関連警告表示: ✓

### 3-5: コンテンツレーティング最終確認

- [ ] **Google Play**
  - [ ] 自動計算レーティング: 4+ または 7+ ✓
  - [ ] 該当する警告なし: ✓

- [ ] **App Store**
  - [ ] Age Rating: 4+ ✓
  - [ ] 該当する警告なし: ✓

### 3-6: リリースノート準備

- [ ] **Google Play リリースノート**
  ```
  小学コレ！道徳 v1.0.0 リリース
  
  【主な機能】
  - 日常のジレンマを体験できるストーリー学習
  - 月1回の親向け成長レポート
  - 楽しいバッジシステム
  - オフライン対応
  
  ご質問やご意見は support@shougaku-kore.jp までお気軽にお問い合わせください。
  ```

- [ ] **App Store リリースノート**
  ```
  Version 1.0.0 初版リリース
  
  小学生の判断力・共感力を育むストーリー学習アプリです。
  
  主な機能:
  • 日常のジレンマを選択肢で体験
  • 月1回の親向け成長レポート
  • バッジシステムで継続をサポート
  • オフライン対応
  ```

---

## Phase 4: 申請フェーズ（申請当日）

### 4-1: 申請前の最終準備

- [ ] **環境確認**
  - [ ] インターネット接続良好: ✓
  - [ ] Apple ID・Google Account ログイン確認: ✓
  - [ ] 必要なファイルが手元にある:
    - [ ] iOS App Bundle / IPA
    - [ ] Android App Bundle
    - [ ] スクリーンショット・画像
    - [ ] プライバシーポリシー URL

- [ ] **時間確保**
  - [ ] 申請に最低 1～2 時間確保
  - [ ] 集中できる環境: ✓

### 4-2: Google Play 申請

1. **Google Play Console にログイン**
   - [ ] 正しいアカウントでログイン

2. **本番環境用ビルド準備**
   - [ ] 「新しいリリースを作成」をクリック
   - [ ] App Bundle をアップロード
   - [ ] リリース名: v1.0.0
   - [ ] リリースノート入力

3. **最終チェック**
   - [ ] すべてのメタデータが表示される: ✓
   - [ ] スクリーンショットが表示される: ✓
   - [ ] 価格・トライアル期間が正しい: ✓
   - [ ] プライバシーポリシー・サポート URL が表示される: ✓

4. **申請実行**
   - [ ] 「審査に提出」をクリック
   - [ ] 確認ダイアログで「確定」をクリック
   - [ ] 申請メール受信確認

### 4-3: App Store 申請

1. **App Store Connect にログイン**
   - [ ] 正しいアカウントでログイン

2. **本番環境用ビルド選択**
   - [ ] TestFlight でテストされたビルドを選択
   - [ ] ビルド ID 確認（例: v1.0.0）

3. **最終チェック**
   - [ ] すべてのメタデータが表示される: ✓
   - [ ] スクリーンショットが表示される: ✓
   - [ ] In-App Purchase が表示される: ✓
   - [ ] Age Rating が 4+ である: ✓
   - [ ] App Privacy が完全に入力されている: ✓

4. **申請実行**
   - [ ] 「Submit for Review」をクリック
   - [ ] 各質問に回答:
     - [ ] Export Compliance: No
     - [ ] IDFA: No
     - [ ] Content Rights: Yes, does not contain third-party content
     - [ ] Medical: No
     - [ ] Kids Category: Yes
   - [ ] 「Submit」をクリック
   - [ ] 申請メール受信確認

### 4-4: 申請後の確認

- [ ] **Google Play**
  - [ ] ステータス: 「In Review」に変更されたことを確認: ✓
  - [ ] メールで申請受領通知受信: ✓
  - [ ] 申請日時: ___ 年 ___ 月 ___ 日

- [ ] **App Store**
  - [ ] ステータス: 「Waiting for Review」に変更されたことを確認: ✓
  - [ ] メールで申請受領通知受信: ✓
  - [ ] 申請日時: ___ 年 ___ 月 ___ 日

---

## 審査結果追跡

### Google Play 審査結果

| 日付 | 時刻 | ステータス | メモ |
|------|------|----------|------|
| 申請日 | | In Review | 申請完了 |
| | | In Review | 確認中... |
| | | In Review | 確認中... |
| 審査日 | | ✓ Approved / ✗ Rejected | |

### App Store 審査結果

| 日付 | 時刻 | ステータス | メモ |
|------|------|----------|------|
| 申請日 | | Waiting for Review | 申請完了 |
| | | In Review | 確認中... |
| | | In Review | 確認中... |
| 審査日 | | ✓ Approved / ✗ Rejected | |

---

## 審査落ちた場合の対応

もし審査が落ちた場合、以下の手順に従い対応します:

1. **落ちた理由を分析**
   - Apple / Google からのメール内容確認
   - 一般的な落ち理由: [APP_REVIEW_RESPONSE_GUIDE.md 参照]

2. **該当部分を修正**
   - コード修正 / メタデータ修正 / 画像修正など

3. **修正ビルドをアップロード**
   - 新しいビルド番号で再申請

4. **Apple / Google に回答**
   - 修正内容を説明するメッセージを送付

5. **再申請**
   - 修正ビルドで再度「Submit for Review」

---

## 最終署名チェック

申請前に必ず以下を確認してください:

### iOS（App Store）

```bash
# ビルド署名確認
codesign -d -v "build/ios/Release-iphoneos/Runner.app"

# 出力例:
# Code=valid on disk (as-is)
# Executable=/path/to/Runner
# Identifier=jp.petitworks.shougaku-kore-doutoku
# ...
```

### Android（Google Play）

```bash
# App Bundle 署名確認
bundletool verify-bundle --bundle-path="app-release.aab"

# 出力例:
# Verifying signature of APKs...
# All APKs signature verified.
```

---

## よくある確認ミス

| ミス | 症状 | 対応 |
|------|------|------|
| Bundle ID の不一致 | アップロード時にエラー | 登録 ID と一致することを確認 |
| Provisioning Profile の期限切れ | 署名エラー | Xcode で自動更新、または手動更新 |
| データセーフティ未入力 | Google Play でエラー | App Privacy 完全入力 |
| プライバシーポリシー URL 無効 | リンク切れ | URL アクセス確認 |
| スクリーンショット解像度誤り | アップロード拒否 | 正確な解像度で再作成 |
| COPPA 準拠表示なし | 審査落ち | メタデータに COPPA 準拠を明記 |

---

## チェックリスト署名

このチェックリストをすべて完了したら、以下に署名してください:

**確認者名**: _________________________
**確認日**: ___ 年 ___ 月 ___ 日
**署名**: _________________________

**承認者名**: _________________________
**承認日**: ___ 年 ___ 月 ___ 日
**署名**: _________________________

---

**最終更新日**: 2026-09-01
**ステータス**: ドラフト
