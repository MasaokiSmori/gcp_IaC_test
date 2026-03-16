output "erp_raw_dataset_id" {
  description = "erp_raw データセット ID"
  value       = google_bigquery_dataset.erp_raw.dataset_id
}

output "erp_stg_dataset_id" {
  description = "erp_stg データセット ID"
  value       = google_bigquery_dataset.erp_stg.dataset_id
}

output "erp_mart_dataset_id" {
  description = "erp_mart データセット ID"
  value       = google_bigquery_dataset.erp_mart.dataset_id
}
