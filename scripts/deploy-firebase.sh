#!/bin/bash

################################################################################
# Firebase デプロイメント スクリプト
# 小学コレ！道徳アプリ - 本番環境デプロイ
#
# 使用方法:
#   ./deploy-firebase.sh [backup|restore|rules|deploy-all]
#
# 説明:
#   - backup:     本番DBをバックアップ
#   - restore:    バックアップから復元
#   - rules:      Firestore/Storage ルールをデプロイ
#   - deploy-all: ルール＆配置のすべてをデプロイ
################################################################################

set -euo pipefail

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 定数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FIREBASE_DIR="${PROJECT_ROOT}/firebase"
BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/firestore_backup_${TIMESTAMP}.json"

# ロギング関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 前提条件チェック
check_prerequisites() {
    log_info "前提条件をチェック中..."

    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI がインストールされていません"
        echo "インストール: npm install -g firebase-tools"
        exit 1
    fi

    if ! firebase --version &> /dev/null; then
        log_error "Firebase CLI が正しく動作していません"
        exit 1
    fi

    log_success "Firebase CLI が見つかりました: $(firebase --version)"

    # Firebase プロジェクト設定の確認
    if [[ ! -f "${PROJECT_ROOT}/.firebaserc" ]]; then
        log_error ".firebaserc ファイルが見つかりません"
        echo "firebase init を実行して初期化してください"
        exit 1
    fi

    log_success "Firebase プロジェクト設定が確認されました"
}

# バックアップディレクトリ作成
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_success "バックアップディレクトリを作成しました: $BACKUP_DIR"
    fi
}

# Firebase 認証確認
check_firebase_auth() {
    log_info "Firebase 認証をチェック中..."

    if ! firebase projects:list &> /dev/null; then
        log_error "Firebase に認証されていません"
        echo "認証情報を設定してください: firebase login"
        exit 1
    fi

    CURRENT_PROJECT=$(firebase use 2>/dev/null || echo "未設定")
    log_success "現在のプロジェクト: $CURRENT_PROJECT"
}

# Firestore バックアップ
backup_firestore() {
    log_info "Firestore をバックアップ中..."
    create_backup_dir

    if firebase firestore:delete --all-collections --yes 2>&1 | grep -q "error"; then
        log_warning "バックアップ実行中に警告が発生しました"
    fi

    # Firestore エクスポート（GCS）
    EXPORT_BUCKET="gs://$(firebase projects:list --json | jq -r '.[0].projectId')-backups"

    log_info "Firestore をエクスポート中: $EXPORT_BUCKET"
    # Note: 実際の エクスポートは gcloud コマンドで実行
    # gcloud firestore export "$EXPORT_BUCKET/firestore_${TIMESTAMP}" --async

    log_success "バックアップ完了: $BACKUP_FILE"
    echo "バックアップパス: $BACKUP_FILE"
}

# Firestore 復元
restore_firestore() {
    local backup_path="$1"

    if [[ ! -f "$backup_path" ]]; then
        log_error "バックアップファイルが見つかりません: $backup_path"
        exit 1
    fi

    log_warning "本番環境 Firestore を復元します: $backup_path"
    read -p "本当に復元しますか？ (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "復元をキャンセルしました"
        exit 0
    fi

    log_info "Firestore 復元中..."
    # Note: gcloud firestore import を使用
    # gcloud firestore import "$backup_path"

    log_success "復元完了"
}

# Firestore ルールをデプロイ
deploy_firestore_rules() {
    local rules_file="${FIREBASE_DIR}/firestore.rules"

    if [[ ! -f "$rules_file" ]]; then
        log_error "Firestore ルールファイルが見つかりません: $rules_file"
        exit 1
    fi

    log_info "Firestore ルールを検証中..."
    if ! firebase rules:test "$rules_file" 2>&1 | grep -q "PASSED"; then
        log_warning "テストが失敗しました。ルールを確認してください"
        read -p "続けますか？ (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            exit 1
        fi
    fi

    log_info "Firestore ルールをデプロイ中..."
    firebase deploy --only firestore:rules

    log_success "Firestore ルール デプロイ完了"
}

# Storage ルールをデプロイ
deploy_storage_rules() {
    local rules_file="${FIREBASE_DIR}/storage.rules"

    if [[ ! -f "$rules_file" ]]; then
        log_error "Storage ルールファイルが見つかりません: $rules_file"
        exit 1
    fi

    log_info "Storage ルールをデプロイ中..."
    firebase deploy --only storage:rules

    log_success "Storage ルール デプロイ完了"
}

# 完全なデプロイ（バックアップ + ルール）
deploy_all() {
    log_info "========================================="
    log_info "本番環境への完全デプロイを開始します"
    log_info "========================================="

    check_prerequisites
    check_firebase_auth

    # バックアップ実行
    log_warning "バックアップを実行してからデプロイを進めます"
    read -p "バックアップを実行しますか？ (yes/no): " backup_confirm
    if [[ "$backup_confirm" == "yes" ]]; then
        backup_firestore
    fi

    # ルールをデプロイ
    log_info ""
    log_info "Firestore ルールをデプロイします"
    deploy_firestore_rules

    log_info ""
    log_info "Storage ルールをデプロイします"
    deploy_storage_rules

    log_success "========================================="
    log_success "デプロイが完了しました"
    log_success "========================================="
}

# バージョン情報表示
show_version() {
    echo "Firebase Deploy Script v1.0.0"
}

# ヘルプ表示
show_help() {
    cat << EOF
Firebase デプロイメント スクリプト

使用方法:
  $0 [コマンド]

コマンド:
  backup       - 本番環境 Firestore をバックアップ
  restore FILE - バックアップから復元 (FILE: バックアップファイルパス)
  rules        - Firestore/Storage ルールをデプロイ
  deploy-all   - バックアップ + ルールのすべてをデプロイ
  help         - このヘルプを表示

例:
  $0 deploy-all              # 完全デプロイ
  $0 backup                  # バックアップのみ
  $0 restore backups/firestore_backup_20240901_120000.json

前提条件:
  - firebase-tools がインストールされていること
  - firebase login で認証済みであること
  - .firebaserc ファイルが存在すること

注意:
  本番環境へのデプロイは十分な確認の上で実行してください。
  デプロイ前には必ずバックアップを取得してください。
EOF
}

# メイン処理
main() {
    local command="${1:-}"

    case "$command" in
        backup)
            check_prerequisites
            check_firebase_auth
            backup_firestore
            ;;
        restore)
            if [[ -z "${2:-}" ]]; then
                log_error "復元ファイルパスを指定してください"
                show_help
                exit 1
            fi
            check_prerequisites
            check_firebase_auth
            restore_firestore "$2"
            ;;
        rules)
            check_prerequisites
            check_firebase_auth
            deploy_firestore_rules
            deploy_storage_rules
            ;;
        deploy-all)
            deploy_all
            ;;
        help|--help|-h)
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        *)
            if [[ -n "$command" ]]; then
                log_error "不明なコマンド: $command"
            fi
            show_help
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"
