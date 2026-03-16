variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "env" {
  description = "Environment name (prod or stg)"
  type        = string
}

variable "workspace_domain" {
  description = "Google Workspace ドメイン (通知先メールアドレスの生成に使用)"
  type        = string
}
