variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region (BigQuery の location に使用)"
  type        = string
  default     = "asia-northeast1"
}

variable "env" {
  description = "Environment name (prod or stg)"
  type        = string
}

variable "is_prod" {
  description = "true の場合、prod_test データセットを追加作成する"
  type        = bool
  default     = false
}
