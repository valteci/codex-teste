# Projeto Django (local)

## Setup
- Use o venv `.venv`
- Instalar deps: `poetry install`
- Rodar migrations: `poetry run python manage.py migrate`
- Subir dev server: `poetry run python manage.py runserver`
- Rodar testes (quando existirem): `poetry run pytest`

## Regras de trabalho
- Faça mudanças pequenas e incrementais
- Sempre rode o comando mais relevante (migrate/test) antes de finalizar
- Não commite segredos; use `.env` e `.env.example`
- Prefira código simples e legível

