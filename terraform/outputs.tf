output "artifact_registry_repository" {
  value = google_artifact_registry_repository.taskflow.name
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.taskflow.repository_id}"
}

output "cloud_sql_connection_name" {
  value = google_sql_database_instance.taskflow.connection_name
}

output "database_name" {
  value = google_sql_database.taskflow.name
}

output "service_account_email" {
  value = google_service_account.taskflow.email
}

output "database_secret_name" {
  value = google_secret_manager_secret.database_url.secret_id
}

output "jwt_secret_name" {
  value = google_secret_manager_secret.jwt_secret.secret_id
}

output "uploads_bucket_name" {
  value = google_storage_bucket.taskflow_uploads.name
}

output "notification_topic" {
  value = google_pubsub_topic.notifications.name
}

output "notification_cloud_run_url" {
  value = google_cloud_run_v2_service.notifications.uri
}

output "notification_subscription" {
  value = google_pubsub_subscription.notifications_to_cloud_run.name
}
