# InsureHub Platform: test cases

**Version:** 0.1.0 · **Date:** 2026-10-01 · **Run:** `scripts/validate.sh` all checks passed; local k3s run recorded in [evidence/2026-10-01-local-cluster.md](evidence/2026-10-01-local-cluster.md)

Infrastructure is tested at three levels: **O** = offline checks in CI (`scripts/validate.sh`, `.github/workflows/validate.yml`) · **K** = against a real Kubernetes API (k3d, `scripts/local-cluster.sh`) · **C** = in the cloud environment (drills, needs the OCI account).
**Result:** ✅ passed 2026-10-01 · ⏳ not run yet (reason given).

## 1. Terraform

| ID | Req | Scenario | Expected | Level | How | Result |
|---|---|---|---|---|---|---|
| TC-TF-01 | PF-08 | Format and validate `terraform/oci` and `terraform/cloudflare` | `fmt -check` clean; both configurations valid | O | `validate.sh` | ✅ |
| TC-TF-02 | NFR security | Read the OCI security list | Ingress 80/443 from anywhere, 22 only from `admin_cidr`, no 6443 | O | review of `terraform/oci/main.tf` | ✅ |
| TC-TF-03 | PF-08 | `terraform plan` on a PR | Plan posted as a PR comment; apply only after the `demo` environment reviewer approves | C | `terraform.yml` | ⏳ needs OCI/Cloudflare secrets |

## 2. Kubernetes manifests

| ID | Req | Scenario | Expected | Level | How | Result |
|---|---|---|---|---|---|---|
| TC-K8S-01 | PF-08 | Build every kustomization and validate against K8s 1.31 schemas and the CRD catalog, strict mode | 0 invalid, 0 errors (platform 34, ingress 3, certs 2, infra 13, applications 15, kyverno 4, bootstrap 31 + 3 upstream CRDs skipped) | O | `validate.sh` | ✅ |
| TC-K8S-02 | PF-09, PF-12 | Apply platform baseline and data services to k3s | Postgres, RabbitMQ, Redis Running with bound PVCs; backup and reset CronJobs scheduled in Africa/Harare | K | `local-cluster.sh up` | ✅ |
| TC-K8S-03 | ADR-0004 | Postgres init on an empty volume | One database and owner role per system (6) | K | `psql -c "select datname …"` | ✅ |
| TC-K8S-04 | NFR security | Pod with `:latest`, no securityContext, in an app namespace | Refused by Pod Security Admission `restricted` | K | `kubectl run` | ✅ |
| TC-K8S-05 | PF-06 | Restart a Deployment whose image was not signed by `build-scan-sign.yml` | Refused by Kyverno `verify-image-signatures`; running pods keep serving | K | `kubectl rollout restart` | ✅ |
| TC-K8S-06 | NFR capacity | Rolling update of a 2-replica app within its namespace quota | Surge pod fits; rollout completes | K | USSD rollout | ✅ after quota fix (defect 2 in the evidence) |
| TC-K8S-07 | US/NFR | Deploy `insurehub-ussd` from its repo under all guardrails | 2/2 Ready; 401 without secret; menu served; session stored in shared Redis | K | port-forward + curl | ✅ after UID fix (defect 1) |
| TC-K8S-08 | NFR security | Traffic from another namespace to `data` services | Denied by default-deny NetworkPolicy except from app namespaces | K | – | ⏳ not probed yet; scripted probe planned |
| TC-K8S-09 | PF-01 | ArgoCD app-of-apps sync from git | All Applications Synced/Healthy | C | `bootstrap-cluster.sh` | ⏳ needs the VM |

## 3. Policies (Kyverno CLI)

`kyverno test policies/kyverno/tests` against `tests/resources/*.yaml`:

