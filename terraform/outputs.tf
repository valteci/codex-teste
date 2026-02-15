output "alloy_service_account_email" {
  description = "Email da service account usada pelo Alloy."
  value       = google_service_account.alloy_logs.email
}
