# MSDP Platform Overview — Canonical Reference

**Status:** ✅ Source of truth. This document supersedes the earlier aspirational overviews (see *Superseded documents* at the end).
**Last updated:** 2026-06-01
**Audience:** platform architects, contributors, and AI coding agents working in this workspace.

> Read this first. If another document in this repo contradicts this one, this one wins. Older docs are kept for history but are marked superseded.

**Related:** for the factory monorepo's technical architecture (components, data flow, deployment topology, built-vs-conceptual), see `msdp-platform/docs/ARCHITECTURE.md`.

---

## 1. What MSDP is

**MSDP (Multi-Service Delivery Platform) is an enterprise "business factory."** Its purpose is not to run one business — it is the machinery to **launch and operate many businesses**, ideally across most business domains and everyday human needs, worldwide. The platform itself is the product; the businesses it spins up are its output.

**VendaBuddy is one such output** — a single product/business that the factory produced. It is *not* the brand for everything the factory makes. Each launched business is its own product with its own identity.

### Core principle: every product operates independently

Each business the factory launches **runs independently with its own code repository, its own deployment, its own data, and its own lifecycle.** The `msdp-*` repos in this workspace are the **factory/platform**; the products it generates (VendaBuddy and future businesses) live in their **own separate repos**, spun out at the pilot stage. The factory provides shared building blocks, templates, governance, and deployment machinery — but it does not couple products together. A failure, release, or change in one product must not affect another.

The economic premise: when AI collapses the marginal cost of architecting, building, testing, and deploying a service toward zero, it becomes viable to launch a **tailored business per market — down to a single district or subdivision**. The only genuinely scarce inputs become a *researcher's idea* and a *board's approval*.

This premise is also the origin of the owner's PhD research (Management & Commerce) on how AI-driven service generation reshapes value creation and revenue models in platform commerce. MSDP is both a real platform ambition and the research demonstrator.

---

## 2. The operating model — researcher → board → pilot

The platform runs a repeatable pipeline:

1. **Idea origination.** A **Market Researcher** brings a business idea scoped to a specific market.
2. **Market scope.** "Market" is a **geographic hierarchy**: `country → region → state → district → subdivision`. The *same* idea can be researched and tuned independently at each level.
3. **Enhancement.** The researcher uses the **MSDP Business Center** to enrich and validate the idea against that market — AI-assisted, using Claude.
4. **Board approval.** The researcher submits the new (or enhanced) idea to **the Board** as a governance gate. Approval is deliberate, not automatic.
5. **Pilot → product.** On approval, the idea becomes a **pilot project** that runs the full product lifecycle — architecting → coding → testing → deployment — reusing proven service templates. The product is **scaffolded into its own independent repository** and registered in the platform catalog. From here it lives and ships on its own (VendaBuddy is the first example of such a product).

```
Researcher idea ──► Market-scoped enhancement (Business Center + Claude)
        ──► Board approval gate ──► Pilot project (architect→code→test→deploy)
        ──► Live business, registered in catalog (Backstage)
        └── repeatable across unlimited domains × geographic levels
```

---

## 3. Target architecture — self-owned, Claude + open source

**Design principle: own the agentic layer, avoid SaaS lock-in.** The previous design leaned on n8n (workflow SaaS) and Port.io (developer-portal SaaS). Both are **dropped**:

- **Port.io → replaced by Backstage**, which is already forked into this workspace (`MSDP-Backstage`). Backstage is the open-source catalog/governance/self-service layer; running Port.io duplicates it.
- **n8n → replaced by a self-owned Claude-based orchestrator.** The Business Center already ships an MCP server as the starting point.

The intended stack:

| Concern | Choice | Notes |
|---|---|---|
| Intelligence / agents | **Claude (Agent SDK or API) + MCP tools** | The part we own. Requirement analysis, enhancement, code generation. |
| Durable orchestration | **Temporal** (or **Windmill** for visual editing) | Long-running, restart-safe workflows: board-approval waits, multi-day pilots. Don't hand-roll retries/state. |
| Catalog & governance | **Backstage** | Service catalog, the approval gate, lifecycle tracking, software templates (scaffolding). |
| Deployment | **Terraform + ArgoCD on Azure AKS** (AWS for DNS/storage) | Already present in `msdp-devops-infrastructure`. |
| Data | **PostgreSQL + Redis** | Per service as needed. |

All open-source and self-hosted. Owning the agentic layer is itself evidence for the PhD thesis, not just plumbing.

How the stack maps to the pipeline: the **board-approval wait** is a durable workflow signal; the **pilot lifecycle** is a long-running workflow; each generated service **registers in Backstage** via a software template.

---

## 4. Honest status — built vs. conceptual

This section exists specifically so contributors and AI agents do **not** assume things exist that don't.

### Implemented today (real, working code)

