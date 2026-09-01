# 運用・リリース体制ドキュメント インデックス

**小学コレ！道徳** - 本番環境運用完全ガイド

**最終更新**: 2026年9月1日

---

## ドキュメント一覧

本番環境の運用・リリース・監視体制を確立するための 7 つの詳細ドキュメント：

### 1. 📋 [リリース手順書（最終版）](RELEASE_PROCEDURE_FINAL.md)
**対象**: リリースエンジニア、DevOps  
**所要時間**: 約 4-6時間（テスト含む）

**内容**:
- リリース前準備（バージョン更新、テスト、署名確認）
- Android AAB / iOS ipa ビルド手順
- Google Play への段階的ロールアウト（25% → 50% → 100%）
- App Store への審査・申請・リリース
- リリース後の監視（Day 1-4）
- ロールバック手順
- GitHub Actions による自動化

**キーポイント**:
- バージョニング規則（メジャー.マイナー.パッチ+ビルド番号）
- 段階的ロールアウトで リスク最小化
- リリース前チェックリスト（署名、テスト、リリースノート）

---

### 2. 📊 [本番監視ダッシュボード設定ガイド](PRODUCTION_MONITORING_SETUP.md)
**対象**: SRE、DevOps、QA  
**セットアップ時間**: 約 2-4時間

**内容**:
- Firebase Analytics ダッシュボード（DAU、クラッシュレート、セッション）
- Firebase Crashlytics（クラッシュ監視、トップクラッシュ分析）
- Firebase Performance Monitoring（起動時間、API レスポンス、メモリ）
- Google Cloud Logging（バックエンド API ログ）
- Cloud Monitoring（インフラ監視、アラート設定）
- Sentry エラー監視
- Slack 統合（自動通知、アラート）
- Google Analytics（ビジネスメトリクス）
- 日次・月次レポート自動生成

**KPI 監視**:
| メトリクス | 目標値 | アラート閾値 |
|----------|-------|-----------|
| クラッシュレート | < 0.5% | > 1% |
| ANR レート | < 0.1% | > 0.5% |
| 起動時間 | < 3秒 | > 5秒 |
| API 応答時間 | < 500ms | > 1000ms |

---

### 3. 🚨 [ホットフィックス対応体制](HOTFIX_RESPONSE_PLAN.md)
**対象**: 全エンジニア、オンコール担当  
**対応時間**: 検出から 1-2営業日以内

**内容**:
- ホットフィックス対象の判定基準（P1/P2/P3）
- 対応フロー：検出 → 確認 → 修正 → テスト → リリース → 監視
- P1 緊急対応（即日リリース）の詳細手順
- バージョン番号更新（パッチバージョンアップ）
- ビルド・署名・テスト
- Google Play / App Store の緊急配布
- リリース後の監視（6時間連続）
- ロールバック手順
- 顧客コミュニケーション（謝罪メール）

**優先度判定**:
- **P1** (即対応): クラッシュ > 2%、セキュリティ脆弱性、支払い機能不可
- **P2** (24h): クラッシュ 0.5-2%、特定 OS のみ、パフォーマンス著しく低下
- **P3** (通常): クラッシュ < 0.5%、UI 表示ズレ、音声機能不具合

---

### 4. 🔧 [本番環境トラブルシューティング](PRODUCTION_TROUBLESHOOTING.md)
**対象**: QA、サポート、エンジニア  
**使用頻度**: トラブル発生時

**内容**:
- アプリ安定性（クラッシュ、ANR、メモリリーク）
- パフォーマンス問題（起動時間、ネットワーク遅延）
- Firebase 関連（データ同期、ストレージ）
- 認証・支払い関連（ログイン、In-App Purchase）
- ネットワーク関連（API 応答、タイムアウト）
- ローカルストレージ破損
- キャッシュの陳腐化

**診断方法**:
- Firebase Console でのログ確認
- Sentry でのエラー詳細確認
- ローカル再現手順
- デバッグシンボル・スタックトレース分析

**対応例**:
- スタックトレースの読み方
- メモリリークの特定・修正
- ネットワーク タイムアウト対応
- キャッシング戦略の改善

---

### 5. 📈 [スケーリング・容量計画](SCALING_AND_CAPACITY_PLAN.md)
**対象**: DevOps、テックリード、プロダクトマネージャー  
**計画期間**: リリース後 24か月

**内容**:
- ユーザー成長予測（月1 → 月24 のスケール）
  - Day 1: 100-500 DAU
  - Month 6: 1,000-5,000 DAU
  - Month 12: 10,000-30,000 DAU
  - Month 24: 50,000-100,000 DAU

