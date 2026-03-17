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

BUCKET_ROOT="${DAG_GCS_PREFIX%/dags}"

echo "▶ バケットルート: ${BUCKET_ROOT}"

# dags/ — DAG 本体 (必須)
echo "▶ 同期中: ./dags/ → ${BUCKET_ROOT}/dags/"
gcloud storage rsync ./dags/ "${BUCKET_ROOT}/dags/" --recursive --delete-unmatched-destination-objects

# plugins/ — カスタム Operator・Hook 等 (存在する場合のみ)
if [[ -d ./plugins ]]; then
  echo "▶ 同期中: ./plugins/ → ${BUCKET_ROOT}/plugins/"
  gcloud storage rsync ./plugins/ "${BUCKET_ROOT}/plugins/" --recursive --delete-unmatched-destination-objects
fi

# data/ — SQL ファイル等 DAG から参照するデータ (存在する場合のみ)
if [[ -d ./data ]]; then
  echo "▶ 同期中: ./data/ → ${BUCKET_ROOT}/data/"
  gcloud storage rsync ./data/ "${BUCKET_ROOT}/data/" --recursive --delete-unmatched-destination-objects
fi

echo "✓ デプロイ完了: $(date)"
