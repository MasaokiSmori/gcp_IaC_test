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