- Firebase Firestore 容量計画
  - データサイズ予測（100MB → 50GB）
  - 読み取り/書き込み数予測
  - コスト試算

- Cloud Run バックエンド API スケーリング
  - CPU/メモリ リソース計画
  - インスタンス数自動スケーリング
  - 最大インスタンス数設定

- Cloud Storage 容量計画
  - 画像・オーディオ・PDF ストレージ
  - ライフサイクル設定（古いデータ削除）

- CDN・キャッシング戦略
  - Cloud CDN 設定
  - ローカルキャッシュ戦略
  - Redis キャッシュ

- コスト最適化施策
  - 年間契約割引（CUD）
  - Committed Use Discounts（25-37% 割引）

**コスト予測**:
| フェーズ | Firestore | Cloud Run | Storage | SQL | 合計 |
|---------|----------|-----------|---------|-----|------|
| Month 1 | ~¥0 | ~¥0 | ~¥100 | ~¥2k | ~¥2.1k |
| Month 6 | ~¥100 | ~¥5k | ~¥500 | ~¥4k | ~¥9.6k |
| Month 12 | ~¥1k | ~¥30k | ~¥1k | ~¥8k | ~¥40k |
| Month 24 | ~¥5k | ~¥150k | ~¥3k | ~¥16k | ~¥174k |

---

### 6. 🏥 [インシデント対応プロセス](INCIDENT_RESPONSE_PROCEDURES.md)
**対象**: 全エンジニア、オンコール担当、プロダクトマネージャー  
**対応時間**: P1 は 1-2時間、P2 は 24時間

**内容**:
- インシデント分類（P1/P2/P3）
- インシデント対応フロー（6 フェーズ）
  1. 検出・報告（0-15分）
  2. 初期対応（15-30分）
  3. 原因特定・初期対応（30-60分）
  4. ホットフィックス実装・テスト（1-2時間）
  5. リリース・デプロイ（30-60分）
  6. 根本原因分析（RCA）（24-48時間後）

- RCA テンプレート（5 Why 分析）
  - 直接原因（Proximate Cause）
  - 根本原因（Root Cause）
  - 改善アクション（即座・短期・長期・組織的）

- インシデント通知・コミュニケーション
  - ユーザー初期通知
  - インシデント完了通知
  - 月次インシデント サマリー

**インシデント ダッシュボード**:
- GitHub Issues でのインシデント管理
- 月次統計（発生数、原因別、パターン分析）

---

### 7. 👨‍💼 [オンコール・運用体制](ONCALL_AND_OPERATIONS.md)
**対象**: オンコール担当、DevOps、テックリード  
**実施範囲**: 24/7 監視体制

**内容**:
- オンコール当番スケジュール
  - 3か月単位で管理
  - Primary（日中）/ Secondary（夜間）体制
  - 休日・祝日の対応

- オンコール対応フロー
  - 問題検出・報告（15分以内に応答）
  - 初期対応（30分以内に確認）
  - エスカレーション（Tier 1 → Tier 2 → Tier 3）
  - オンコール支援体制

- オンコール手当・評価
  - 月額手当（Primary +¥30k, Secondary +¥15k）
  - パフォーマンス評価基準

- 定期メンテナンス計画
  - **毎週**: システムチェック（Monday 9:00）
  - **毎月**: 月次レポート（1st day 10:00）
  - **四半期**: 深刻度レビュー（Quarter end）

- セキュリティパッチ対応
  - パッチ検出（毎日 9:00 通知）
  - 優先度判定（P1/P2/P3）
  - パッチ実装フロー
  - 定期依存パッケージ更新（毎週月曜）

- バックアップ・リカバリ計画
  - 自動バックアップ（毎日）
  - 手動スナップショット（毎週）
  - 復旧テスト（毎月末）

- 本番環境 Health Check
  - Daily Health Check（毎営業日 9:00）
  - Weekly Deep Dive（毎週月曜 9:00-10:00）

- エスカレーション・連絡先
  - Tier 1: オンコール担当（0-30分）
  - Tier 2: テックリード（30分-1時間）
  - Tier 3: CTO（1-2時間）
  - 緊急連絡先リスト

---

## ドキュメント使用フロー

### 🚀 リリース時
1. [リリース手順書](RELEASE_PROCEDURE_FINAL.md) で手順確認
2. [本番監視ダッシュボード設定](PRODUCTION_MONITORING_SETUP.md) で監視準備
3. リリース後、[本番監視ダッシュボード](PRODUCTION_MONITORING_SETUP.md) で監視開始

