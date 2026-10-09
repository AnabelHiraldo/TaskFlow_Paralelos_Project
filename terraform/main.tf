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

