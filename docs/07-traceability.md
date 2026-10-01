# InsureHub Platform: requirements traceability & implementation report

**Version:** 0.1.0 · **Date:** 2026-10-01 · **Build:** `scripts/validate.sh` green; data layer, Kyverno and the USSD gateway deployed to a local k3s cluster ([evidence](evidence/2026-10-01-local-cluster.md))

This closes the loop from [02-requirements.md](02-requirements.md) to code and evidence. Status: ✅ built and verified · 🟡 built, verified offline only (needs the cloud account) · ⏳ not built yet (reason given).

## 1. Functional requirements

| ID | Requirement | Implementation | Verified by | Status |
|---|---|---|---|---|
| PF-01 | Merge to main deploys automatically | `build-scan-sign.yml` (bump job → `repository_dispatch`) → `bump-image.yml` edits one tag in `clusters/demo/applications/apps.yaml` → ArgoCD automated sync | TC-GO-01..03 (workflow lint by GitHub on push; bump script logic) | 🟡 needs the app repos to call the workflow and the cluster to exist |
| PF-02 | Reusable pipeline, ≤ 10 lines per repo | `.github/workflows/build-scan-sign.yml` (`workflow_call`), caller snippet in its header | TC-SC-01 | 🟡 (lives in `.github/workflows`, see ADR-0006) |
| PF-03 | Roll back by reverting a commit | image tags pinned in `apps.yaml` only; `bump-image.yml` makes one commit per deploy; Kyverno forbids `:latest` | TC-POL-03/04, TC-K8S-04 | ✅ design + policy; drill on the VM ⏳ |
| PF-04 | Alerts when an SLO burns too fast | `slo/rules.yaml` recording rules + multi-window burn-rate alerts; `slo/tests/alerts_test.yaml` | TC-SLO-01..06 (promtool) | ✅ rules tested; delivery to email/Telegram configured in Grafana Cloud ⏳ |
| PF-05 | One trace across services and the bus | OTel Collector (`clusters/demo/observability/otel-collector-values.yaml`); apps propagate `traceparent` (LendHub event envelope, Integrations) | – | ⏳ needs Grafana Cloud + all apps deployed |
| PF-06 | Every image scanned and signed | Trivy gate + SARIF, Syft SBOM, cosign keyless sign + SBOM attestation; Kyverno `verify-image-signatures` pins the signer to this workflow | TC-K8S-05 (unsigned image refused) | 🟡 signing path runs on the first app release |
| PF-07 | Secrets encrypted in git | SOPS + age (`secrets/.sops.yaml`), KSOPS in the ArgoCD repo server, examples only in git, gitleaks in CI and locally | TC-SEC-01..03 | ✅ |
| PF-08 | Environment rebuildable | `terraform/oci`, `terraform/cloudflare`, `bootstrap/cloud-init.yaml`, `scripts/bootstrap-cluster.sh`, `scripts/rebuild-drill.sh` | TC-TF-01/02, TC-K8S-01..03 | 🟡 timed drill needs the OCI account |
| PF-09 | Nightly backups and tested restore | `clusters/demo/infra/jobs.yaml` `postgres-backup` (pg_dump → OCI Object Storage, 30-day lifecycle in Terraform); `BackupMissing` alert; runbook | TC-K8S-02, TC-SLO-04 | 🟡 restore drill needs the bucket |
| PF-10 | Public read-only health view | `dashboards/golden-signals.json`, `dashboards/business-flows.json`; `status` DNS record | TC-DB-01 | ⏳ publish after Grafana Cloud is connected |
| PF-11 | One staff login (Keycloak, phase 3) | – | – | ⏳ phase 3 per the delivery plan |
| PF-12 | Demo data reset nightly | `demo-reset` CronJob 02:00 Africa/Harare with scoped RBAC | TC-K8S-02 | ✅ scheduled; reseed hooks per app ⏳ |

## 2. Non-functional requirements

| Category | Requirement | Evidence | Status |
|---|---|---|---|
| Cost | $0/month compute | single A1 VM (Always Free), Object Storage free tier, Grafana Cloud free, Cloudflare free | ✅ by design |
| Availability | 99% per endpoint | SLO rules + alerts; single node accepted | 🟡 measured once live |
| Recovery | RPO 24 h, RTO 1 h | nightly pg_dump + `BackupMissing` at 26 h; rebuild script | 🟡 drill pending |
| Security | TLS 1.2+, HSTS; SSH key-only from allowlist; kube API not public; least privilege | Cloudflare `min_tls_version`, Traefik `security-headers` middleware; security list (22 from `admin_cidr`, no 6443); cloud-init hardening; PSA `restricted` + Kyverno; default-deny NetworkPolicies; ArgoCD AppProject whitelist | ✅ |
| Observability | traces, metrics, logs from every service; 7 days | OTel Collector pipelines with PII redaction and tail sampling | 🟡 |
| Portability | no provider-specific k8s resources outside `terraform/` | manifests use only core APIs + cert-manager/Kyverno/ArgoCD CRDs; `local-path` storage is the k3s default class, not named | ✅ |
| Documentation | runbook per component, ADR per decision | `docs/runbooks/*`, ADR-0001..0006 | ✅ |

## 3. Deviations from the planning pack

See [ADR-0006](adr/0006-implementation-decisions-v0-1.md): the reusable workflow lives in `.github/workflows/`, ArgoCD "core" install instead of the full UI, cert-manager HTTP-01 instead of DNS-01, Grafana Cloud instead of in-cluster Prometheus/Loki/Tempo, Pod Security Admission alongside Kyverno.

## 4. Next

1. Create the OCI and Cloudflare accounts' API keys, the state bucket and the repo secrets listed in `.github/workflows/terraform.yml`; run `terraform apply` through the pipeline.
2. `scripts/bootstrap-cluster.sh`, encrypt the real secrets, watch ArgoCD converge; record the rebuild drill.
3. Add the 10-line release workflow to LendHub, InsureAssist and USSD; first signed release; enable `verify-image-signatures` in Enforce (it is from day one).
4. Connect Grafana Cloud, import the dashboards and rules (`mimirtool rules load slo/rules.yaml`), publish the status page.
