# Cloud Composer 3 (Small)
resource "google_composer_environment" "main" {
  project = var.project_id
  name    = var.name
  region  = var.region

  config {
    software_config {
      image_version = var.airflow_image_version
    }

    # Small サイズ相当のリソース設定
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }

      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }

      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      network         = var.network_id
      subnetwork      = var.subnet_id
      service_account = var.composer_sa_email
    }

    # prod/stg ともに Private Endpoint 有効 (VPC 内・IAP トンネル経由からのみ Airflow UI にアクセス可)
    private_environment_config {
      enable_private_endpoint          = var.enable_private_endpoint
      enable_privately_used_public_ips = false
    }
  }
}
