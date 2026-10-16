variable "project_id" {
  description = "ID del proyecto de Google Cloud"
  type        = string
}

variable "region" {
  description = "Region principal de Google Cloud"
  type        = string
  default     = "us-central1"
}

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  type        = string
  default     = "taskflow"
}

variable "db_user" {
  description = "Usuario de PostgreSQL"
  type        = string
  default     = "taskflow_user"
}

variable "db_password" {
  description = "Contrasena de PostgreSQL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Clave secreta para JWT"
  type        = string
  sensitive   = true
}

variable "notification_image" {
  description = "Imagen de Artifact Registry para notification-cloud-run"
  type        = string
}

variable "smtp_host" {
  description = "Servidor SMTP para el envío de notificaciones"
  type        = string
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "Puerto SMTP (465 SSL o 587 STARTTLS)"
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "Usuario SMTP"
  type        = string
  sensitive   = true
}

variable "smtp_password" {
  description = "Contraseña o contraseña de aplicación SMTP"
  type        = string
  sensitive   = true
}

variable "smtp_from" {
  description = "Dirección remitente verificada por el proveedor SMTP"
  type        = string
}

variable "deployment_service_account_email" {
  description = "Cuenta de servicio de GitHub Actions que aplica Terraform"
  type        = string
  default     = "taskflow-github-deploy@project-8545473a-2e97-44ae-9bd.iam.gserviceaccount.com"
}
