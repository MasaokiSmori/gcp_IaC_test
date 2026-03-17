# =============================================================
# Cloud Monitoring: Composer 環境の監視・アラート
# =============================================================

# 通知チャンネル: Senior DS グループへメール通知
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Senior DS Email (${var.env})"
  type         = "email"

  labels = {
    email_address = "g-datascience-snr@${var.workspace_domain}"
  }
}

# ----------------------------------------------------------
# Composer 環境の健全性監視
# environment.healthy が false になったらアラート
# ----------------------------------------------------------
resource "google_monitoring_alert_policy" "composer_health" {
  project      = var.project_id
  display_name = "Composer Environment Unhealthy (${var.env})"
  combiner     = "OR"

  conditions {
    display_name = "Composer environment is unhealthy"

    condition_threshold {
      filter          = "resource.type = \"cloud_composer_environment\" AND metric.type = \"composer.googleapis.com/environment/healthy\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "300s" # 5分間連続で unhealthy

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MIN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s" # 30分で自動クローズ
  }
}

# ----------------------------------------------------------
# DAG 実行失敗の監視
# dag_run の failed 状態を検知
# ----------------------------------------------------------
resource "google_monitoring_alert_policy" "dag_failure" {
  project      = var.project_id
  display_name = "Composer DAG Run Failed (${var.env})"
  combiner     = "OR"

  conditions {
    display_name = "DAG run failed"

    condition_threshold {
      filter          = "resource.type = \"cloud_composer_environment\" AND metric.type = \"composer.googleapis.com/environment/finished_task_instance_count\" AND metric.labels.state = \"failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

# ----------------------------------------------------------
# Composer ワーカーの Pod 退避 (Eviction) 監視
# メモリ不足等で Pod が退避された場合に通知
# ----------------------------------------------------------
resource "google_monitoring_alert_policy" "composer_worker_eviction" {
  project      = var.project_id
  display_name = "Composer Worker Pod Evicted (${var.env})"
  combiner     = "OR"

  conditions {
    display_name = "Worker pod evictions detected"

    condition_threshold {
      filter          = "resource.type = \"cloud_composer_environment\" AND metric.type = \"composer.googleapis.com/environment/worker/pod_eviction_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

# ----------------------------------------------------------
# Composer スケジューラーのハートビート監視
# スケジューラーが応答しなくなった場合に通知
# ----------------------------------------------------------
resource "google_monitoring_alert_policy" "scheduler_heartbeat" {
  project      = var.project_id
  display_name = "Composer Scheduler Heartbeat Missing (${var.env})"
  combiner     = "OR"

  conditions {
    display_name = "Scheduler heartbeat missing"

    condition_absent {
      filter   = "resource.type = \"cloud_composer_environment\" AND metric.type = \"composer.googleapis.com/environment/scheduler_heartbeat_count\""
      duration = "600s" # 10分間ハートビートなし

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}
