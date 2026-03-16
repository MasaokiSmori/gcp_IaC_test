variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "env" {
  description = "Environment name (prod or stg)"
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

variable "is_prod" {
  description = "true の場合は prod 向け IAM を適用"
  type        = bool
  default     = false
}

variable "org_id" {
  description = "GCP 組織 ID - GitHub Actions SA への VPC SC 管理権限付与に使用 (prod のみ)"
  type        = string
  default     = ""
}
