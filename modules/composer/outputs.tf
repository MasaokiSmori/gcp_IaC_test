output "dag_gcs_prefix" {
  description = "DAG ファイルを配置する GCS パス (gs://...)"
  value       = google_composer_environment.main.config[0].dag_gcs_prefix
}

output "airflow_uri" {
  description = "Airflow Web UI の URI"
  value       = google_composer_environment.main.config[0].airflow_uri
}

output "gke_cluster" {
  description = "Composer が使用する GKE クラスタ名"
  value       = google_composer_environment.main.config[0].gke_cluster
}
