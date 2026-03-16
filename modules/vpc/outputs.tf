output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Main subnet ID"
  value       = google_compute_subnetwork.main.id
}

output "subnet_name" {
  description = "Main subnet name"
  value       = google_compute_subnetwork.main.name
}
