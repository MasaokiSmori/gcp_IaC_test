variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "env" {
  description = "Environment name (prod or stg)"
  type        = string
}

variable "network_name" {
  description = "VPC network 名 (IAP SSH ファイアウォールルール用)"
  type        = string
}

variable "subnet_id" {
  description = "Subnetwork ID"
  type        = string
}

variable "service_account_email" {
  description = "VM に紐付ける Service Account のメールアドレス"
  type        = string
}

variable "composer_env_name" {
  description = "deploy_dags.sh が参照する Composer 環境名 (例: composer-prod-runner, composer-stg)"
  type        = string
}

variable "machine_type" {
  description = "VM マシンタイプ"
  type        = string
  default     = "e2-small"
}

variable "github_repo_url" {
  description = "git clone に使用する GitHub リポジトリの SSH URL (例: git@github.example.com:org/repo.git)"
  type        = string
}

variable "deploy_key_secret_name" {
  description = "SSH deploy key を格納した Secret Manager シークレット名 (VM 起動時に取得)"
  type        = string
}

variable "terraform_version" {
  description = "VM にインストールする Terraform のバージョン (CI/CD と合わせること)"
  type        = string
  default     = "1.9.8"
}
