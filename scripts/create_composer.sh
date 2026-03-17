#!/bin/bash
# create_composer.sh
# composer-stg を Terraform で作成する。
# vm-stg 上のリポジトリルートから実行すること。
#
# 使い方:
#   bash scripts/create_composer.sh

set -euo pipefail

cd "$(dirname "$0")/../environments/stg"

terraform init -reconfigure
terraform apply \
  -target=module.composer_stg \
  -target=google_storage_bucket_iam_member.vm_bastion_composer_dag_bucket \
  -var="is_stg_active=true" \
  -auto-approve
