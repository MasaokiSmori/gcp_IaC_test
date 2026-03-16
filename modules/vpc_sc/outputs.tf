output "perimeter_name" {
  description = "VPC SC サービス境界の name"
  value       = google_access_context_manager_service_perimeter.prod.name
}
