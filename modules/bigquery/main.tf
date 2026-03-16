# ERP 生データロード先
resource "google_bigquery_dataset" "erp_raw" {
  project     = var.project_id
  dataset_id  = "erp_raw"
  location    = var.region
  description = "ERP からの生データロード先 (スキーマは初期手動作成、以降 DAG で管理)"

  delete_contents_on_destroy = false
}

# クレンジング・中間処理用
resource "google_bigquery_dataset" "erp_stg" {
  project     = var.project_id
  dataset_id  = "erp_stg"
  location    = var.region
  description = "クレンジング・中間処理用"

  delete_contents_on_destroy = false
}

# ビジネスサイド公開用
resource "google_bigquery_dataset" "erp_mart" {
  project     = var.project_id
  dataset_id  = "erp_mart"
  location    = var.region
  description = "ビジネスサイド公開用（大判テーブル）"

  delete_contents_on_destroy = false
}

# 開発者用の砂場（prod のみ）
resource "google_bigquery_dataset" "prod_test" {
  count = var.is_prod ? 1 : 0

  project     = var.project_id
  dataset_id  = "prod_test"
  location    = var.region
  description = "開発者用の砂場 (prod 環境のみ)"

  delete_contents_on_destroy = true
}
