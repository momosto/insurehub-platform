# InsureHub Platform — GitOps, observability & DevSecOps for the InsureHub Group ecosystem

**Status:** 📝 Planned — Phase 1 starts 2026-10-01
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
| [docs/adr/](docs/adr/) | platform decisions |

## Planned repo layout

```
insurehub-platform/
├── terraform/
│   ├── oci/                 VCN, subnet, security list, A1 instance, block volume, object storage bucket
│   └── cloudflare/          DNS records, Pages projects
├── bootstrap/
│   ├── cloud-init.yaml      OS hardening, k3s install
│   └── argocd/              ArgoCD install + root "app-of-apps"
├── clusters/demo/
│   ├── apps/                one ArgoCD Application per system (points at each repo's chart/kustomize)
│   ├── infra/               cert-manager, postgres, rabbitmq, redis, keycloak
│   └── observability/       otel-collector, prometheus, loki, tempo, grafana (+ dashboards as JSON)
├── policies/kyverno/        require limits, disallow :latest, require signed images
├── secrets/                 SOPS-encrypted secrets (age)
├── .github/
│   ├── workflows/           terraform plan/apply, policy checks
│   └── reusable/            shared build-scan-sign-push workflow used by every app repo
└── docs/
```

## Phases

| Phase | When | Outcome |
|---|---|---|
| 1 — Live | Oct 1–7 | VM + k3s + TLS + first three apps live (manual secrets) |
| 2 — GitOps & observability | Oct 8–Nov 4 | Terraform, ArgoCD app-of-apps, SOPS, OTel → Grafana, SLO dashboards public |
| 3 — Security & identity | Nov 26–Dec 9 | reusable secure pipeline (Trivy, gitleaks, CodeQL, SBOM, cosign), Kyverno, Keycloak SSO for staff apps |
