# Platform requirements

## Personas

| Persona | Needs |
|---|---|
| **Developer** (me, future contributors) | push → live without touching servers; see logs and traces for my service |
| **Operator / on-call** | know something is broken before users do; runbooks; rollback |
| **Security / auditor** | evidence of change control, vulnerability management, access control |
| **Recruiter / hiring manager** | open live demos, a public dashboard and a readable architecture |

## Functional requirements (user stories)

| ID | Story | Acceptance criteria |
|---|---|---|
| PF-01 | As a developer, I want a merge to `main` to deploy my service automatically | CI builds multi-arch image → pushes to GHCR → updates the tag in this repo → ArgoCD syncs; visible in ArgoCD UI in < 10 min |
| PF-02 | As a developer, I want a reusable pipeline so every repo builds the same way | `.github/reusable/build-scan-sign.yml` called by each app repo with ≤ 10 lines |
| PF-03 | As an operator, I want to roll back by reverting a commit | `git revert` on the tag bump → previous version live < 5 min |
| PF-04 | As an operator, I want alerts when an SLO burns too fast | multi-window burn-rate alerts → email/Telegram; tested with a fault-injection drill |
| PF-05 | As a developer, I want one trace across services and the message bus | a payment trace spans InsureHub → Payments → RabbitMQ → Notifications in Tempo/Jaeger |
| PF-06 | As a security reviewer, I want every image scanned and signed | Trivy report + SBOM attached to each release; cosign signature verified by Kyverno at admission |
| PF-07 | As an operator, I want secrets encrypted in git | SOPS + age; no plaintext secret in history (gitleaks in CI) |
| PF-08 | As an operator, I want the whole environment rebuildable | `terraform apply` + bootstrap script → all apps healthy in < 1 h (drill recorded) |
| PF-09 | As an operator, I want nightly backups and a tested restore | `pg_dump` CronJob → object storage; monthly restore drill logged |
| PF-10 | As a recruiter, I want a public read-only view of health | Grafana public dashboard + UptimeRobot status page |
| PF-11 | As staff, I want one login for all back-office apps (phase 3) | Keycloak realm `insurehub-group`; InsureHub back office, LendHub, ClaimGuard and InsureAssist inbox use OIDC |
| PF-12 | As an operator, I want demo data reset nightly | CronJob per app reseeds demo DBs at 02:00 Africa/Harare |

## Non-functional requirements

| Category | Requirement |
|---|---|
| Cost | $0/month compute (domain optional) |
| Availability (demo) | 99% monthly per public endpoint (single node accepted) |
| Recovery | RPO 24 h (nightly backup), RTO 1 h (rebuild from code) |
| Security | TLS 1.2+ only, HSTS; SSH key-only from allowlisted IP; kube API not public; least-privilege service accounts |
| Observability | 100% of services emit traces, metrics, logs; retention 7 days |
| Portability | no provider-specific k8s resources outside `terraform/`; manifests work on AKS unchanged |
| Documentation | every component has a runbook entry; every significant decision has an ADR |
