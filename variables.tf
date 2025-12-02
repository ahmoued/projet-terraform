# --- Variables de Base de Données (PostgreSQL) ---
variable "db_name" {
  description = "Nom de la base de données PostgreSQL."
  type        = string
  default     = "devops_db"
}

variable "db_user" {
  description = "Nom d'utilisateur PostgreSQL."
  type        = string
  default     = "devops_user"
}

variable "db_password" {
  description = "Mot de passe PostgreSQL (ATTENTION: Simulé, ne pas utiliser en Prod !)"
  type        = string
  default     = "strongpassword123"
}

# --- Variables d'Application ---
variable "app_port_external" {
  description = "Port externe pour accéder à l'application web (mappé au 80 interne)."
  type        = number
  default     = 9090 # Changé de 8080 pour éviter les conflits
}

variable "db_port_external" {
  description = "Port externe pour accéder à PostgreSQL (mappé au 5432 interne)."
  type        = number
  default     = 5433 # Changé de 5432 pour éviter les conflits
}
