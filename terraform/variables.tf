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