### 🆘 問題が発生した場合
1. [本番環境トラブルシューティング](PRODUCTION_TROUBLESHOOTING.md) で初期診断
2. クラッシュレート > 0.5% なら [ホットフィックス対応体制](HOTFIX_RESPONSE_PLAN.md)
3. インシデント対応は [インシデント対応プロセス](INCIDENT_RESPONSE_PROCEDURES.md)
4. 解決後、RCA と改善アクション実施

### 📈 ユーザー成長時
1. [スケーリング・容量計画](SCALING_AND_CAPACITY_PLAN.md) で成長に対応
2. リソース増加判定と実施
3. [オンコール・運用体制](ONCALL_AND_OPERATIONS.md) で定期メンテナンス実施

### 🛡️ セキュリティパッチ
1. [オンコール・運用体制](ONCALL_AND_OPERATIONS.md) の "セキュリティパッチ対応" で対応
2. パッチ実装 → テスト → リリース

### 📋 定期メンテナンス
[オンコール・運用体制](ONCALL_AND_OPERATIONS.md) に従い:
- 毎週月曜朝: Weekly Check
- 毎月1日: Monthly Report
- 毎月末: Quarterly Review

---

## チェックリスト

### リリース前に確認
- [ ] [RELEASE_PROCEDURE_FINAL.md](RELEASE_PROCEDURE_FINAL.md) を読了
- [ ] バージョン番号を確認（pubspec.yaml, iOS, Android）
- [ ] リリースノートを準備
- [ ] テストが通っているか確認
- [ ] 署名設定が正しいか確認
- [ ] Firebase 設定（本番）になっているか確認

### リリース後に確認
- [ ] [PRODUCTION_MONITORING_SETUP.md](PRODUCTION_MONITORING_SETUP.md) の KPI を監視
- [ ] クラッシュレート < 0.5% か確認
- [ ] API 応答時間 < 500ms か確認
- [ ] ユーザーコメント確認
- [ ] 段階的ロールアウト進捗確認

### 日次
- [ ] [ONCALL_AND_OPERATIONS.md](ONCALL_AND_OPERATIONS.md) の Daily Health Check 実施
- [ ] Firebase Crashlytics で新しいクラッシュ確認
- [ ] ユーザーレビュー確認

### 週次
- [ ] [ONCALL_AND_OPERATIONS.md](ONCALL_AND_OPERATIONS.md) の Weekly Check 実施
- [ ] セキュリティパッチ確認
- [ ] インシデント確認

### 月次
- [ ] [ONCALL_AND_OPERATIONS.md](ONCALL_AND_OPERATIONS.md) の月次レポート生成
- [ ] コスト確認（[SCALING_AND_CAPACITY_PLAN.md](SCALING_AND_CAPACITY_PLAN.md)）
- [ ] インシデント傾向分析

---

## 参考資料

### 既存ドキュメント（関連）
- [docs/RELEASE_GUIDE.md](RELEASE_GUIDE.md) - リリースガイド（基本）
- [docs/MONITORING.md](MONITORING.md) - 監視ガイド（基本）
- [docs/HOTFIX_PROCEDURE.md](HOTFIX_PROCEDURE.md) - ホットフィックス（基本）

### Google Cloud
- [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator)
- [Cloud Run Scaling](https://cloud.google.com/run/docs/quickstarts/build-and-deploy)
- [Firestore Quotas and Limits](https://firebase.google.com/docs/firestore/quotas)
- [Google Cloud On-call Best Practices](https://cloud.google.com/solutions/on-call-practices)

### Firebase
- [Firebase Console](https://console.firebase.google.com)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mod)

### SRE / DevOps
- [Google SRE Books](https://sre.google/books/)
- [Google Cloud Incident Response](https://cloud.google.com/docs/incident-response)

---

## 質問・問い合わせ

運用に関するご質問・課題がございましたら、以下の手順で対応いただきます：

1. **関連ドキュメント確認**: 上記の該当ドキュメントを参照
2. **FAQ 確認**: 各ドキュメントのトラブルシューティングセクション
3. **Slack #ops で質問**: `@devops-team` にメンション
4. **GitHub Issue 作成**: `label: ops`, `label: documentation`

---

## ドキュメント更新履歴

| 日付 | 更新内容 | 更新者 |
|------|--------|-------|
| 2026-09-01 | 初版作成（全 7 つの運用ドキュメント） | zkaz83@gmail.com |

次回レビュー: **2026年10月1日**

---

**最後に**: これらのドキュメントは、チーム全体が実運用を通じて経験することで、継続的に改善されていきます。フィードバックや改善提案は大歓迎です！
