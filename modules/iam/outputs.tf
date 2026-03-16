output "composer_sa_email" {
  description = "Composer Service Account のメールアドレス"
  value       = google_service_account.composer.email
}

output "github_actions_sa_email" {
  description = "GitHub Actions 用 Service Account のメールアドレス"
  value       = google_service_account.github_actions.email
}

output "wif_provider_name" {
  description = "WIF Provider のフルリソース名 (GitHub Actions の workload_identity_provider に設定する値)"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "vm_bastion_sa_email" {
  description = "VM Bastion Service Account のメールアドレス"
  value       = google_service_account.vm_bastion.email
}
