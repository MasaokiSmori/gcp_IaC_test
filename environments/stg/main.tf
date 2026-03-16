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
  enable_private_endpoint = true # stg: VPC 内 (IAP トンネル経由) からのみ Airflow UI にアクセス可
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
  composer_env_name     = "composer-stg"
}
