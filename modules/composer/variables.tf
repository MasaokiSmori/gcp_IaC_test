variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "env" {
  description = "Environment name (prod or stg)"
  type        = string
}

variable "name" {
  description = "Composer 環境名 (例: composer-prod-runner, composer-stg)"
  type        = string
}

variable "enable_private_endpoint" {
  description = "true: Airflow Web UI を VPC 内限定にする (prod). false: ブラウザから直接アクセス可 (stg)"
  type        = bool
  default     = true
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnetwork ID"
  type        = string
}

variable "composer_sa_email" {
  description = "Composer が使用する Service Account のメールアドレス"
  type        = string
}

variable "airflow_image_version" {
  description = "Cloud Composer 3 の image version (例: composer-3-airflow-2.10.2)"
  type        = string
  default     = "composer-3-airflow-2.10.2"
}
