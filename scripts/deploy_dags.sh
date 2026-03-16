#!/bin/bash
# deploy_dags.sh
# DAG ファイルを Cloud Composer の GCS バケットへ同期する。
# prod / stg 共通。同期先 Composer 環境は COMPOSER_ENV_NAME 環境変数で切り替える。
# (Terraform の startup_script が VM 起動時に /etc/environment へ設定する)
#
# 使い方 (リポジトリルートから実行):
#   git pull
#   bash scripts/deploy_dags.sh

set -euo pipefail

REGION="${REGION:-asia-northeast1}"

# /etc/environment から COMPOSER_ENV_NAME を読み込む
# shellcheck source=/dev/null
source /etc/environment 2>/dev/null || true

if [[ -z "${COMPOSER_ENV_NAME:-}" ]]; then
  echo "ERROR: COMPOSER_ENV_NAME が設定されていません。" >&2
  echo "       VM の起動スクリプトが完了しているか確認してください。" >&2
  exit 1
fi

# PROJECT_ID は VM のメタデータから取得
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

echo "▶ Composer 環境: ${COMPOSER_ENV_NAME} (${PROJECT_ID})"
echo "▶ DAG_GCS_PREFIX を取得中..."

DAG_GCS_PREFIX=$(gcloud composer environments describe "${COMPOSER_ENV_NAME}" \
  --location="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(config.dagGcsPrefix)")

echo "▶ 同期先: ${DAG_GCS_PREFIX}/"
echo "▶ 同期元: ./dags/"

# --delete フラグにより、リポジトリから削除された DAG はバケットからも削除される
gsutil -m rsync -r -d ./dags/ "${DAG_GCS_PREFIX}/"

echo "✓ デプロイ完了: $(date)"
