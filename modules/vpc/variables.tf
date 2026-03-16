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

variable "subnet_cidr" {
  description = "CIDR range for the main subnet"
  type        = string
}
