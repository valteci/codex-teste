# Terraform - Cloud Run + Cloud SQL

Este diretório provisiona a base de infra para publicar o Django no Google Cloud:

- APIs necessárias (`run`, `sqladmin`, `secretmanager`, `iam`, `logging`, etc.);
- Artifact Registry (repositório Docker para imagens da aplicação);
- Cloud SQL PostgreSQL (instância, database e usuário);
- Cloud Run v2 (serviço e IAM de invocação pública opcional);
- Service account dedicada ao runtime do Cloud Run;
- IAM mínimo para o runtime (`roles/cloudsql.client` e `roles/secretmanager.secretAccessor`);
- Secret Manager para `DJANGO_SECRET_KEY` e senha do banco;
- service account do Alloy com `roles/logging.logWriter` (mantida para observabilidade local).

## Pré-requisitos

1. Autenticar no GCP com ADC:

```bash
gcloud auth application-default login
```

2. Build/publish da imagem Docker do app em um registry acessível pelo Cloud Run.

## Uso

1. Copie o exemplo de variáveis:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edite os valores obrigatórios no `terraform.tfvars`:

- `project_id`
- `container_image`
- `database_password`
- `django_secret_key`

3. (Opcional, recomendado) Crie apenas o repositório do Artifact Registry primeiro:

```bash
terraform init
terraform apply -target=google_artifact_registry_repository.app
```

4. Publique a imagem no repositório criado:

```bash
REPO_URL="$(terraform output -raw artifact_registry_repository_url)"
gcloud auth configure-docker "$(echo "$REPO_URL" | cut -d/ -f1)"
docker build -t "${REPO_URL}/django-project:latest" ..
docker push "${REPO_URL}/django-project:latest"
```

5. Execute o apply completo:

```bash
terraform plan
terraform apply
```

## Variáveis importantes

- `django_allowed_hosts`: default `.run.app`.
- `django_csrf_trusted_origins`: deve incluir a URL HTTPS do Cloud Run e/ou domínio customizado.
- `cloud_run_allow_unauthenticated`: `true` para API/site público.
- `run_migrations_on_startup`: se `true`, o container roda `migrate` ao iniciar.
- `cloud_sql_edition`: use `ENTERPRISE` para compatibilidade com tiers `db-custom-*`.
- `artifact_registry_repository_id`: nome do repositório Docker no Artifact Registry.
- `artifact_registry_location`: região do repositório no Artifact Registry.

## Outputs úteis

- `artifact_registry_repository_url`
- `cloud_run_service_url`
- `cloud_sql_connection_name`
- `cloud_run_service_account_email`

## Observações

- O deploy configura o Django para conectar no Cloud SQL via socket Unix em `/cloudsql/<connection_name>`.
- `DJANGO_SECRET_KEY` e senha do banco são injetados como secrets no runtime.
- Para ambiente produtivo, revise `cloud_sql_tier`, escalonamento do Cloud Run e políticas de backup.
