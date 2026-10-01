# InsureHub Platform — GitOps, observability & DevSecOps for the InsureHub Group ecosystem

**Status:** 🟡 v0.1.0 built and validated: every check in `scripts/validate.sh` passes, and the data layer, Kyverno policies and the USSD gateway were deployed to a local k3s cluster ([evidence](docs/evidence/2026-10-01-local-cluster.md)). The OCI VM is not provisioned yet (needs the cloud account).
**Stack:** Terraform (OCI provider) · cloud-init · k3s · Traefik · cert-manager · ArgoCD (app-of-apps) · Helm/Kustomize · SOPS + age · OpenTelemetry Collector · Grafana Cloud (Prometheus/Loki/Tempo) · Trivy · gitleaks · CodeQL · Syft (SBOM) · cosign · Kyverno · Keycloak (phase 3) · GitHub Actions

**Author:** Simbarashe Nyamusa, Senior Software Engineer

One infrastructure repo that provisions, deploys, secures and observes every system in the portfolio. It is also the home of the **ecosystem-level architecture paperwork**.

## Why this repo exists

It proves the DevOps and governance lines on my CV with something a reviewer can open:
- "Established CI/CD pipelines … reducing deployment time by 60%" → GitOps pipeline with a measured lead time.
- "Stood up a k3s Kubernetes cluster" → the actual cluster, as code.
- "Reduced downtime by 40% through proactive monitoring" → SLOs, alerts, public dashboards.
- "Remediated vulnerabilities (SSL/TLS, XSS …)", "ISO/IEC 27001, DevSecOps" → supply-chain security pipeline and a control mapping.

## Documents

| Document | What |
|---|---|
| [docs/ecosystem-architecture.md](docs/ecosystem-architecture.md) | architecture vision, C4 L1/L2, integration & event catalogues, data ownership, port map |
| [docs/free-hosting-plan.md](docs/free-hosting-plan.md) | $0 hosting options, resource budget, Day 1 checklist |
| [docs/01-concept-paper.md](docs/01-concept-paper.md) | business case for the platform |
| [docs/02-requirements.md](docs/02-requirements.md) | platform requirements and NFRs |
| [docs/03-architecture.md](docs/03-architecture.md) | cluster, GitOps flow, pipelines, observability design |
| [docs/04-security-and-compliance.md](docs/04-security-and-compliance.md) | threat model, supply chain, ISO 27001 control mapping |
| [docs/05-slos-and-alerting.md](docs/05-slos-and-alerting.md) | SLOs and alert rules per service |
| [docs/06-delivery-plan.md](docs/06-delivery-plan.md) | phases, backlog, definition of done |
| [docs/runbooks/](docs/runbooks/) | operational runbooks |
| [docs/templates/](docs/templates/) | ADR, concept paper, change request, runbook, postmortem templates |
| [docs/adr/](docs/adr/) | platform decisions (ADR-0006: what changed while building) |
| [docs/07-traceability.md](docs/07-traceability.md) | every requirement → implementation → evidence, and what is left |
| [docs/09-test-cases.md](docs/09-test-cases.md) | every test case (offline, local cluster, cloud drills) with its last result |
| [docs/evidence/](docs/evidence/) | validation runs and drills |

## Repo layout

```
insurehub-platform/
├── terraform/
│   ├── oci/                  VCN, subnet, security list (SSH from admin CIDR only), A1 VM, backup bucket + lifecycle
│   └── cloudflare/           proxied DNS per app, Pages projects for the SPAs, TLS settings
├── bootstrap/
│   ├── cloud-init.yaml       OS hardening, k3s with secrets encryption + audit log
│   └── argocd/               ArgoCD core install + KSOPS, root app-of-apps
├── clusters/demo/
│   ├── platform/             namespaces (PSA levels), default-deny NetworkPolicies, quotas + LimitRanges
│   ├── ingress/ certs/       Traefik middlewares (headers, rate limit), Let's Encrypt issuers
│   ├── infra/                Postgres (DB per system), RabbitMQ, Redis, nightly backup, demo reset
│   ├── applications/         AppProject + Applications in sync waves; app image tags pinned here
│   └── observability/        OTel Collector values (PII redaction, tail sampling → Grafana Cloud)
├── policies/kyverno/         limits, no :latest, non-root, keyless signature verification + CLI tests
├── slo/                      recording rules, burn-rate alerts, promtool unit tests
├── dashboards/               golden signals, business flows (Grafana JSON)
├── secrets/                  SOPS rules, examples (no real values), KSOPS generator
├── scripts/                  validate, bootstrap-cluster, local-cluster (k3d), rebuild-drill
└── .github/workflows/        validate, terraform plan/apply, build-scan-sign (reusable), bump-image
```

## Try it

```bash
scripts/validate.sh              # all offline checks (needs terraform, kustomize, kubeconform, kyverno, promtool, jq)
scripts/local-cluster.sh up      # k3s in Docker with the platform baseline and data services
scripts/local-cluster.sh down
```

Going live: [docs/07-traceability.md §4](docs/07-traceability.md#4-next).

## Phases

| Phase | When | Outcome |
|---|---|---|
| 1 — Live | Oct 1–7 | VM + k3s + TLS + first three apps live (manual secrets) |
| 2 — GitOps & observability | Oct 8–Nov 4 | Terraform, ArgoCD app-of-apps, SOPS, OTel → Grafana, SLO dashboards public |
| 3 — Security & identity | Nov 26–Dec 9 | reusable secure pipeline (Trivy, gitleaks, CodeQL, SBOM, cosign), Kyverno, Keycloak SSO for staff apps |
