  1. Definir arquitetura-alvo e estratégia por ambiente V

  2. Adotar Cloud Run para a app Django e Cloud SQL (PostgreSQL) para banco.
    2.1 Usar Cloud Run para fazer deploy
    2.2 Usar BATABASES no settings.py em vez de usar DATABSE_URL (evitar dor de cabeça com URLs)
    2.3 Cria cloud run, cloud sql e service accounts no terraform e conectar o cloud run ao sql cloud.

  3. Mapear branches para ambientes: develop -> dev, homolog -> staging, main -> prod.
    3.1 Fazer cd iniciar apenas nas branches homolog ou main
    3.2 Proteger branches homolog e prod para aceitarem push apenas via PR e rejeitar force
    

  4. Definir política de promoção: deploy automático em dev/staging e aprovação manual em prod.
  5. Preparar infraestrutura GCP (preferencialmente via Terraform)
  6. Criar/ajustar recursos: Artifact Registry, Cloud Run, Cloud SQL, Secret Manager, contas de serviço e IAM.
  7. Habilitar APIs necessárias (run, artifactregistry, sqladmin, secretmanager, iamcredentials, etc.).
  8. Configurar backend remoto do Terraform em bucket GCS para estado.
  9. Criar identidade de deploy via OIDC (Workload Identity Federation) para GitHub Actions, evitando chave JSON estática.
  10. Configurar segurança e segredos
  11. Manter segredos fora do repo (.env/Secret Manager), como já indicado em AGENTS.md.
  12. Definir segredos/variáveis por ambiente no GitHub (Settings > Environments), por exemplo:
     GCP_PROJECT_ID, GCP_REGION, GAR_REPOSITORY, CLOUD_RUN_SERVICE, WORKLOAD_IDENTITY_PROVIDER, DEPLOY_SERVICE_ACCOUNT, DJANGO_SECRET_KEY, DATABASE_URL (ou
     componentes via Secret Manager).
  13. Aplicar proteções de ambiente no GitHub (review obrigatório para prod).
  14. Ajustes de aplicação para produção (pré-requisito do deploy)
  15. Definir estratégia de estáticos com DEBUG=False (ex.: WhiteNoise ou bucket/CDN), porque Django puro não serve estático em produção.
  16. Configurar DJANGO_ALLOWED_HOSTS e DJANGO_CSRF_TRUSTED_ORIGINS para URL do Cloud Run/domínio.
  17. Ativar hardening por env (DJANGO_SECURE_SSL_REDIRECT, cookies secure, HSTS, proxy SSL header).
  18. Separar migração de startup contínuo: serviço roda com RUN_MIGRATIONS=0 e migração vira etapa/job de deploy.
  19. Criar pipeline CD no GitHub Actions
  20. Novo workflow de CD (ex.: .github/workflows/cd.yml) acionado após CI verde.
  21. Etapas do CD:
     autenticar via OIDC no GCP;
     build/push da imagem no Artifact Registry com tags (sha, branch, opcional latest-env);
     executar migração (Cloud Run Job ou execução única controlada);
     deploy no Cloud Run com imagem imutável;
     smoke test em /health/live/ e /health/ready/.
  22. Configurar concurrency por ambiente para evitar deploy concorrente.
  23. Estratégia de rollout e rollback
  24. Em prod, usar revisão do Cloud Run para rollback rápido (voltar tráfego para revisão anterior).
  25. Opcional: deploy sem tráfego + teste + promoção de tráfego.
  26. Definir runbook simples de incidente (rollback, reexecução de migração, validação de saúde).
  27. Observabilidade e operação
  28. Usar logs nativos do Cloud Run no Cloud Logging (Alloy tende a não ser necessário nesse cenário).
  29. Criar alertas básicos (erro 5xx, latência, instância indisponível, falha de migração).
  30. Definir check operacional pós-deploy (endpoint, admin/login, conexão DB).