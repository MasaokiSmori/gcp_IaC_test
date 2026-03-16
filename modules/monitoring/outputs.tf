output "notification_channel_id" {
  description = "通知チャンネルの ID"
  value       = google_monitoring_notification_channel.email.id
}
