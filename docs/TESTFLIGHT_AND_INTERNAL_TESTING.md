# TestFlight と内部テスト配信ガイド

小学コレ！道徳の App Store (TestFlight) および Google Play (内部テスト) での配信手順書です。

## 目次
1. [概要](#概要)
2. [TestFlight テスト配信（Apple）](#testflight-テスト配信apple)
3. [Google Play 内部テスト配信](#google-play-内部テスト配信)
4. [テスト実施チェックリスト](#テスト実施チェックリスト)
5. [フィードバック収集](#フィードバック収集)

---

## 概要

### テスト配信の目的

本番申請前に、実際のデバイスで以下をテストします:

- [ ] 主要機能が問題なく動作する
- [ ] In-App Purchase（サブスクリプション）が正常に機能する
- [ ] オフライン対応が正常に機能する
- [ ] UI・UX に問題がないか
- [ ] パフォーマンス（起動時間、読み込み時間）に問題がないか
- [ ] 親向けレポート生成が正常に動作する
- [ ] プッシュ通知が正常に機能する（iOS）
- [ ] COPPA・プライバシー対応が適切か

### テスト対象デバイス

| プラットフォーム | デバイス | OS | 数量 |
|-----------------|---------|----|----|
| iOS | iPhone SE（第2世代） | iOS 16.x | 1 |
| iOS | iPhone 14 Pro | iOS 17.x | 1 |
| iOS | iPad（第9世代） | iOS 16.x | 1 |
| Android | Google Pixel 6a | Android 13 | 1 |
| Android | Samsung Galaxy A52 | Android 13 | 1 |

### テスト期間

**推奨**: 2～3 週間

- 第1週: 基本機能テスト（内部テスト）
- 第2週: 詳細テスト・フィードバック対応
- 第3週: 最終確認・バグ修正

---

## TestFlight テスト配信（Apple）

### ステップ 1: Internal Testers への配信

Internal Testers は Apple Developer Team メンバーです。最初は内部テストから開始します。

#### 1-1: ビルドの準備

1. **ビルドがアーカイブされていることを確認**
   ```bash
   flutter build ios --release
   ```

2. **Xcode でアーカイブ**
   ```
   Product > Archive
   ```

3. **Organizer を確認**
   ```
   Window > Organizer > Archives
   ```

#### 1-2: App Store Connect にアップロード

1. **Xcode から自動アップロード**
   - Organizer で Archive を選択
   - 「Distribute App」をクリック
   - 「App Store Connect」を選択
   - 「Upload」をクリック

   または、手動で:

2. **Transporter を使用**
   ```bash
   # IPA に変換
   xcodebuild -exportArchive \
     -archivePath "archive.xcarchive" \
     -exportPath "export" \
     -exportOptionsPlist "exportOptions.plist"
   
   # Transporter でアップロード
   transporter -f "export/Shougaku Kore Dotoku.ipa" \
     -u "your-apple-id@example.com" \
     -p "app-specific-password"
   ```

#### 1-3: App Store Connect で確認

1. **App Store Connect にログイン**
   - https://appstoreconnect.apple.com

2. **「Builds」→「iOS」を確認**
   - ビルドがアップロードされたことを確認
   - ステータス: 「Processing」（数分～数十分待つ）

3. **ビルドが「Ready for TestFlight」になったことを確認**

#### 1-4: Internal Testers に配信

1. **「TestFlight」→「Internal Testing」をクリック**

2. **Testers を確認**
   - デフォルトでは、Developer Team メンバーが登録されている

3. **ビルドを選択**
   - 「Select a build」で最新ビルドを選択

4. **「Save」をクリック**

5. **テスター招待メールが送信される**
   - メールで「Start Testing」リンクを受け取る
   - TestFlight アプリをインストール
   - アプリをダウンロードしてテスト開始

### ステップ 2: External Testers への配信（オプション）

External Testers は外部の選定テスターです。最低 10 人以上推奨。

#### 2-1: External Testers を追加

1. **「External Testing」をクリック**

2. **「Manage Testers」をクリック**

3. **テスターのメールアドレスを入力**
   - 例:
     ```
     tester1@example.com
     tester2@example.com
     tester3@example.com
     （最大 10,000 人）
     ```

4. **「Add」をクリック**

#### 2-2: ビルドを選択して Apple 審査に提出

1. **ビルドを選択**
   - 「Select a build」で最新ビルド選択

2. **Beta App Review 情報を入力**
   - **Account Information**:
     - Email: support@shougaku-kore.jp
     - Phone Number: [登録電話番号]
     - Alternate Contact Email: [代替メール]
   - **Demo Account Information**:
     - Username: test-user@example.com
     - Password: TestPassword123!
     - Description: Test account for evaluating subscription features
   - **Beta App Review Information**:
     - Notes: 
       ```
       This is an educational app for elementary school children (3-4 grade).
       
       Key features to test:
       - Story selection and completion
       - In-App Purchase (subscription trial)
       - Monthly growth report generation
       - Offline story reading
       
       Parental controls and privacy protection are fully COPPA-compliant.
       ```
     - Contact Information: support@shougaku-kore.jp
     - Sign-In Required: ✓ チェック
     - Demo Account: ✓ チェック

3. **「Save」をクリック**

4. **Apple 審査に送信**
   - Apple が 1～3 日で External Testing の可否を審査

5. **「Ready to Test」になったら External Testers に通知**
   - 自動的に招待メールが送信される

### ステップ 3: TestFlight でのテスト実施

#### 3-1: 利用者側の手順

テスターが以下の手順でテストします:

1. **招待メール受け取り**
   - Apple からの招待メール内の「Start Testing」をクリック

2. **TestFlight アプリをインストール**
   - App Store から TestFlight アプリをダウンロード
   - 無料アプリ

3. **アプリをインストール**
   - TestFlight で「小学コレ！道徳」を検索
   - 「Install」をクリック

4. **テストを実施**
   - 機能をテスト
   - フィードバックを入力（TestFlight の Feedback 機能を使用）

#### 3-2: フィードバック方法

1. **TestFlight アプリ内フィードバック**
   - アプリ内: メニュー → 「Send Feedback」
   - またはアプリを揺する（Shake to Feedback）
   - スクリーンショット・テキストコメントを送信

2. **メール/Slack でのフィードバック**
   - テスト専用チャネルを作成
   - リアルタイムでフィードバック共有

---

## Google Play 内部テスト配信

### ステップ 1: ビルドの準備

#### 1-1: App Bundle（AAB）のビルド

```bash
flutter build appbundle --release
```

出力ファイル: `build/app/outputs/bundle/release/app-release.aab`

#### 1-2: 署名の確認

```bash
# 署名情報を確認
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# または、キーストア情報を確認
keytool -list -v -keystore ~/path/to/release.keystore
```

### ステップ 2: Google Play Console にアップロード

#### 2-1: Google Play Console にログイン

1. **Google Play Console にアクセス**
   - https://play.google.com/console

2. **アプリを選択**
   - 「小学コレ！道徳」を選択

#### 2-2: 内部テスト用ビルドをアップロード

1. **「Testing」→「Internal Testing」をクリック**

2. **「Create new release」をクリック**

3. **App Bundle をアップロード**
   - `app-release.aab` ファイルを選択
   - 自動的に署名が検証される

4. **リリース情報を入力**
   - **Release name**: v1.0.0-internal-001
   - **Release notes** (ユーザー向け):
     ```
     小学コレ！道徳 v1.0.0 内部テストビルド
     
     【テスト対象機能】
     - ホーム画面・ストーリー選択
     - ストーリー学習・選択肢体験
     - バッジシステム
     - サブスクリプション（トライアル機能）
     - 月次成長レポート
     - オフライン読み込み
     
     ご質問やフィードバックは support@shougaku-kore.jp までお願いします。
     ```

5. **「Save」をクリック**

6. **「Review release」をクリック**

7. **「Start rollout to Internal Testing」をクリック**

#### 2-3: テスターを招待

1. **「Testers」をクリック**

2. **Google Group を作成**
   - 例: shougaku-kore-testers@googlegroups.com
   - メンバーを追加

3. **テスター Group を登録**
   - 「Create new testers list」で Group を追加

4. **テスト用リンクを生成**
   - テスターに共有するリンクを取得
   - 例: https://play.google.com/apps/testing/jp.petitworks.shougaku_kore_doutoku

### ステップ 3: Google Play での内部テスト実施

#### 3-1: 利用者側の手順

テスターが以下の手順でテストします:

1. **テスト用リンクにアクセス**
   - 提供されたリンクをクリック

2. **Google Play でアプリを入手**
   - 「このアプリをインストール」をクリック

3. **アプリをテスト**
   - デバイスにインストールされる
   - 機能をテスト

4. **フィードバックを送信**
   - メール・Slack・Google Forms で提出

#### 3-2: フィードバック方法

1. **Google Forms アンケート**
   - テスト項目をチェックシート化
   - フィードバックを収集

   ```
   https://forms.gle/[form-id]
   
   質問例:
   [ ] ホーム画面は正常に表示されるか？
   [ ] ストーリーは読み込まれるか？
   [ ] サブスクリプション試用は機能するか？
   [ ] バグ・クラッシュはないか？
   その他意見: _____________
   ```

2. **Slack チャネル**
   - テスト専用チャネル: #testing-internal
   - リアルタイムでフィードバック

3. **メール**
   - support@shougaku-kore.jp

---

## テスト実施チェックリスト

以下のテストを実施して、各項目の結果を記録します。

### Phase 1: 基本機能テスト（第1週）

| テスト項目 | 予期される結果 | 実績 |
|-----------|-------------|------|
| アプリがインストール可能 | インストール成功 | ✓ |
| アプリが起動する | 3 秒以内に起動 | ✓ |
| ホーム画面が表示される | ロゴ・タイトル表示 | ✓ |
| ストーリー一覧が表示される | 複数のストーリータイル表示 | ✓ |
| ストーリーが開く | ストーリーテキスト表示 | ✓ |
| 選択肢が表示される | 複数の選択肢が表示 | ✓ |
| 選択肢をタップできる | 次の画面に遷移 | ✓ |
| ストーリー完了時にバッジが表示される | バッジアイコン表示 | ✓ |
| バッジ一覧画面が表示される | 獲得したバッジ一覧表示 | ✓ |

### Phase 2: In-App Purchase テスト（第2週）

| テスト項目 | 予期される結果 | 実績 |
|-----------|-------------|------|
| 「Purchase」ボタンが表示される | ボタンが見える | ✓ |
| 「Purchase」をタップ | サブスクリプション説明表示 | ✓ |
| 試用期間（14日無料）の表示 | 「Free trial, then ¥500/month」表示 | ✓ |
| キャンセル方法が明記されている | 「You can cancel anytime」など表示 | ✓ |
| 購入確認ダイアログが表示 | OS の購入ダイアログ表示 | ✓ |
| 試用購入が成功する | 購入完了通知・領収書送信 | ✓ |
| 有料コンテンツにアクセス可能 | レポート・全ストーリー表示 | ✓ |
| キャンセルできる | iOS: Settings > Subscriptions、Android: Play Store > Subscription からキャンセル | ✓ |

### Phase 3: 親向けレポートテスト（第2週）

| テスト項目 | 予期される結果 | 実績 |
|-----------|-------------|------|
| 「Growth Report」が表示される | レポート画面表示 | ✓ |
| 月別データが表示される | グラフ・チャート表示 | ✓ |
| 判断力・共感力・主体性スコア表示 | 0～100 のスコア表示 | ✓ |
| レーダーチャートが表示 | 6 軸のレーダーチャート | ✓ |
| 月別変化グラフが表示 | 折れ線グラフで月ごとの変化 | ✓ |
| メール送信機能が動作 | レポート PDF が送信される | ✓ |

### Phase 4: オフライン機能テスト（第2週）

| テスト項目 | 予期される結果 | 実績 |
|-----------|-------------|------|
| オンライン時にストーリーが正常に読み込まれる | ストーリーテキスト表示 | ✓ |
| 飛行機モード ON にする | インターネット接続なし | ✓ |
| 既に読み込まれたストーリーが表示される | ストーリーテキスト表示 | ✓ |
| 未読ストーリーはダウンロードエラー | 「No internet connection」メッセージ表示 | ✓ |
| オンラインに戻す | インターネット接続復帰 | ✓ |
| 新しいストーリーが読み込まれる | ストーリーテキスト表示 | ✓ |

### Phase 5: パフォーマンステスト（第3週）

| テスト項目 | 予期される結果 | 実績 |
|-----------|-------------|------|
| アプリ起動時間 | 3 秒以内 | __ 秒 |
| ストーリー一覧読み込み | 1 秒以内 | __ 秒 |
| ストーリー本体読み込み | 1 秒以内 | __ 秒 |
| レポート画面読み込み | 2 秒以内 | __ 秒 |
| バッジ一覧読み込み | 1 秒以内 | __ 秒 |
| メモリ使用量 | 300 MB 以下 | __ MB |
| CPU 使用率 | 50% 以下 | __ % |

### Phase 6: UI・UX テスト（第3週）

| テスト項目 | 確認項目 | 結果 |
|-----------|---------|------|
| 文字サイズ | 読みやすい（12pt 以上） | ✓ |
| 色彩 | 子ども向け、見やすい色 | ✓ |
| ボタン配置 | 操作しやすい位置・サイズ | ✓ |
| アニメーション | 滑らか、目障りでない | ✓ |
| 日本語表示 | 正しく表示される | ✓ |
| 親向けテキスト | 親向けレポート説明は明確 | ✓ |
| バリアビリティ | 音声ナレーション機能が動作 | ✓ |

### Phase 7: セキュリティ・プライバシーテスト（第3週）

| テスト項目 | 予期される結果 | 実績 |
|-----------|-------------|------|
| HTTPS 通信が使用される | すべての通信が暗号化 | ✓ |
| ユーザーデータが暗号化される | ローカルデータが暗号化 | ✓ |
| 個人情報収集が最小化される | 名前・学年のみ収集 | ✓ |
| プライバシーポリシーが表示される | メニュー内にリンク | ✓ |
| 親向け同意画面が表示される | 初回起動時に同意要求 | ✓ |
| 親パスワード保護が動作 | パスワード設定・確認機能 | ✓ |

### Phase 8: クラッシュ・バグテスト（全期間）

| テスト項目 | 期待値 | 実績 |
|-----------|--------|------|
| クラッシュ検出 | クラッシュなし | 0 |
| ANR（Application Not Responding） | 5 秒以上の応答遅延なし | なし |
| ネットワークエラーハンドリング | エラーメッセージ表示 | ✓ |
| 入力フィールド検証 | 無効な入力を拒否 | ✓ |
| メモリリーク検出 | メモリ増加が緩い | ✓ |

---

## フィードバック収集

### フィードバック収集テンプレート

以下のテンプレートを使用してフィードバックを記録します:

```markdown
## テスト結果レポート

**テスター**: [Name]
**テスト日**: [Date]
**デバイス**: [Device Model / OS Version]
**ビルド**: [Version / Build Number]

### 全体の評価
- [ ] 非常に良い
- [ ] 良い
- [ ] 普通
- [ ] 悪い
- [ ] 非常に悪い

**コメント**: 

### 機能テスト
- [ ] ホーム画面: ✓ 問題なし / ✗ 問題あり
  - 詳細: 
- [ ] ストーリー選択: ✓ 問題なし / ✗ 問題あり
  - 詳細: 
- [ ] ストーリー読了: ✓ 問題なし / ✗ 問題あり
  - 詳細: 
- [ ] バッジシステム: ✓ 問題なし / ✗ 問題あり
  - 詳細: 
- [ ] レポート表示: ✓ 問題なし / ✗ 問題あり
  - 詳細: 
- [ ] サブスクリプション: ✓ 問題なし / ✗ 問題あり
  - 詳細: 

### バグ・問題報告
**優先度**: 
- [ ] 高（機能が使用不可）
- [ ] 中（使用可能だがエラーあり）
- [ ] 低（UI 改善程度）

**説明**: 

**再現手順**:
1. 
2. 
3. 

**期待される動作**: 

**実際の動作**: 

**スクリーンショット**: [添付]

### 改善案・要望
- 
- 

---
```

### Google Forms テンプレート

自動的にフィードバック収集するため、Google Forms を活用:

```
質問 1: ビルド・デバイス情報
- ビルド番号: [自由記入]
- デバイス名: [プルダウン]
- OS バージョン: [プルダウン]

質問 2: 全体評価
- 非常に良い / 良い / 普通 / 悪い / 非常に悪い

質問 3: 各機能評価（ラジオボタン各機能）
- ホーム画面
- ストーリー選択
- ストーリー読了
- バッジシステム
- レポート表示
- サブスクリプション

質問 4: バグ・問題報告（テキストエリア）
- 問題があればご記入ください

質問 5: 改善案・要望（テキストエリア）
- 改善案があればご記入ください

質問 6: その他コメント（テキストエリア）
```

### フィードバック共有・管理

1. **Slack チャネル**
   ```
   #testing-internal
   
   - フィードバック自動投稿
   - リアルタイム共有
   - 対応状況をスレッドで追跡
   ```

2. **Google Sheet**
   ```
   Testing Feedback Sheet
   
   列:
   - テスター名
   - 日付
   - デバイス
   - 優先度
   - 問題説明
   - 対応状況
   ```

3. **GitHub Issues**
   ```
   Label: testing-feedback
   
   バグ：
   - #001 Crash on Launch
   - #002 Purchase Dialog Not Showing
   
   改善案：
   - #003 Larger Font Size Option
   - #004 Dark Mode Support
   ```

---

## 対応プロセス

### フィードバック受け取り～対応～リリースまで

```
┌─────────────────────┐
│ フィードバック受け取り │
└──────────┬──────────┘
           │
      ┌────▼────┐
      │ 分類     │
      │ 優先度付 │
      └────┬────┘
           │
      ┌────▼──────────────┐
      │ 優先度別対応      │
      │ 高: 即日          │
      │ 中: 1-2 日        │
      │ 低: 次リリース    │
      └────┬──────────────┘
           │
      ┌────▼──────────┐
      │ ビルド修正     │
      │ & ローカルテスト│
      └────┬──────────┘
           │
      ┌────▼──────────┐
      │ 修正ビルド    │
      │ アップロード   │
      └────┬──────────┘
           │
      ┌────▼──────────┐
      │ テスター再確認 │
      └────┬──────────┘
           │
      ┌────▼──────────┐
      │ 全項目OK      │
      │ ↓本番申請     │
      └────────────────┘
```

### 対応例

**例 1: 高優先度バグ**
```
Issue: クラッシュ on Launch
優先度: 高
報告日: 2026-09-05
対応: 
  - 09-05 18:00 - バグ特定（メモリリーク）
  - 09-05 20:00 - 修正 & ローカルテスト
  - 09-06 10:00 - 修正ビルド（v1.0.0-internal-002）アップロード
  - 09-06 15:00 - テスター再確認 ✓ OK
解決: 09-06
```

**例 2: 中優先度改善案**
```
Issue: Font Size が小さい
優先度: 中
報告日: 2026-09-06
対応:
  - 09-06 15:00 - フォントサイズ調整（14pt → 16pt）
  - 09-06 16:00 - ローカルテスト
  - 09-07 10:00 - 修正ビルド（v1.0.0-internal-003）アップロード
  - 09-07 14:00 - テスター確認 ✓ OK
解決: 09-07
```

---

## テスト完了の判定基準

テスト期間を終了する際の判定基準:

- [ ] クラッシュゼロ（少なくとも 1 週間）
- [ ] 高優先度バグなし
- [ ] In-App Purchase 動作確認 ✓
- [ ] オフライン機能動作確認 ✓
- [ ] レポート生成確認 ✓
- [ ] パフォーマンス基準達成 ✓
- [ ] UI・UX テスト完了 ✓
- [ ] セキュリティテスト完了 ✓
- [ ] テスター全員から「OK」を受け取る
- [ ] 平均ユーザー評価 4.0 以上

**判定**: すべてのチェックが完了したら、本番申請へ進行可能。

---

## 次のステップ

テスト完了後:

1. **本番ビルド準備**
   - バージョン番号を更新（例: v1.0.0）
   - リリースノートを作成

2. **申請準備**
   - メタデータ最終確認
   - スクリーンショット・画像最終確認
   - プライバシーポリシー・サポート URL 確認

3. **申請実行**
   - Google Play: 「Submit for Review」をクリック
   - App Store: 「Submit for Review」をクリック

詳細は **GOOGLE_PLAY_SUBMISSION_GUIDE.md** および **APP_STORE_SUBMISSION_GUIDE.md** を参照。

---

**最終更新日**: 2026-09-01
**ステータス**: ドラフト
