# オンコール・運用体制

**小学コレ！道徳** - 24/7 監視・運用体制

**最終更新**: 2026年9月1日

---

## 概要

本ドキュメントは、本番環境の 24/7 監視、オンコール対応体制、定期メンテナンス、セキュリティパッチ対応を定めています。

---

## オンコール体制

### 1. オンコール当番スケジュール

#### 1.1 基本体制

```
【シフト構成】
- Primary On-call: 東京在住のシニアエンジニア
- Secondary On-call: サポート・エンジニア
- Escalation: CTO・プロジェクトマネージャー

【時間帯】
- 平日日中 (9:00-18:00): Primary 待機
- 平日夜間 (18:00-9:00): Secondary 待機
- 休日: 交代制（Primary / Secondary）
```

#### 1.2 オンコール当番表（3か月単位で更新）

```
【2026 年 9月-11月】

9 月:
- Week 1 (1-7): Alice (平日) / Bob (夜間)
- Week 2 (8-14): Bob (平日) / Charlie (夜間)
- Week 3 (15-21): Charlie (平日) / Alice (夜間)
- Week 4 (22-30): Alice (平日) / Bob (夜間)

10 月:
- Week 1 (1-5): Bob (平日) / Charlie (夜間)
- ...

【休日対応】
- 日祝日: 交代制
- GW・盆・年末年始: 事前に決定
```

**Google Calendar での共有**:
```
Calendar: "Shougaku Kore On-call"
- 各担当者のスケジュールを共有
- Slack との連動で自動通知
```

#### 1.3 オンコール担当者向けの事前準備

**セットアップチェックリスト**:

```
□ 環境変数の設定確認
export KEYSTORE_PASSWORD=***
export APPLE_ID=***
export FASTLANE_PASSWORD=***

□ GitHub 権限確認
- Push 権限: main ブランチ
- Release 作成権限

□ Google Play Console へのアクセス確認
- Service Account 認証

□ Slack 通知設定
- #critical の通知を ON にする

□ 電話・連絡先の確認
- オンコール電話番号を確認
- エスカレーション連絡先を把握

□ ツールのインストール確認
flutter upgrade
gcloud auth login
fastlane setup ios
```

### 2. オンコール対応フロー

#### 2.1 問題検出・報告

```
【自動通知パターン】
1. Firebase Crashlytics → Slack #critical
2. Sentry エラー → Slack #critical
3. Cloud Monitoring アラート → Slack #critical
4. ユーザーメール → ops@example.com → Slack

【応答時間目標】
- P1: 15分以内に確認
- P2: 30分以内に確認
- P3: 2時間以内に確認
```

#### 2.2 初期対応（30分以内）

**Slack での確認**:

```
Slack #critical:

@on-call-engineer
P1 インシデントが発生しました

詳細は当スレッドで更新いたします。
確認いただけましたでしょうか？

確認しました → 返信する
対応不可 → 連絡先に電話
```

**エスカレーション**:

```
30分以内に返信がない場合:
1. Slack で @on-call-engineer を再度メンション
2. 電話で連絡 (emergency phone)
3. 応答なし → 次の担当者に連絡
```

#### 2.3 対応チーム集合

**P1 の場合**:

```
Slack スレッド:

@alice (IC): 対応開始
@bob (Tech Lead): デバッグ準備
@charlie (Support): ユーザー連絡準備

【Zoom 通話】
https://zoom.us/j/shougaku-kore-incident
```

### 3. オンコール支援体制

#### 3.1 オンコール中の サポート

```
【テックリード（平日 9-18時）】
- オンコール担当が判断に迷った場合の相談先
- ホットフィックス承認者
- Slack で常に応答可能

【プロダクトマネージャー】
- ユーザーコミュニケーション判断
- リリース判断（セキュリティ脅威など）

【DevOps】
- インフラ対応
- ビルド・署名・リリース
```

#### 3.2 オンコール中の休息

