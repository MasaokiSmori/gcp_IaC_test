variable "project_id" {
  description = "GCP Project ID (stg)"
  type        = string
  default     = "erp-dataplatform-stg"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "subnet_cidr" {
  description = "stg VPC メインサブネットの CIDR (prod と重複しないこと)"
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
  description = "git clone に使用する GitHub リポジトリの HTTPS URL (例: https://github.com/org/repo.git)"
  type        = string
}

variable "is_stg_active" {
  description = <<-EOT
    composer-stg の作成フラグ。
    true  → composer-stg を作成する (DS が vm-stg から手動で apply する場合のみ)
    false → composer-stg を作成しない (デフォルト・CI/CD は常にこの値を使用)
  EOT
  type        = bool
  default     = false
}
