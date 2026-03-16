output "erp_ingest_raw_bucket_name" {
  description = "ERP 生データ用 GCS バケット名"
  value       = google_storage_bucket.erp_ingest_raw.name
}

output "erp_ingest_raw_bucket_url" {
  description = "ERP 生データ用 GCS バケット URL (gs://...)"
  value       = google_storage_bucket.erp_ingest_raw.url
}
