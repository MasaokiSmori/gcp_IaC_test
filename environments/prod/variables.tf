variable "project_id" {
  description = "GCP Project ID (prod)"
  type        = string
  default     = "erp-dataplatform-prod"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "subnet_cidr" {
  description = "prod VPC メインサブネットの CIDR"
  type        = string
}

variable "workspace_domain" {
  description = "Google Workspace ドメイン (例: example.com)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization または user 名"
  type        = string
}

variable "github_repo" {
  description = "GitHub リポジトリ名"
  type        = string
}

variable "github_repo_url" {
  description = "git clone に使用する GitHub リポジトリの SSH URL (例: git@github.example.com:org/repo.git)"
  type        = string
}

variable "deploy_key_secret_name" {
  description = "SSH deploy key を格納した Secret Manager シークレット名"
  type        = string
  default     = "github-deploy-key"
}

variable "org_id" {
  description = "GCP 組織 ID (GitHub Actions SA への VPC SC 権限付与に使用)"
  type        = string
}

variable "access_policy_id" {
  description = "Access Context Manager ポリシー ID (数値のみ, 例: 1234567890)"
  type        = string
}

variable "prod_project_number" {
  description = "erp-dataplatform-prod のプロジェクト番号"
  type        = string
}

variable "erp_project_number" {
  description = "ERP ソースプロジェクトのプロジェクト番号"
  type        = string
}

variable "erp_sa_email" {
  description = "ERP プロジェクトで生データを prod GCS へアップロードする SA のメール"
  type        = string
}

variable "stg_project_id" {
  description = "stg GCP Project ID - クロスプロジェクト IAM の SA メール生成に使用"
  type        = string
  default     = "erp-dataplatform-stg"
}
