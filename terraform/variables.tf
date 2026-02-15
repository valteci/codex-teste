variable "project_id" {
  description = "ID do projeto no Google Cloud."
  type        = string
}

variable "region" {
  description = "Regiao padrao para recursos que exigem localizacao."
  type        = string
  default     = "us-central1"
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
  description = "Lista minima de APIs que devem estar habilitadas no projeto."
  type        = set(string)
  default = [
    "iam.googleapis.com",
    "logging.googleapis.com",
  ]
}