| ID | Policy / rule | Resource | Expected | Result |
|---|---|---|---|---|
| TC-POL-01 | require-requests-limits / containers-have-resources | good-pod | pass | ✅ |
| TC-POL-02 | require-requests-limits / containers-have-resources | no-limits | fail | ✅ |
| TC-POL-03 | disallow-latest-tag / require-image-tag | untagged | fail (and good-pod passes) | ✅ |
| TC-POL-04 | disallow-latest-tag / no-latest | latest-tag | fail (and good-pod passes) | ✅ |
| TC-POL-05 | require-non-root / run-as-non-root | root-pod | fail (and good-pod passes) | ✅ |
| TC-POL-06 | require-non-root / no-privilege-escalation | privileged | fail (and good-pod passes) | ✅ |
| TC-POL-07 | verify-image-signatures | an image signed by `build-scan-sign.yml@refs/heads/main` | admitted, digest pinned | ⏳ first signed release |

## 4. SLO rules (promtool)

`promtool test rules slo/tests/alerts_test.yaml`:

| ID | Req | Scenario | Expected | Result |
|---|---|---|---|---|
| TC-SLO-01 | PF-04 | lendhub-api 20% errors for 90 min; insureassist healthy | `SLOErrorBudgetFastBurn` (page) for lendhub-api only | ✅ |
| TC-SLO-02 | PF-04 | Recording rule | `slo:http_errors:ratio_rate5m` = 0.2 | ✅ |
| TC-SLO-03 | PF-04 | USSD 7% errors for 7 h | `SLOErrorBudgetSlowBurn` (ticket), no fast-burn page | ✅ |
| TC-SLO-04 | PF-09 | Last successful backup 30 h ago | `BackupMissing` | ✅ |
| TC-SLO-05 | ops | 1 message in `lendhub.dlq` for > 10 min | `DeadLetterQueueNotEmpty` with the runbook link | ✅ |
| TC-SLO-06 | US NFR | USSD fallbacks 0.2/s for 25 min | `UssdBackendFallbacks` | ✅ |
| TC-SLO-07 | PF-04 | Fault-injection drill on the live cluster | alert reaches email/Telegram | ⏳ needs Grafana Cloud |

## 5. Secrets and supply chain

| ID | Req | Scenario | Expected | Level | Result |
|---|---|---|---|---|---|
| TC-SEC-01 | PF-07 | gitleaks over the whole history | no leaks | O | ✅ |
| TC-SEC-02 | PF-07 | Secret keys in `secrets/examples` match what each consumer reads (Postgres init loop, RabbitMQ, OTel, app `envFrom`) | every key used exists, no stale keys | O (review) | ✅ (fixed during review: Postgres `<APP>_PASSWORD` names, `IA_WHATSAPP_ACCESS_TOKEN`, unused Cloudflare token removed) |
| TC-SEC-03 | PF-07 | `secrets/` kustomization with no encrypted files yet | builds empty (app syncs, nothing applied) | O | ✅ |
| TC-SC-01 | PF-02/06 | App repo release calls `build-scan-sign.yml` | multi-arch image, Trivy gate, SBOM artefact + attestation, keyless signature, dispatch to `bump-image` | C | ⏳ first release |
| TC-GO-01 | PF-01 | `bump-image` with app `lendhub`, image `ghcr.io/momosto/lendhub-api`, tag `0.1.1` | only that line changes; one commit "Deploy lendhub: lendhub-api:0.1.1" | C | ⏳ |
| TC-GO-02 | PF-01 | `bump-image` with an image from another owner or a `latest` tag | rejected by input validation | C | ⏳ |
| TC-GO-03 | PF-03 | `git revert` of a bump commit | previous tag live after ArgoCD sync (< 5 min) | C | ⏳ |

## 6. Dashboards and host

| ID | Scenario | Expected | Level | Result |
|---|---|---|---|---|
| TC-DB-01 | Dashboards parse and panel ids are unique | valid JSON | O | ✅ |
| TC-HOST-01 | `bootstrap/cloud-init.yaml` parses | valid YAML | O | ✅ |
| TC-HOST-02 | kube-bench on the VM | no FAIL in the k3s profile except documented exceptions | C | ⏳ |
| TC-DRILL-01 | Rebuild drill (`rebuild-drill.sh`) | all apps healthy and data restored in < 60 min | C | ⏳ |
