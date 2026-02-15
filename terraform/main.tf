resource "google_project_service" "required" {
  for_each = var.enabled_services

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_service_account" "alloy_logs" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  project      = var.project_id

  depends_on = [
    google_project_service.required["iam.googleapis.com"],
  ]
}

resource "google_project_iam_member" "alloy_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.alloy_logs.email}"

  depends_on = [
    google_project_service.required["logging.googleapis.com"],
  ]
}