```
【ポリシー】
- P1 インシデント対応後: 翌日は勤務免除
- 深夜対応が多い月: 勤務日数を調整

【例】
- 月曜夜 P1 対応 → 火曜は勤務免除
- 月夜：3件の P1 対応 → 月末に代休 2日
```

### 4. オンコール手当・評価

```
【月額手当】
- Primary On-call: +¥30,000
- Secondary On-call: +¥15,000

【評価項目】
- インシデント対応速度
- 対応品質（再発なし）
- チームサポート（エスカレーション判断）
- ドキュメント更新状況
```

---

## 定期メンテナンス計画

### 1. 毎週メンテナンス

#### 1.1 毎週月曜朝（9:00-10:00）

```
【システムチェック】
- [ ] Firebase コンソール ステータス確認
- [ ] Google Cloud サービスステータス確認
- [ ] 過去 1 週間のインシデント確認
- [ ] クラッシュレート確認（< 0.5%か）
- [ ] API 応答時間確認（> 500msか）
```

**チェックリスト実行**:

```bash
#!/bin/bash

echo "=== Weekly Maintenance Check ==="

# 1. Firebase Analytics
echo "Firebase Crashlytics: https://console.firebase.google.com/project/[id]/crashlytics"
# クラッシュレート確認

# 2. Google Cloud 状態確認
gcloud services list --enabled | grep "run\|firestore\|storage"

# 3. API ヘルスチェック
curl -s https://api.shougaku-kore.jp/health

# 4. ディスク使用量確認
gsutil du -s gs://shougaku-kore-*

echo "=== Check Complete ==="
```

**実行者**: オンコール担当者（Monday 9:00）

#### 1.2 毎週金曜夕方（17:00-18:00）

```
【リリース準備確認】
- [ ] main ブランチが安定しているか
- [ ] テスト成功率 > 95% か
- [ ] コードカバレッジ低下がないか
- [ ] 次回リリース予定を確認
```

### 2. 毎月メンテナンス

#### 2.1 月初（第 1 営業日 10:00-12:00）

```
【月次監視レポート生成】
```

**手順**:

```bash
# Firebase Analytics レポート生成
python3 scripts/monthly_analytics_report.py > reports/2026-09.md

# コスト確認
gcloud billing accounts list
gcloud compute project-info describe [project-id] --format="value(quotas)"

# セキュリティアラート確認
gcloud container images scan [image-url]

# バックアップ確認
gsutil ls gs://shougaku-kore-backups/
```

**レポート送信**:

```
宛先: team@example.com
件名: 【月次レポート】2026年9月 - 小学コレ！道徳

【KPI】
- DAU: 1,234 (+5% from previous month)
- Crash Rate: 0.32% (target: < 0.5%) ✅
- Conversion Rate: 12% (target: > 10%) ✅

【インシデント】
- P1: 1 件（既解決）
- P2: 3 件（既解決）

【コスト】
- Firebase: $123
- Google Cloud: $456
- Total: $579

【推奨アクション】
- Cloud Run 最大インスタンス数を 20 → 30 に増加
```

#### 2.2 月中（第 2 水曜 14:00-15:00）

```
【セキュリティ監視】
- [ ] Firebase Security Rules レビュー
- [ ] API キー ローテーション確認
- [ ] セキュリティパッチ確認（OS・パッケージ）
- [ ] ユーザーデータ保護を再確認（COPPA 準拠）
```

#### 2.3 月末（最終金曜 15:00-17:00）

```
【容量・スケーリング判定】
- [ ] Firestore 読み取り数が増加傾向か
- [ ] Cloud Run CPU 使用率が増加傾向か
- [ ] Storage 容量が増加傾向か
- [ ] スケールアップが必要か判定
```

### 3. 四半期ごとのレビュー

#### 3.1 Q ごとレビュー（月末金曜 16:00-18:00）

