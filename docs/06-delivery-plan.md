# Platform delivery plan

## Phase 1 — Live (Oct 1–7, 2026)
- [ ] Accounts, domain, Cloudflare DNS
- [ ] OCI A1 VM (click-ops on Day 1; Terraform import in Phase 2)
- [ ] Host hardening checklist
- [ ] k3s + cert-manager + ClusterIssuer
- [ ] Deploy Integrations (existing kustomize), InsureHub API, ClaimGuard (offline)
- [ ] InsureHub SPA on Cloudflare Pages
- [ ] Nightly demo reset + backup CronJobs
- [ ] UptimeRobot + status page
**Done when:** 3 apps reachable over HTTPS; READMEs show live links.

## Phase 2 — GitOps & observability (Oct 8 – Nov 4)
- [ ] Terraform for OCI + Cloudflare (import Day-1 resources), remote state in OCI Object Storage (S3-compatible backend)
- [ ] ArgoCD core install, app-of-apps, sync waves
- [ ] Move all app manifests under ArgoCD; image tag bump bot
- [ ] SOPS + age for secrets; ksops/helm-secrets plugin in ArgoCD
- [ ] OTel Collector in-cluster → Grafana Cloud free (Prometheus/Loki/Tempo-compatible backends); golden-signal dashboards; public dashboard. In-cluster Prometheus/Loki/Tempo only if the free VM allowance grows again.
- [ ] SLO recording rules + burn-rate alerts
- [ ] Rebuild drill: destroy and recreate in < 1 h (record video)
**Done when:** a merge in any app repo reaches production with no manual step; one trace across InsureHub → Payments → RabbitMQ → Notifications is visible.

## Phase 3 — Security & identity (Nov 26 – Dec 9)
- [ ] Reusable workflow: tests, CodeQL, gitleaks, buildx multi-arch, Trivy, Syft SBOM, cosign, provenance
- [ ] Kyverno policies (signed images, limits, non-root, no `:latest`)
- [ ] NetworkPolicies default-deny
- [ ] Keycloak realm, OIDC for staff UIs
- [ ] kube-bench report, ISO control evidence folder
**Done when:** an unsigned image is rejected at admission (demo clip); staff SSO works across two apps.

## Definition of done (platform)
Code in git · plan reviewed · applied via pipeline · runbook updated · ADR if a decision was made · evidence captured.

## Risks
See concept paper §7.
