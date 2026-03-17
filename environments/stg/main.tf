terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# =============================================================
# VPC
# =============================================================
module "vpc" {
  source      = "../../modules/vpc"
  project_id  = var.project_id
  region      = var.region
  env         = "stg"
  subnet_cidr = var.subnet_cidr
}

# =============================================================
# GCS
# =============================================================
module "storage" {
  source     = "../../modules/storage"
  project_id = var.project_id
  region     = var.region
  env        = "stg"
}

# =============================================================
# BigQuery (prod_test なし)
# =============================================================
module "bigquery" {
  source     = "../../modules/bigquery"
  project_id = var.project_id
  region     = var.region
  env        = "stg"
  is_prod    = false
}

# =============================================================
# IAM & WIF
# =============================================================
module "iam" {
  source           = "../../modules/iam"
  project_id       = var.project_id
  env              = "stg"
  workspace_domain = var.workspace_domain
  github_org       = var.github_org
  github_repo      = var.github_repo
  is_prod          = false
}

# =============================================================
# Monitoring (Composer 環境の健全性・DAG 失敗・スケジューラー監視)
# NOTE: stg でも監視を有効化。composer-stg が存在しない場合、
#       メトリクスが発生しないためアラートは発火しない。
# =============================================================
module "monitoring" {
  source           = "../../modules/monitoring"
  project_id       = var.project_id
  env              = "stg"
  workspace_domain = var.workspace_domain
}

# =============================================================
# Cloud Composer 3 - stg (on-demand, count方式)
#
# is_stg_active = true  → composer-stg を作成
# is_stg_active = false → composer-stg を削除 (リソース未作成)
#
# CI/CD は常に is_stg_active=false を渡すため、この環境には触れない。
# DS が vm-stg 上で以下を実行してライフサイクルを管理する:
#   作成: terraform apply -target=module.composer_stg -var="is_stg_active=true"
#   削除: terraform apply -target=module.composer_stg -var="is_stg_active=false"
# =============================================================
module "composer_stg" {
  count = var.is_stg_active ? 1 : 0

  source                  = "../../modules/composer"
  project_id              = var.project_id
  region                  = var.region
  env                     = "stg"
  name                    = "composer-stg"
  network_id              = module.vpc.network_id
  subnet_id               = module.vpc.subnet_id
  composer_sa_email       = module.iam.composer_sa_email
  enable_private_endpoint = false # stg: Airflow Web UI へ直接アクセス可 (prod は true)
}

# =============================================================
# VM Bastion (on-demand - stg DAG デプロイ・composer-stg 管理用)
# Terraform がインストール済み。DS が SSH 接続して以下を実行する:
#   composer-stg 作成: terraform apply -target=module.composer_stg -var="is_stg_active=true"
#   DAG 同期        : git pull && bash scripts/deploy_dags.sh
#   composer-stg 削除: terraform apply -target=module.composer_stg -var="is_stg_active=false"
# =============================================================
module "vm_stg" {
  source                = "../../modules/vm_bastion"
  project_id            = var.project_id
  env                   = "stg"
  network_name          = module.vpc.network_name
  subnet_id             = module.vpc.subnet_id
  service_account_email = module.iam.vm_bastion_sa_email
  composer_env_name      = "composer-stg"
  github_repo_url        = var.github_repo_url
  deploy_key_secret_name = var.deploy_key_secret_name
}

# =============================================================
# バケットレベル IAM (最小権限: プロジェクトレベルではなくバケット単位で付与)
# =============================================================

# Composer SA → erp-ingest-raw バケット (DAG が生データを読み書き)
resource "google_storage_bucket_iam_member" "composer_erp_ingest_raw" {
  bucket = module.storage.erp_ingest_raw_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.iam.composer_sa_email}"
}

# VM Bastion SA → Composer DAG バケット (deploy_dags.sh で DAG を同期)
# NOTE: composer-stg は count 方式で存在しない場合があるため、
#       Composer 存在時のみバインディングを作成する。
resource "google_storage_bucket_iam_member" "vm_bastion_composer_dag_bucket" {
  count  = var.is_stg_active ? 1 : 0
  bucket = module.composer_stg[0].dag_gcs_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.iam.vm_bastion_sa_email}"
}

# =============================================================
# データセットレベル BigQuery IAM
# Composer SA にはプロジェクトレベルではなくデータセット単位で dataEditor を付与。
# =============================================================
resource "google_bigquery_dataset_iam_member" "composer_erp_raw_editor" {
  project    = var.project_id
  dataset_id = module.bigquery.erp_raw_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.iam.composer_sa_email}"
}

resource "google_bigquery_dataset_iam_member" "composer_erp_stg_editor" {
  project    = var.project_id
  dataset_id = module.bigquery.erp_stg_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.iam.composer_sa_email}"
}

resource "google_bigquery_dataset_iam_member" "composer_erp_mart_editor" {
  project    = var.project_id
  dataset_id = module.bigquery.erp_mart_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.iam.composer_sa_email}"
}
