# ERP 生データロード先
resource "google_bigquery_dataset" "erp_raw" {
  project     = var.project_id
  dataset_id  = "erp_raw"
  location    = var.region
  description = "ERP からの生データロード先 (スキーマは初期手動作成、以降 DAG で管理)"

  # 生データ保持: 365日 (GCS ライフサイクルと合わせる)
  default_table_expiration_ms = 31536000000 # 365 days

  delete_contents_on_destroy = false
}

# クレンジング・中間処理用
resource "google_bigquery_dataset" "erp_stg" {
  project     = var.project_id
  dataset_id  = "erp_stg"
  location    = var.region
  description = "クレンジング・中間処理用"

  # 中間データ保持: 180日
  default_table_expiration_ms = 15552000000 # 180 days

  delete_contents_on_destroy = false
}

# ビジネスサイド公開用
resource "google_bigquery_dataset" "erp_mart" {
  project     = var.project_id
  dataset_id  = "erp_mart"
  location    = var.region
  description = "ビジネスサイド公開用（大判テーブル）"

  # mart は有効期限なし (ビジネスサイドが参照するため永続)

  delete_contents_on_destroy = false
}

# 開発者用の砂場（prod のみ）
resource "google_bigquery_dataset" "prod_test" {
  count = var.is_prod ? 1 : 0

  project     = var.project_id
  dataset_id  = "prod_test"
  location    = var.region
  description = "開発者用の砂場 (prod 環境のみ)"

  # 砂場テーブル: 30日で自動削除
  default_table_expiration_ms = 2592000000 # 30 days

  delete_contents_on_destroy = true
}
