# ERP 生データの日次アップロード先
resource "google_storage_bucket" "erp_ingest_raw" {
  project                     = var.project_id
  name                        = "erp-ingest-raw-${var.env}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  # 誤上書き・誤削除からの復旧用
  versioning {
    enabled = true
  }

  # コスト最適化: 段階的にストレージクラスを遷移させてから削除
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  # バージョニング有効時、古い世代のオブジェクトも自動削除
  lifecycle_rule {
    condition {
      age                = 30
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }
}

# NOTE: terraform-state-[env] バケットは bootstrap 時に手動で作成すること。
# Terraform 自身の state を管理するバケットを Terraform で作るとチキンエッグ問題が生じるため。
# 作成後、アクセス制限は以下の通り設定する:
#   - prod: WIF 経由の Terraform SA のみ書き込み可。人間は直接アクセス不可。
#   - stg : 上記に加え、Senior DS グループに読み取り専用権限を付与。
