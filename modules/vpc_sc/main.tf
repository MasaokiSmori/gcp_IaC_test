# =============================================================
# VPC Service Controls - prod サービス境界
#
# prod プロジェクトを囲み、BigQuery / GCS への外部 API アクセスを遮断する。
# ERP は境界外のため、ingress/egress ルールで通信を明示的に許可する。
# =============================================================
resource "google_access_context_manager_service_perimeter" "prod" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/servicePerimeters/erp_dataplatform_prod"
  title  = "erp-dataplatform-prod"

  status {
    # 境界内に含めるプロジェクト
    resources = ["projects/${var.prod_project_number}"]

    # アクセスを制限する GCP サービス
    restricted_services = [
      "bigquery.googleapis.com",
      "storage.googleapis.com",
    ]

    # ----------------------------------------------------------
    # Ingress: ERP SA → prod GCS (erp-ingest-raw-prod への生データ書き込み)
    # ERP チームが別プロジェクトから生データをアップロードするユースケース
    # ----------------------------------------------------------
    ingress_policies {
      ingress_from {
        identities = ["serviceAccount:${var.erp_sa_email}"]
        sources {
          resource = "projects/${var.erp_project_number}"
        }
      }
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "google.storage.objects.create"
          }
          method_selectors {
            method = "google.storage.objects.list"
          }
        }
      }
    }

    # ----------------------------------------------------------
    # Ingress: stg Composer SA → prod erp_raw BQ
    # stg の DAG が prod 生データを参照するユースケース
    # ----------------------------------------------------------
    ingress_policies {
      ingress_from {
        identities = ["serviceAccount:${var.stg_composer_sa_email}"]
      }
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "bigquery.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }
    }

    # ----------------------------------------------------------
    # Egress: prod Composer → ERP プロジェクト BQ
    # DAG がプル型で ERP データを直接取得する場合のみ使用。
    # ERP への書き戻しは行わないため、bigquery 読み取りのみ許可。
    # ----------------------------------------------------------
    egress_policies {
      egress_from {
        identities = ["serviceAccount:${var.prod_composer_sa_email}"]
      }
      egress_to {
        resources = ["projects/${var.erp_project_number}"]
        operations {
          service_name = "bigquery.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }
    }
  }
}
