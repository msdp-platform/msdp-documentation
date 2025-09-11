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

---
See `docs/diagrams/` for CI/CD and bootstrap flows.
