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

variable "composer_always_on" {
  description = "Composer が常時稼働か (true=prod)。false の場合、condition_absent 系アラートを無効化する"
  type        = bool
  default     = true
}
