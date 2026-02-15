# Terraform - GCP Logging Basico

Este diretório foi simplificado para manter apenas o necessário para o cenário atual do projeto:

- habilitar APIs mínimas (`iam.googleapis.com` e `logging.googleapis.com`);
- garantir a service account `alloy-logs`;
- garantir o papel `roles/logging.logWriter` no projeto para essa service account.

## Uso

1. Autentique no GCP (Application Default Credentials):

```bash
gcloud auth application-default login
```

2. Copie o arquivo de exemplo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Ajuste `project_id` no `terraform.tfvars`.

4. Rode:

```bash
terraform init
terraform plan
terraform apply
```

## Import (se os recursos ja existem)

Se você já criou os recursos manualmente, importe antes do `apply`:

```bash
terraform import google_service_account.alloy_logs \
  projects/logs-teste/serviceAccounts/alloy-logs@logs-teste.iam.gserviceaccount.com

terraform import 'google_project_iam_member.alloy_logs_writer' \
  'logs-teste roles/logging.logWriter serviceAccount:alloy-logs@logs-teste.iam.gserviceaccount.com'

terraform import 'google_project_service.required["iam.googleapis.com"]' \
  logs-teste/iam.googleapis.com

terraform import 'google_project_service.required["logging.googleapis.com"]' \
  logs-teste/logging.googleapis.com
```
