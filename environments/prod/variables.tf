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
  description = "git clone に使用する GitHub リポジトリの HTTPS URL (例: https://github.com/org/repo.git)"
  type        = string
}
