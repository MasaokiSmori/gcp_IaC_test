# =============================================================
# Service Account: Cloud Composer
# prod: sa-composer-prod-runner (常時稼働の DAG 実行環境)
# stg : sa-composer-stg        (on-demand のテスト環境)
# =============================================================
locals {
  composer_sa_id = var.is_prod ? "sa-composer-prod-runner" : "sa-composer-stg"
}

resource "google_service_account" "composer" {
  project      = var.project_id
  account_id   = local.composer_sa_id
  display_name = "Cloud Composer SA (${local.composer_sa_id})"
}

# BigQuery: ジョブ実行権限 (プロジェクトレベル - ジョブはデータセットに紐付かないため)
resource "google_project_iam_member" "composer_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

# NOTE: BigQuery データセットレベルの dataEditor と GCS バケットレベルの objectAdmin は
#       environments/*/main.tf で個別バインディングとして設定する。
#       プロジェクトレベルでの付与は権限過剰となるため廃止。

# =============================================================
# Service Account: GitHub Actions (Terraform デプロイ用)
# =============================================================
resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "sa-github-actions-${var.env}"
  display_name = "GitHub Actions Terraform SA (${var.env})"
}

# Terraform が各種リソースを操作するための権限 (最小権限の原則に基づき個別ロールを付与)
# NOTE: roles/editor は過剰なため使用しない

resource "google_project_iam_member" "github_actions_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_composer_admin" {
  project = var.project_id
  role    = "roles/composer.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_service_account_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Terraform が IAM バインディングを管理するための権限
resource "google_project_iam_member" "github_actions_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# VPC SC 境界の管理は org レベル権限が必要 (prod のみ)
# roles/accesscontextmanager.policyAdmin はプロジェクト IAM では付与できないため org レベルで付与
resource "google_organization_iam_member" "github_actions_vpc_sc_admin" {
  count  = (var.is_prod && var.org_id != "") ? 1 : 0
  org_id = var.org_id
  role   = "roles/accesscontextmanager.policyAdmin"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}

# =============================================================
# Workload Identity Federation (WIF)
# GitHub Actions がキーファイルなしに認証するためのプール
# =============================================================
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool-${var.env}"
  display_name              = "GitHub Actions Pool (${var.env})"
  description               = "WIF pool for GitHub Actions CI/CD"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # リポジトリ単位でスコープを絞る
  attribute_condition = "assertion.repository == '${var.github_org}/${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# GitHub Actions SA に WIF 経由での impersonation を許可
resource "google_service_account_iam_member" "github_wif_binding" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${var.github_repo}"
}

# =============================================================
# Workspace Group IAM: Senior DS
# prod: BigQuery Admin (プロジェクトレベル)
# stg : Owner
# =============================================================
resource "google_project_iam_member" "senior_ds" {
  project = var.project_id
  role    = var.is_prod ? "roles/bigquery.admin" : "roles/owner"
  member  = "group:g-datascience-snr@${var.workspace_domain}"
}

# =============================================================
# Workspace Group IAM: Junior DS
# =============================================================
resource "google_project_iam_member" "junior_ds_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "group:g-datascience-jnr@${var.workspace_domain}"
}

resource "google_project_iam_member" "junior_ds_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "group:g-datascience-jnr@${var.workspace_domain}"
}

# stg のみ: Junior DS に Editor 権限
resource "google_project_iam_member" "junior_ds_stg_editor" {
  count   = var.is_prod ? 0 : 1
  project = var.project_id
  role    = "roles/editor"
  member  = "group:g-datascience-jnr@${var.workspace_domain}"
}

# prod のみ: Junior DS に prod_test Dataset の編集権限
# NOTE: この binding は bigquery module による prod_test dataset の作成後に適用される。
#       environments/prod/main.tf の depends_on で順序を保証すること。
resource "google_bigquery_dataset_iam_member" "junior_ds_prod_test_editor" {
  count      = var.is_prod ? 1 : 0
  project    = var.project_id
  dataset_id = "prod_test"
  role       = "roles/bigquery.dataEditor"
  member     = "group:g-datascience-jnr@${var.workspace_domain}"
}

# =============================================================
# Service Account: VM Bastion (DAG デプロイ用 on-demand VM)
# deploy_dags.sh が Composer の GCS バケットへ gsutil rsync するために使用
# =============================================================
resource "google_service_account" "vm_bastion" {
  project      = var.project_id
  account_id   = "sa-vm-${var.env}"
  display_name = "VM Bastion SA (${var.env})"
}

# NOTE: VM Bastion SA の GCS 権限はバケットレベルで付与する。
#       Composer DAG バケットへの書き込み権限は environments/*/main.tf で
#       Composer 作成後に google_storage_bucket_iam_member で設定する。

# stg のみ: terraform state バケットへの読み書き (vm-stg 上での terraform apply 用)
resource "google_storage_bucket_iam_member" "vm_bastion_terraform_state" {
  count  = var.is_prod ? 0 : 1
  bucket = "terraform-state-${var.env}"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_bastion.email}"
}

# IAP 経由の SSH 接続を許可
resource "google_project_iam_member" "vm_bastion_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "group:g-datascience-snr@${var.workspace_domain}"
}

# Junior DS の IAP SSH は stg のみ (prod の vm-prod へのアクセスは Senior DS のみ)
resource "google_project_iam_member" "vm_bastion_iap_tunnel_jnr" {
  count   = var.is_prod ? 0 : 1
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "group:g-datascience-jnr@${var.workspace_domain}"
}

# =============================================================
# stg のみ: vm-stg から composer-stg を作成・削除するための権限
# =============================================================

# composer-stg の作成・削除を terraform apply で実行できるようにする
resource "google_project_iam_member" "vm_bastion_composer_admin" {
  count   = var.is_prod ? 0 : 1
  project = var.project_id
  role    = "roles/composer.admin"
  member  = "serviceAccount:${google_service_account.vm_bastion.email}"
}

# composer-stg 作成時に sa-composer-stg を Composer へアタッチするための権限
resource "google_service_account_iam_member" "vm_stg_use_composer_sa" {
  count              = var.is_prod ? 0 : 1
  service_account_id = google_service_account.composer.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.vm_bastion.email}"
}

# terraform apply 実行時に既存リソースの状態を refresh するために必要な読み取り権限
resource "google_project_iam_member" "vm_bastion_viewer" {
  count   = var.is_prod ? 0 : 1
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.vm_bastion.email}"
}
