output "vm_name" {
  description = "VM インスタンス名"
  value       = google_compute_instance.bastion.name
}

output "vm_self_link" {
  description = "VM の self link"
  value       = google_compute_instance.bastion.self_link
}
