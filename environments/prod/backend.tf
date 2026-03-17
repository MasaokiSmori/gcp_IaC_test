# NOTE: このバケットは terraform apply 前に手動で作成しておくこと。
# gcloud storage buckets create gs://terraform-state-prod \
#   --project=erp-dataplatform-prod \
#   --location=asia-northeast1 \
#   --uniform-bucket-level-access \
#   --enable-versioning
terraform {
  backend "gcs" {
    bucket = "terraform-state-prod"
    prefix = "terraform/state"
  }
}
