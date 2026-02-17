locals {
  managed_services = setunion(
    var.enabled_services,
    toset([
      "compute.googleapis.com",
      "iam.googleapis.com",
      "logging.googleapis.com",
      "run.googleapis.com",
      "servicenetworking.googleapis.com",
      "secretmanager.googleapis.com",
      "sqladmin.googleapis.com",
    ])
  )
}

resource "google_project_service" "required" {
  for_each = local.managed_services

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "app" {
  project       = var.project_id
  location      = var.artifact_registry_location
  repository_id = var.artifact_registry_repository_id
  format        = var.artifact_registry_format
  description   = var.artifact_registry_description

  depends_on = [
    google_project_service.artifact_registry,
  ]
}

resource "google_compute_network" "private" {
  name                    = var.vpc_network_name
  project                 = var.project_id
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.required["compute.googleapis.com"],
  ]
}

resource "google_compute_subnetwork" "cloud_run" {
  name                     = var.cloud_run_subnetwork_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.private.id
  ip_cidr_range            = var.cloud_run_subnetwork_cidr
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_services" {
  project       = var.project_id
  name          = var.private_services_address_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_services_prefix_length
  network       = google_compute_network.private.id
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.private.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]

  depends_on = [
    google_project_service.required["servicenetworking.googleapis.com"],
  ]
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

resource "google_service_account" "cloud_run_runtime" {
  account_id   = var.cloud_run_service_account_id
  display_name = var.cloud_run_service_account_display_name
  project      = var.project_id

  depends_on = [
    google_project_service.required["iam.googleapis.com"],
  ]
}

resource "google_project_iam_member" "cloud_run_cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_runtime.email}"
}

resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_runtime.email}"
}

resource "google_secret_manager_secret" "django_secret_key" {
  project   = var.project_id
  secret_id = var.django_secret_key_secret_id

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.required["secretmanager.googleapis.com"],
  ]
}

resource "google_secret_manager_secret_version" "django_secret_key" {
  secret      = google_secret_manager_secret.django_secret_key.id
  secret_data = var.django_secret_key
}

resource "google_secret_manager_secret" "database_password" {
  project   = var.project_id
  secret_id = var.database_password_secret_id

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.required["secretmanager.googleapis.com"],
  ]
}

resource "google_secret_manager_secret_version" "database_password" {
  secret      = google_secret_manager_secret.database_password.id
  secret_data = var.database_password
}

resource "google_sql_database_instance" "django" {
  name                = var.cloud_sql_instance_name
  project             = var.project_id
  region              = var.region
  database_version    = var.cloud_sql_database_version
  deletion_protection = var.cloud_sql_deletion_protection

  settings {
    edition           = var.cloud_sql_edition
    tier              = var.cloud_sql_tier
    availability_type = var.cloud_sql_availability_type
    disk_type         = var.cloud_sql_disk_type
    disk_size         = var.cloud_sql_disk_size_gb
    disk_autoresize   = true

    backup_configuration {
      enabled = var.cloud_sql_backup_enabled
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.private.id
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = var.cloud_sql_ssl_mode
    }
  }

  depends_on = [
    google_project_service.required["sqladmin.googleapis.com"],
    google_service_networking_connection.private_services,
  ]
}

resource "google_sql_database" "django" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.django.name
}

resource "google_sql_user" "django" {
  name     = var.database_user
  project  = var.project_id
  instance = google_sql_database_instance.django.name
  password = var.database_password
}

resource "google_cloud_run_v2_service" "django" {
  name                = var.cloud_run_service_name
  location            = var.region
  project             = var.project_id
  ingress             = var.cloud_run_ingress
  deletion_protection = var.cloud_run_deletion_protection

  template {
    service_account = google_service_account.cloud_run_runtime.email
    timeout         = "300s"

    vpc_access {
      egress = var.cloud_run_vpc_egress

      network_interfaces {
        network    = google_compute_network.private.id
        subnetwork = google_compute_subnetwork.cloud_run.id
      }
    }

    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.django.connection_name]
      }
    }

    containers {
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "DB_NAME"
        value = google_sql_database.django.name
      }

      env {
        name  = "DB_USER"
        value = google_sql_user.django.name
      }

      env {
        name  = "DB_HOST"
        value = "/cloudsql/${google_sql_database_instance.django.connection_name}"
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "CLOUD_RUN_DIRECT_VPC_SUBNET_CIDR"
        value = var.cloud_run_subnetwork_cidr
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "DJANGO_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.django_secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "DJANGO_DEBUG"
        value = "False"
      }

      env {
        name  = "DJANGO_ALLOWED_HOSTS"
        value = var.django_allowed_hosts
      }

      env {
        name  = "DJANGO_CSRF_TRUSTED_ORIGINS"
        value = var.django_csrf_trusted_origins
      }

      env {
        name  = "DJANGO_SECURE_PROXY_SSL_HEADER"
        value = "HTTP_X_FORWARDED_PROTO,https"
      }

      env {
        name  = "DJANGO_SECURE_SSL_REDIRECT"
        value = "True"
      }

      env {
        name  = "DJANGO_SESSION_COOKIE_SECURE"
        value = "True"
      }

      env {
        name  = "DJANGO_CSRF_COOKIE_SECURE"
        value = "True"
      }

      env {
        name  = "DJANGO_LOG_LEVEL"
        value = var.django_log_level
      }

      env {
        name  = "WAIT_FOR_DB"
        value = "1"
      }

      env {
        name  = "RUN_MIGRATIONS"
        value = var.run_migrations_on_startup ? "1" : "0"
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [
    google_project_service.required["run.googleapis.com"],
    google_project_iam_member.cloud_run_cloud_sql_client,
    google_project_iam_member.cloud_run_secret_accessor,
    google_secret_manager_secret_version.database_password,
    google_secret_manager_secret_version.django_secret_key,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.cloud_run_allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.django.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
