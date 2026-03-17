# NOTE: このバケットは terraform apply 前に手動で作成しておくこと。
# gcloud storage buckets create gs://terraform-state-stg \
#   --project=erp-dataplatform-stg \
#   --location=asia-northeast1 \
#   --uniform-bucket-level-access \
#   --enable-versioning
terraform {
  backend "gcs" {
    bucket = "terraform-state-stg"
    prefix = "terraform/state"
  }
}