```
【開催】
- テックリード
- SRE / DevOps
- QA リード

【アジェンダ】
1. インシデント分析（傾向・改善）
2. パフォーマンス分析（KPI 確認）
3. セキュリティ監査（脆弱性確認）
4. 改善アクション確認（実施状況）
5. 来期計画立案
```

---

## セキュリティパッチ対応

### 1. セキュリティパッチ検出・評価

#### 1.1 パッチ情報源

```
【監視対象】
- Google Cloud Security Advisories
- Flutter / Dart セキュリティアナウンス
- Firebase セキュリティアナウンス
- GitHub Dependabot
- NVD (National Vulnerability Database)
```

**Slack bot による毎日 9:00 通知**:

```
Slack #security:

🔒 Security Update Available

Package: firebase_core
Current: 2.13.0
Latest: 2.14.0

Severity: MEDIUM
Description: Session hijacking vulnerability in iOS SDK

Action Required: Within 1 week

CVE: CVE-2026-1234
Link: https://firebase.google.com/support/security/secures/
```

#### 1.2 パッチ優先度判定

```
P1 - 即対応（24時間以内）
- セキュリティ脆弱性 (CVSS > 9.0)
- 認証・支払い関連
- ユーザーデータ保護関連

P2 - 週内対応（7日以内）
- 中程度脆弱性 (CVSS 5.0-8.9)
- API セキュリティ
- ネットワークセキュリティ

P3 - 通常リリースで対応
- 低程度脆弱性 (CVSS < 5.0)
- 開発ツール関連
```

#### 1.3 パッチ実装フロー

```bash
# 1. パッチを検証
pubspec.yaml でバージョン更新
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 2. テスト実行
flutter test
flutter test integration_test

# 3. ステージング環境で検証
# Firebase Staging プロジェクトにデプロイ

# 4. リリース
# 通常のリリースプロセスに従う
```

### 2. 依存パッケージ管理

#### 2.1 定期更新ポリシー

```
【セキュリティアップデート】
- パッチバージョン: 即更新
- マイナーバージョン: 2週間以内
- メジャーバージョン: 検証後（1-2か月）

【実装例】
pubspec.yaml で:
firebase_core: ^2.14.0  # パッチは自動更新（推奨）
flutter_riverpod: ^2.4.0  # マイナー更新も許可

flutter pub upgrade  # 月 1 回定期実行
```

#### 2.2 パッケージ更新 CI/CD

```yaml
# .github/workflows/dependency-update.yml
name: Dependency Update

on:
  schedule:
    - cron: '0 9 * * MON'  # 毎週月曜 9時

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Update Dependencies
        run: |
          flutter pub upgrade
          flutter pub get
      
      - name: Run Tests
        run: flutter test
      
      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: 'chore: update dependencies'
          title: 'Dependency Update'
          labels: 'dependencies'
```

---

## バックアップ・リカバリ計画

### 1. バックアップスケジュール

```
【毎日】
- Cloud SQL 自動バックアップ (00:00 UTC)
- Cloud Firestore リアルタイムレプリケーション
- Cloud Storage オブジェクト バージョニング

【毎週】
- Cloud SQL 手動スナップショット (日曜 12:00 UTC)
- Cloud Storage 全体バックアップ (日曜 20:00 UTC)

【毎月】
- Cross-Region レプリケーション (asia-northeast1 → asia-southeast1)
- 復旧テスト実施
```

### 2. 復旧テスト（毎月末）

```
【テスト内容】
1. Cloud SQL バックアップからの復旧テスト
2. Firestore エクスポート/インポートテスト
3. Cloud Storage からのリストアテスト

【実施者】
- DevOps エンジニア
- QA リード

【テスト結果】
docs/BACKUP_RECOVERY_TEST_RESULTS.md に記録
```

---

## 本番環境 Health Check

### 1. Daily Health Check（毎営業日 9:00）

