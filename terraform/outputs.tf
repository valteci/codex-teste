output "alloy_service_account_email" {
  description = "Email da service account usada pelo Alloy."
  value       = google_service_account.alloy_logs.email
}

output "artifact_registry_repository_name" {
  description = "Nome completo do repositorio Artifact Registry criado."
  value       = google_artifact_registry_repository.app.name
}

output "artifact_registry_repository_url" {
  description = "Base da URL para tags de imagem no Artifact Registry."
  value       = "${google_artifact_registry_repository.app.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}

output "cloud_run_service_url" {
  description = "URL publica (quando liberada) do servico Cloud Run."
  value       = google_cloud_run_v2_service.django.uri
}

output "cloud_run_service_account_email" {
  description = "Email da service account de runtime do Cloud Run."
  value       = google_service_account.cloud_run_runtime.email
}

output "cloud_sql_connection_name" {
  description = "Connection name da instancia Cloud SQL."
  value       = google_sql_database_instance.django.connection_name
}

output "cloud_sql_instance_name" {
  description = "Nome da instancia Cloud SQL criada."
  value       = google_sql_database_instance.django.name
}

output "cloud_sql_database_name" {
  description = "Nome do banco de dados da aplicacao."
  value       = google_sql_database.django.name
}
