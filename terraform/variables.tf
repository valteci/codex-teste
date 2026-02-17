variable "project_id" {
  description = "ID do projeto no Google Cloud."
  type        = string
}

variable "region" {
  description = "Regiao padrao para recursos que exigem localizacao."
  type        = string
  default     = "us-central1"
}

variable "container_image" {
  description = "Imagem de container usada no Cloud Run (Artifact Registry ou outro registry suportado)."
  type        = string
}

variable "artifact_registry_repository_id" {
  description = "Repository ID do Artifact Registry para imagens Docker da aplicacao."
  type        = string
  default     = "django-project"
}

variable "artifact_registry_location" {
  description = "Regiao do repositório no Artifact Registry."
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_format" {
  description = "Formato do repositorio no Artifact Registry."
  type        = string
  default     = "DOCKER"
}

variable "artifact_registry_description" {
  description = "Descricao do repositorio no Artifact Registry."
  type        = string
  default     = "Docker images do Django project"
}

variable "cloud_run_service_name" {
  description = "Nome do servico Cloud Run."
  type        = string
  default     = "django-app"
}

variable "cloud_run_service_account_id" {
  description = "Account ID da service account usada pelo runtime do Cloud Run."
  type        = string
  default     = "cloud-run-django"
}

variable "cloud_run_service_account_display_name" {
  description = "Display name da service account do runtime Cloud Run."
  type        = string
  default     = "Cloud Run Django Runtime"
}

variable "cloud_run_ingress" {
  description = "Controle de ingress do Cloud Run."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "cloud_run_allow_unauthenticated" {
  description = "Se true, publica o servico para acesso sem autenticacao (allUsers)."
  type        = bool
  default     = true
}

variable "cloud_run_deletion_protection" {
  description = "Protecao contra delecao acidental do servico Cloud Run."
  type        = bool
  default     = false
}

variable "cloud_run_min_instances" {
  description = "Numero minimo de instancias do Cloud Run."
  type        = number
  default     = 0
}

variable "cloud_run_max_instances" {
  description = "Numero maximo de instancias do Cloud Run."
  type        = number
  default     = 3
}

variable "cloud_run_cpu" {
  description = "Limite de CPU por instancia no Cloud Run."
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Limite de memoria por instancia no Cloud Run."
  type        = string
  default     = "512Mi"
}

variable "container_port" {
  description = "Porta exposta pelo container do Django."
  type        = number
  default     = 8000
}

variable "run_migrations_on_startup" {
  description = "Se true, executa migrate no startup do container."
  type        = bool
  default     = false
}

variable "cloud_sql_instance_name" {
  description = "Nome da instancia Cloud SQL."
  type        = string
  default     = "django-postgres"
}

variable "cloud_sql_database_version" {
  description = "Versao do PostgreSQL no Cloud SQL."
  type        = string
  default     = "POSTGRES_16"
}

variable "cloud_sql_edition" {
  description = "Edicao do Cloud SQL (ENTERPRISE ou ENTERPRISE_PLUS)."
  type        = string
  default     = "ENTERPRISE"
}

variable "cloud_sql_tier" {
  description = "Tier da instancia Cloud SQL."
  type        = string
  default     = "db-custom-1-3840"
}

variable "cloud_sql_disk_type" {
  description = "Tipo de disco da instancia Cloud SQL."
  type        = string
  default     = "PD_SSD"
}

variable "cloud_sql_disk_size_gb" {
  description = "Tamanho inicial do disco (GB) da instancia Cloud SQL."
  type        = number
  default     = 20
}

variable "cloud_sql_availability_type" {
  description = "Tipo de disponibilidade do Cloud SQL (ZONAL ou REGIONAL)."
  type        = string
  default     = "ZONAL"
}

variable "cloud_sql_backup_enabled" {
  description = "Habilita backup automatico no Cloud SQL."
  type        = bool
  default     = true
}

variable "cloud_sql_deletion_protection" {
  description = "Protecao contra delecao acidental do Cloud SQL."
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Nome do banco de dados da aplicacao."
  type        = string
  default     = "django_project"
}

variable "database_user" {
  description = "Usuario do banco de dados da aplicacao."
  type        = string
  default     = "django"
}

variable "database_password" {
  description = "Senha do usuario do banco de dados da aplicacao."
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Valor de DJANGO_SECRET_KEY usado em producao."
  type        = string
  sensitive   = true
}

variable "django_allowed_hosts" {
  description = "Valor de DJANGO_ALLOWED_HOSTS para o deploy no Cloud Run."
  type        = string
  default     = ".run.app"
}

variable "django_csrf_trusted_origins" {
  description = "Valor de DJANGO_CSRF_TRUSTED_ORIGINS para o deploy no Cloud Run."
  type        = string
  default     = ""
}

variable "django_log_level" {
  description = "Nivel de log do Django em producao."
  type        = string
  default     = "INFO"
}

variable "django_secret_key_secret_id" {
  description = "Secret ID no Secret Manager para DJANGO_SECRET_KEY."
  type        = string
  default     = "django-secret-key"
}

variable "database_password_secret_id" {
  description = "Secret ID no Secret Manager para a senha do banco."
  type        = string
  default     = "django-db-password"
}

variable "service_account_id" {
  description = "Account ID da service account do Alloy."
  type        = string
  default     = "alloy-logs"
}

variable "service_account_display_name" {
  description = "Display name da service account."
  type        = string
  default     = "Alloy -> Cloud Logging"
}

variable "enabled_services" {
  description = "Lista minima de APIs gerais que devem estar habilitadas no projeto (exceto Artifact Registry)."
  type        = set(string)
  default = [
    "iam.googleapis.com",
    "logging.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
  ]
}
