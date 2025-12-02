# --- Configuration Terraform et Provider ---

terraform {
  required_providers {
    docker = {
      source  = "terraform-providers/docker"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# --- 1. Ressource : Base de Données PostgreSQL ---

# Télécharge l'image PostgreSQL depuis Docker Hub
resource "docker_image" "postgres_image" {
  name         = "postgres:latest"
  keep_locally = true
}

# Crée et configure le conteneur PostgreSQL
resource "docker_container" "db_container" {
  name  = "tp-db-postgres"
  image = docker_image.postgres_image.latest

  ports {
    internal = 5432
    external = var.db_port_external # Utilise la variable pour éviter les conflits
  }

  # Configuration de la DB via les variables d'environnement
  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
  ]
}

# --- 2. Ressource : Application Web Nginx ---

# Construit l'image Docker via null_resource
resource "null_resource" "build_app_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/Dockerfile_app")
  }

  provisioner "local-exec" {
    command = "docker build -f Dockerfile_app -t tp-web-app:latest ."
  }
}

# Référence l'image construite
resource "docker_image" "app_image" {
  name         = "tp-web-app:latest"
  keep_locally = true

  depends_on = [null_resource.build_app_image]
}

# Crée le conteneur de l'application web
resource "docker_container" "app_container" {
  name  = "tp-app-web"
  image = docker_image.app_image.latest

  # Dépendance explicite : la DB doit être prête avant l'Application
  depends_on = [
    docker_container.db_container
  ]

  # Mappage du port 80 interne au port externe défini dans variables.tf (par défaut 8080)
  ports {
    internal = 80
    external = var.app_port_external
  }
}
