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
  env         = "prod"
  subnet_cidr = var.subnet_cidr
}

# =============================================================
# GCS
# =============================================================
module "storage" {
  source     = "../../modules/storage"
  project_id = var.project_id
  region     = var.region
  env        = "prod"
}

# =============================================================
# BigQuery
# =============================================================
module "bigquery" {
  source     = "../../modules/bigquery"
  project_id = var.project_id
  region     = var.region
  env        = "prod"
  is_prod    = true
}

# =============================================================
# IAM & WIF
# =============================================================
module "iam" {
  source           = "../../modules/iam"
  project_id       = var.project_id
  env              = "prod"
  workspace_domain = var.workspace_domain
  github_org       = var.github_org
  github_repo      = var.github_repo
  is_prod          = true

  depends_on = [module.bigquery]
}

# =============================================================
# Cloud Composer 3 (常時稼働 - 本番 DAG 実行専用)
# =============================================================
module "composer_prod_runner" {
  source                  = "../../modules/composer"
  project_id              = var.project_id
  region                  = var.region
  env                     = "prod"
  name                    = "composer-prod-runner"
  network_id              = module.vpc.network_id
  subnet_id               = module.vpc.subnet_id
  composer_sa_email       = module.iam.composer_sa_email
  enable_private_endpoint = true # prod: VPC 内からのみ Airflow UI にアクセス可
}

# =============================================================
# VM Bastion (on-demand - prod DAG デプロイ操作用)
# main マージ後に DS が SSH 接続して deploy_dags.sh を実行する
# =============================================================
module "vm_prod" {
  source                = "../../modules/vm_bastion"
  project_id            = var.project_id
  env                   = "prod"
  network_name          = module.vpc.network_name
  subnet_id             = module.vpc.subnet_id
  service_account_email = module.iam.vm_bastion_sa_email
  composer_env_name     = "composer-prod-runner"
}

# =============================================================
# VPC Service Controls
# prod を境界内に、ERP を境界外として ingress/egress を明示設定
# =============================================================
module "vpc_sc" {
  source                 = "../../modules/vpc_sc"
  access_policy_id       = var.access_policy_id
  prod_project_number    = var.prod_project_number
  erp_project_number     = var.erp_project_number
  erp_sa_email           = var.erp_sa_email
  prod_composer_sa_email = module.iam.composer_sa_email
  stg_composer_sa_email  = "sa-composer-stg@erp-dataplatform-stg.iam.gserviceaccount.com"

  depends_on = [module.iam]
}

# =============================================================
# クロスプロジェクト IAM
# stg の Composer SA に prod の erp_raw Dataset 読み取り権限を付与
# (本番生データを stg へコピーするユースケース用)
# =============================================================
resource "google_bigquery_dataset_iam_member" "stg_composer_read_prod_raw" {
  project    = var.project_id
  dataset_id = module.bigquery.erp_raw_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:sa-composer-stg@erp-dataplatform-stg.iam.gserviceaccount.com"
}