```bash
#!/bin/bash

echo "=== Daily Health Check ==="
echo "Time: $(date)"

# 1. アプリケーション
curl -s https://api.shougaku-kore.jp/health | jq .
# 期待: {"status": "ok"}

# 2. Firebase
gcloud firestore query users --limit=1

# 3. Cloud Run
gcloud run services describe shougaku-kore-backend

# 4. Cloud SQL
gcloud sql instances describe shougaku-kore-db

# 5. Cloud Storage
gsutil du -h gs://shougaku-kore-storage

echo "=== Health Check Complete ==="
```

**実行**: オンコール担当者（Daily 9:00）

### 2. Weekly Deep Dive（毎週月曜 9:00-10:00）

```
【確認事項】
- [ ] 過去 1 週間のリソース使用量トレンド
- [ ] エラーログの傾向（新しいエラーパターン）
- [ ] ユーザーフィードバック（ネガティブレビュー）
- [ ] セキュリティアラート
```

---

## エスカレーション・連絡先

### 1. エスカレーション経路

```
【Tier 1: オンコール担当者】
- 対応時間: 0-30分
- 判断基準: 既知の問題か、明確な解決策があるか

【Tier 2: テックリード】
- 対応時間: 30-1時間
- 判断基準: 原因が特定でき、修正可能か
- 連絡: Slack + 電話

【Tier 3: CTO / プロダクトマネージャー】
- 対応時間: 1-2時間
- 判断基準: サービス継続判定、リリース判定
- 連絡: 電話 + メール
```

### 2. 緊急連絡先

```
【平日 9:00-18:00】
Tech Lead (Alice): alice@example.com / 090-XXXX-1111
Product Manager: bob@example.com / 090-XXXX-2222

【平日 18:00-09:00】
On-call Engineer: oncall@example.com / 090-XXXX-3333

【休日・緊急】
CTO: cto@example.com / 090-XXXX-4444

【外部連絡】
Google Cloud Support: support@google.com / サポートコンソール
Firebase Support: Firebase コンソール > サポート
```

### 3. 連絡テンプレート

**P1 インシデント時の電話連絡**:

```
"お疲れ様です。[名前] です。

現在 P1 インシデントが発生しています：
- 問題: [簡潔な説明]
- 影響: [ユーザー数、時間]
- 状態: [検出/対応中/解決済み]

対応チーム: [担当者]

電話で詳細打ち合わせをしたいのですが、
お時間ありますか？"
```

---

## インシデント後の振り返り（Retrospective）

### 1. 実施タイミング

```
【即座に実施】（インシデント直後 1-2日以内）
- P1: 24時間以内
- P2: 1週間以内
- P3: 1か月以内
```

### 2. 参加者

```
- Incident Commander
- 対応エンジニア全員
- QA リード
- 関連する他チーム
```

### 3. アジェンダ

```
1. Timeline Review (15分)
   - 何が起きたのか、時系列で振り返り

2. What Went Well (5分)
   - 良かった点、素早い対応など

3. What Didn't Go Well (10分)
   - 改善が必要な点、遅かった対応など

4. Action Items (10分)
   - 改善アクション
   - 担当者、期限を決定

5. Appreciation (2分)
   - チームメンバーへの感謝
```

---

## 参考資料

- [docs/HOTFIX_RESPONSE_PLAN.md](HOTFIX_RESPONSE_PLAN.md)
- [docs/PRODUCTION_MONITORING_SETUP.md](PRODUCTION_MONITORING_SETUP.md)
- [docs/INCIDENT_RESPONSE_PROCEDURES.md](INCIDENT_RESPONSE_PROCEDURES.md)
- [Google Cloud On-call Best Practices](https://cloud.google.com/solutions/on-call-practices)
- [SRE Books](https://sre.google/books/)

---

## 更新履歴

| 日付 | 更新内容 | 更新者 |
|------|--------|-------|
| 2026-09-01 | 初版作成 | zkaz83@gmail.com |