- **Business Center** (`msdp-admin-frontends`): React/Vite + Node/Express + PostgreSQL. Real proposal lifecycle — create draft, `createAndSubmitProposal`, `submitForEnhancement` → AI enrichment job. Backend routes for `proposals`, `blueprints`, `businesses`, `enrichment`, `dashboard`, `config`, `auth`. Includes four business flows: *Commission New Business* (reusable `product_catalog` template), *New Business Idea* (country-specific launch from catalog into `businesses`), plus add-features / expand-location variants.
- **Claude integration** (`msdp-admin-frontends/mcp-server`): MCP server with `claude.ts` and blueprint tools — the seed of the self-owned agentic layer.
- **Location Service** (`msdp-location-service`): standalone Node service — geospatial search, real-time GPS tracking over WebSockets, Redis caching, country detection. The most complete microservice.
- **Shared libraries** (`msdp-shared-libs`): TS packages — `api-client`, `auth`, `types`, `ui-components`, `validation` — plus a service registry and contracts.
- **Infrastructure** (`msdp-devops-infrastructure`): Terraform (Azure AKS + AWS), YAML-driven config, GitHub Actions OIDC, ArgoCD/GitOps. Real IaC.
- **Developer portal** (`MSDP-Backstage`): Backstage fork with an MSDP catalog (`msdp-business`, `msdp-governance`, `msdp-domains`, `msdp-services`, `msdp-teams`) and software templates (`onboard-business`, `create-service`, `enable-location`, `platform-engineering-service`).
- **Reusable service templates** (`msdp-platform-core/archived/`): six reference microservices — `user`, `merchant`, `order`, `payment`, `api-gateway`, `admin` — plus databases/packages. Kept on purpose as pilot building blocks. *(This dir is gitignored; it lives on disk only.)*

### Conceptual / not yet built

- **The deep market hierarchy.** Today the data model effectively has *Business Unit + Country*. The `region → state → district → subdivision` levels — central to the vision — are **not modeled yet**.
- **The board-approval workflow.** Proposal → *submit for enhancement* exists; a **researcher → board → pilot** approval state machine does **not** yet exist as a durable workflow.
- **The self-owned orchestrator.** The MCP server is a starting point; the Claude + Temporal/Windmill orchestration layer described in §3 is **target, not current**.
- **Fully autonomous "idea → production in minutes."** Aspirational. Treat earlier docs claiming this as a vision statement, not a description of running software.

---

## 5. Repository → pipeline-stage map

The `~/github` workspace is **not** a single repo; it is a multi-repo workspace. **These are the factory/platform repos — not the products it launches.** Each launched product (e.g. VendaBuddy) lives in its own separate repo outside this set. Each platform repo serves a pipeline stage:

| Repo | Pipeline stage | Role |
|---|---|---|
| `msdp-admin-frontends` | **Enhancement** | The Business Center — idea capture, blueprints, Claude-assisted enrichment. The live front door. |
| `MSDP-Backstage` | **Approval + catalog** | Governance gate, service catalog, lifecycle tracking, scaffolding templates. (Replaces Port.io.) |
| `msdp-platform-core` | **Catalog assets + reuse** | Backstage catalog entities; `archived/` holds the six reusable microservice templates for pilots. |
| `msdp-devops-infrastructure` | **Deployment** | Terraform/ArgoCD/AKS — the engine that ships a pilot to production. |
| `msdp-location-service` | **Building block** | Proven standalone service; reference for geospatial/tracking needs. |
| `msdp-shared-libs` | **Building block** | Shared TS packages used across generated services. |
| `msdp-customer-frontends` | **Template surface** | Per-country customer app scaffolds — templates a launched product forks into its own repo. |
| `msdp-merchant-frontends` | **Template surface** | Merchant web app scaffold (the basis VendaBuddy was built from) — a template per-product, not a shared runtime. |
| `msdp-documentation` | **Reference** | This overview + design docs + PhD research materials. |

---

## 6. Near-term priorities (to close the vision→reality gap)

1. **Model the market hierarchy** (`country → region → state → district → subdivision`) as a first-class entity in the Business Center data model and in Backstage catalog domains.
2. **Implement the approval state machine** (researcher → board → pilot) as a durable workflow (Temporal/Windmill), with the board gate as a human-in-the-loop signal.
3. **Grow the MCP server into the orchestrator** — Claude agents for requirement analysis, enhancement, and code generation, calling reusable templates from `platform-core/archived/`.
4. **Wire pilot output into Backstage** via the `onboard-business` / `create-service` templates so every launched business is catalogued and governed.
5. **Scaffold each product into its own repository** at the pilot stage (repo-per-product), with independent CI/CD, data, and deployment — so products stay decoupled. Define the standard product-repo template and the spin-out automation.

---

## Superseded documents

The following are retained for history but **no longer authoritative**; where they conflict with this overview, this overview wins. They describe an earlier n8n/Port.io, "fully autonomous ∞ services" framing:

- `MSDP_MASTER_TECHNOLOGY_OVERVIEW.md`
- `MSDP_BACKSTAGE_ARCHITECTURE_VIEW.md`
- `MSDP_MASTER_DEPLOYMENT_GUIDE.md`
- `MSDP_LOW_LEVEL_DESIGN.md`
- `CURRENT_PROGRESS_ASSESSMENT.md`
- `MODULAR_DEPLOYMENT_TRACKER.md`
- `MSDP_FOUNDATION_COMPLETION_CHECKLIST.md`
