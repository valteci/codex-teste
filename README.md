# Django Project (Docker-Ready)

## Resumo de arquitetura

- App: Django 6 servido por Gunicorn.
- Banco PostgreSQL configurado por `DATABASE_URL` ou por variáveis `DB_*` (útil no Cloud Run + Cloud SQL).
- Configuração 12-factor por variáveis de ambiente.
- Container com usuário não-root.

## Objetivo 6: segurança mínima aplicada

- Flags de segurança parametrizadas no `config/settings.py`.
- Suporte a headers/SSL proxy por `DJANGO_SECURE_PROXY_SSL_HEADER`.
- Cookies, HSTS, frame/referrer policy e hardening por env.
- `RUN_DEPLOY_CHECK` opcional no entrypoint para `manage.py check --deploy`.

## Objetivo 7: observabilidade e health checks

- Logs do Django em stdout com formato consistente.
- Gunicorn com access/error logs em stdout.
- Coletor de logs `Grafana Alloy` em container para exportar logs Docker ao Google Cloud Logging.
- Endpoints:
  - `GET /health/live/`
  - `GET /health/ready/` (valida conexão com banco)
- `docker-compose.yml` usa readiness no healthcheck do `web`.

## Objetivo 8: pipeline de validação

Workflow em `.github/workflows/ci.yml` com 3 jobs:

1. `tests`: `check`, `migrate`, `pytest`
2. `docker-build`: build da imagem Docker
3. `security-scan`: `bandit` + `pip-audit`

## Objetivo 9: operação e onboarding

### Variáveis obrigatórias

- `DJANGO_SECRET_KEY`
- `DATABASE_URL` **ou** `DB_NAME` + `DB_USER` + `DB_PASSWORD` (+ `DB_HOST`/`DB_PORT` quando necessário)
- `DJANGO_ALLOWED_HOSTS`

### Variáveis de inicialização do container

- `WAIT_FOR_DB` (default: `1`)
- `DB_WAIT_TIMEOUT` (default: `60`)
- `RUN_MIGRATIONS` (default: `0`)
- `RUN_COLLECTSTATIC` (default: `0`)
- `RUN_DEPLOY_CHECK` (default: `0`)

Modelos de ambiente: `.env.example` e `.env.sample`.

## Comandos principais

### Subir stack local

```bash
docker compose up --build
```

### Subir em background

```bash
docker compose up --build -d
```

### Derrubar stack

```bash
docker compose down
```

### Rodar migrations no serviço web

```bash
docker compose exec web python manage.py migrate
```

### Rodar testes

```bash
poetry run pytest
```

### Abrir shell Django

```bash
docker compose exec web python manage.py shell
```

### Build da imagem manualmente

```bash
docker build -t django-project:local .
```

### Subir coletor de logs (Alloy -> Google Cloud Logging)

1. Defina `GCP_PROJECT_ID` em `.env.sample`.
2. Coloque a chave de service account em `secrets/service-account.json`.
3. Garanta que a service account tenha o papel `roles/logging.logWriter`.

```bash
docker compose up -d alloy
docker compose logs -f alloy
```

4. Para ver os logs no gcloud:
```bash
gcloud logging read \
  'log_id("alloy-docker-logs")' \
  --project=GCP_PROJECT_ID \
  --limit=20
```

## Notas de produção

- Em produção, configure:
  - `DJANGO_DEBUG=False`
  - `DJANGO_SECURE_SSL_REDIRECT=True`
  - `DJANGO_SESSION_COOKIE_SECURE=True`
  - `DJANGO_CSRF_COOKIE_SECURE=True`
  - HSTS (`DJANGO_SECURE_HSTS_SECONDS > 0`)
- Ajuste `DJANGO_SECURE_PROXY_SSL_HEADER` quando estiver atrás de reverse proxy.
