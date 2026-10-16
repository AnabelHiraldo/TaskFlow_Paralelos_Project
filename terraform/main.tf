resource "google_artifact_registry_repository" "taskflow" {
  location      = var.region
  repository_id = "taskflow-images"
  description   = "Docker images for TaskFlow"
  format        = "DOCKER"
}

resource "google_service_account" "taskflow" {
  account_id   = "taskflow-run"
  display_name = "TaskFlow Cloud Run service account"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.taskflow.email}"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.taskflow.email}"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.taskflow.email}"
}

resource "google_sql_database_instance" "taskflow" {
  name                = "taskflow-postgres"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = false

  settings {
    edition           = "ENTERPRISE"
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_HDD"
    disk_size         = 10
    disk_autoresize   = false

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  depends_on = [
    google_project_iam_member.cloudsql_client
  ]
}

resource "google_sql_database" "taskflow" {
  name     = var.db_name
  instance = google_sql_database_instance.taskflow.name
}

resource "google_sql_user" "taskflow" {
  name     = var.db_user
  instance = google_sql_database_instance.taskflow.name
  password = var.db_password
}

resource "google_secret_manager_secret" "database_url" {
  secret_id = "taskflow-database-url"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "taskflow-jwt-secret"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "taskflow-db-password"

  replication {
    auto {}
  }
}

# Almacenamiento persistente para archivos subidos a TaskFlow
resource "google_storage_bucket" "taskflow_uploads" {
  name                        = "taskflow-uploads-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
}

# Permitir que el backend administre archivos en este bucket
resource "google_storage_bucket_iam_member" "taskflow_uploads" {
  bucket = google_storage_bucket.taskflow_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.taskflow.email}"
}


resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = var.jwt_secret
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "postgresql+psycopg://${var.db_user}:${urlencode(var.db_password)}@/${var.db_name}?host=/cloudsql/${google_sql_database_instance.taskflow.connection_name}"

  depends_on = [
    google_sql_database.taskflow,
    google_sql_user.taskflow
  ]
}

# Pub/Sub, Cloud Run de notificaciones y permisos mínimos para el flujo de correo.
resource "google_project_service" "notification_apis" {
  for_each = toset([
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "iam.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_pubsub_topic" "notifications" {
  name       = "taskflow-notifications"
  depends_on = [google_project_service.notification_apis]
}

resource "google_service_account" "notification_runtime" {
  account_id   = "taskflow-notifications"
  display_name = "TaskFlow notification Cloud Run runtime"
  depends_on   = [google_project_service.notification_apis]
}

resource "google_service_account" "pubsub_invoker" {
  account_id   = "taskflow-pubsub-invoker"
  display_name = "Pub/Sub identity for invoking notification Cloud Run"
  depends_on   = [google_project_service.notification_apis]
}

resource "google_service_account_iam_member" "deployer_uses_notification_runtime" {
  service_account_id = google_service_account.notification_runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deployment_service_account_email}"
}

resource "google_service_account_iam_member" "deployer_uses_pubsub_invoker" {
  service_account_id = google_service_account.pubsub_invoker.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deployment_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "backend_publish_notifications" {
  topic  = google_pubsub_topic.notifications.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.taskflow.email}"
}

resource "google_project_iam_member" "notification_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.notification_runtime.email}"
}

resource "google_secret_manager_secret" "smtp_username" {
  secret_id = "taskflow-smtp-username"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "smtp_password" {
  secret_id = "taskflow-smtp-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "smtp_username" {
  secret      = google_secret_manager_secret.smtp_username.id
  secret_data = var.smtp_username
}

resource "google_secret_manager_secret_version" "smtp_password" {
  secret      = google_secret_manager_secret.smtp_password.id
  secret_data = var.smtp_password
}

resource "google_secret_manager_secret_iam_member" "smtp_username_accessor" {
  secret_id = google_secret_manager_secret.smtp_username.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.notification_runtime.email}"
}

resource "google_secret_manager_secret_iam_member" "smtp_password_accessor" {
  secret_id = google_secret_manager_secret.smtp_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.notification_runtime.email}"
}

resource "google_cloud_run_v2_service" "notifications" {
  name                = "notification-cloud-run"
  location            = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.notification_runtime.email
    timeout         = "60s"
    scaling {
      max_instance_count = 5
    }
    containers {
      image = var.notification_image
      ports {
        container_port = 8080
      }
      env {
        name  = "SMTP_HOST"
        value = var.smtp_host
      }
      env {
        name  = "SMTP_PORT"
        value = tostring(var.smtp_port)
      }
      env {
        name  = "SMTP_FROM"
        value = var.smtp_from
      }
      env {
        name = "SMTP_USERNAME"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.smtp_username.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "SMTP_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.smtp_password.secret_id
            version = "latest"
          }
        }
      }
      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 0
        period_seconds        = 10
        timeout_seconds       = 3
        failure_threshold     = 6
      }
    }
  }

  depends_on = [
    google_project_service.notification_apis,
    google_secret_manager_secret_iam_member.smtp_username_accessor,
    google_secret_manager_secret_iam_member.smtp_password_accessor,
    google_secret_manager_secret_version.smtp_username,
    google_secret_manager_secret_version.smtp_password,
    google_service_account_iam_member.deployer_uses_notification_runtime,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "pubsub_invokes_notifications" {
  project  = var.project_id
  location = google_cloud_run_v2_service.notifications.location
  name     = google_cloud_run_v2_service.notifications.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
}

resource "google_project_service_identity" "pubsub" {
  provider   = google-beta
  project    = var.project_id
  service    = "pubsub.googleapis.com"
  depends_on = [google_project_service.notification_apis]
}

resource "google_service_account_iam_member" "pubsub_token_creator" {
  service_account_id = google_service_account.pubsub_invoker.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

resource "google_pubsub_subscription" "notifications_to_cloud_run" {
  name  = "taskflow-notifications-to-cloud-run"
  topic = google_pubsub_topic.notifications.id
  push_config {
    push_endpoint = "${google_cloud_run_v2_service.notifications.uri}/pubsub"
    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
      audience              = google_cloud_run_v2_service.notifications.uri
    }
  }
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
  depends_on = [
    google_cloud_run_v2_service_iam_member.pubsub_invokes_notifications,
    google_service_account_iam_member.pubsub_token_creator,
    google_service_account_iam_member.deployer_uses_pubsub_invoker,
  ]
}
