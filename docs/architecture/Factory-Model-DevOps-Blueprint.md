# Factory-Model DevOps Blueprint (MVP)

## Goals
- DRY, reusable infra modules; avoid over-engineering
- Start single-cloud-first; expand to multi-cloud when stable
- Factory packaging for services with minimal templates
- Integrated CI/CD across repos with GitOps for deployment

## Principles
- Simplicity first; add complexity only with clear value
- Immutable builds; declarative deployments; Git as the source of truth
- Security-by-default (OIDC auth, least privilege, signed images)
- Environments: dev → staging → prod; promotion via tags/PRs

## Phase 1 Scope (MVP)
- Cloud: Azure (AKS, ACR, VNet) as first target
- Identity: GitHub OIDC to Azure; no long‑lived keys
- Infra IaC: Terraform modules (foundation only)
- CD: ArgoCD for apps (app-of-apps), Helm for packaging
- CI: GitHub Actions minimal pipelines (lint, test, build, push)
- Observability: add in Phase 2 (Prometheus/Grafana)

## Minimal Architecture
- Repositories
  - `msdp-devops-infrastructure`: Terraform modules + ArgoCD bootstrap
  - Service repos (e.g., `msdp-food-delivery`): app code + Helm chart
  - `msdp-documentation`: architecture and runbooks
- Tooling
  - Infra: Terraform + AzureRM provider
  - CD: ArgoCD (ApplicationSet/app-of-apps)
  - Packaging: Docker (single-arch first), Helm
  - CI: GitHub Actions (reusable workflows later)

## Pipelines (Phase 1)
- Infra Bootstrap (manual/workflow_dispatch)
  1) Terraform init/plan/apply → AKS, ACR, VNet
  2) Export kubeconfig and install ArgoCD
  3) Point ArgoCD to GitOps app-of-apps path
- App Delivery (on push)
  1) Lint + unit tests
  2) Build image → push to ACR
  3) Bump Helm image tag in GitOps env path
  4) ArgoCD sync to AKS

## Environments
- Branches: dev, staging, prod drive overlay values
- Secrets: Azure Key Vault (or Kubernetes Secrets initially)
- Promotion: release tag/PR from dev → staging → prod

## Expansion (Phase 2+)
- Add AWS/GCP Terraform modules for multi-cloud
- Introduce Crossplane for app-layer infra if it reduces toil
- Add security scanning, SBOM, signing (Trivy/Cosign)
- Add Prometheus/Grafana, Alertmanager, Loki, Tempo

## Guardrails (Baseline)
- Required checks: build + unit tests must pass
- Protected branches for staging/prod
- CODEOWNERS for infra and GitOps paths

## Naming & Variables Dictionary

### Naming conventions
- Repository: `msdp-{domain}-{scope}` (e.g., `msdp-devops-infrastructure`, `msdp-food-delivery`)
- Kubernetes cluster: `{org}-{env}-{cloud}-{region}` (e.g., `msdp-dev-aws-use1`, `msdp-stg-azr-uks`)
- Kubernetes namespace: `{env}-{bu}-{app}` (e.g., `dev-food-order`)
- ArgoCD project: `{org}-{env}` (e.g., `msdp-dev`)
- ArgoCD application: `{env}-{bu}-{app}` (e.g., `dev-food-order`)
- Helm release: `{app}-{env}` (e.g., `order-dev`)
- Docker image: `{registry}/{org}/{app}:{semver|sha}` (e.g., `acme.azurecr.io/msdp/order:1.2.3`)
- Crossplane XRD kind: `X{Capability}` (e.g., `XDatabase`, `XCluster`)
- Crossplane Composition: `{capability}-{cloud}` (e.g., `database-aws`, `cluster-azure`)
- Backstage template id: `{bu}-{capability}-{env}-tmpl` (e.g., `food-api-dev-tmpl`)
- DNS records: `{app}.{env}.{base_domain}` (e.g., `api.dev.example.com`)
- Resource group (Azure): `{org}-{env}-{purpose}` (e.g., `msdp-dev-network`)
- Tag/label key prefix: `platform.msdp.io/` (e.g., `platform.msdp.io/owner=team-core`)

### Global variables (org-wide defaults)
- org: `msdp`
- base_domain: e.g., `example.com`
- git_org: e.g., `acme-inc`
- cloud_providers: `["aws","azure"]`
- default_regions:
  - aws: `us-east-1`
  - azure: `uksouth`
- accounts:
  - aws_account_id: `123456789012`
  - azure_subscription_id: `00000000-0000-0000-0000-000000000000`
- registries:
  - aws_ecr: `public.ecr.aws/acme`
  - azure_acr: `acme.azurecr.io`
- oidc:
  - github_org: `acme-inc`
  - audiences: `["sigstore","api://AzureADTokenExchange"]`
- k8s_defaults:
  - version: `1.29`
  - ingress_class: `nginx`
  - cert_issuer: `letsencrypt-prod`
- autoscaling:
  - nodes: `karpenter`
  - pods: `keda`
- dns:
  - provider: `route53`
  - zone_id: `Z123EXAMPLE`
- security_baseline:
  - sign_images: `false`
  - image_scan: `true`
  - branch_protection: `true`

### Local variables (per env / per app)
- env: `dev|stg|prod`
- cloud: `aws|azure`
- region: overrides default (e.g., `us-east-1`, `uksouth`)
- bu: `food|grocery|cleaning|repair` (etc.)
- app: service/app name (e.g., `order`, `gateway`)
- image:
  - repository: from registry map (e.g., `acme.azurecr.io/msdp/order`)
  - tag: `1.0.0` or git SHA
- runtime:
  - replicas: `2`
  - resources: `{ requests: {cpu,mem}, limits: {cpu,mem} }`
  - hpa: `{ min:1, max:5, cpuTarget:70 }`
  - keda: `{ trigger:type, params:{...} }`
- ingress:
  - host: `{app}.{env}.{base_domain}`
  - tls_secret: `{env}-{app}-tls`
- secrets:
  - source: `akv|kubernetes`
  - names: `{ db_conn, jwt_secret, api_keys[...] }`
- cost_and_ownership:
  - owner: team name (e.g., `team-core`)
  - cost_center: code (e.g., `CC1001`)
- karpenter:
  - provisioner_selector: labels for node classes (e.g., `workload=general`)
- labels (Kubernetes):
  - `app.kubernetes.io/name={app}`
  - `app.kubernetes.io/instance={app}-{env}`
  - `app.kubernetes.io/part-of={bu}`
  - `platform.msdp.io/env={env}`
  - `platform.msdp.io/owner={owner}`
  - `platform.msdp.io/cloud={cloud}`
- cloud tags (AWS/Azure):
  - `Environment={env}`
  - `BusinessUnit={bu}`
  - `Application={app}`
  - `Owner={owner}`
  - `CostCenter={cost_center}`
  - `ManagedBy=msdp`

## Platform Stack Alignment
- Crossplane: deploy infrastructure (XRDs + compositions) across AWS/Azure
- Backstage: developer templates and orchestration
- ArgoCD: application deployments (GitOps)
- GitHub Actions: pipelines (lint, test, build, push)
- Git: repositories as source of truth
- Kubernetes (EKS/AKS): shared platform for infra/app dev & test
  - Ingress: NGINX
  - Node autoscaling: Karpenter
  - Pod autoscaling: KEDA
  - DNS automation: external-dns (Route53 hosted zone)

---
See `docs/diagrams/` for CI/CD and bootstrap flows.
