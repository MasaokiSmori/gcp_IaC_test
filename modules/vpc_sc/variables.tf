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

variable "prod_composer_sa_email" {
  description = "prod Composer SA のメール (sa-composer-prod-runner)"
  type        = string
}

variable "stg_composer_sa_email" {
  description = "stg Composer SA のメール (sa-composer-stg) - prod erp_raw への ingress 許可用"
  type        = string
}

variable "github_actions_sa_email" {
  description = "GitHub Actions SA のメール (sa-github-actions-prod) - Terraform apply 用"
  type        = string
}
