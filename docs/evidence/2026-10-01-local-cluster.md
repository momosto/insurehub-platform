# Evidence: local k3s deploy, 2026-10-01

**Where:** k3d (k3s v1.31.4) in Docker Desktop on the author's laptop, created with `scripts/local-cluster.sh up`
**Why:** prove the manifests are admitted by a real API server, the policies behave as designed and an app runs under them, before any cloud spend. ArgoCD and the cloud VM are not part of this run.

## 1. Offline validation (`scripts/validate.sh`)

| Check | Result |
|---|---|
| `terraform fmt -check` + `validate` (oci, cloudflare) | ✅ both valid |
| `kustomize build` + `kubeconform -strict` (K8s 1.31 + CRD catalog) | ✅ platform 34, ingress 3, certs 2, infra 13, applications 15, kyverno 4, bootstrap/argocd 31 (+3 upstream CRDs skipped) |
| `kyverno test policies/kyverno/tests` | ✅ 10/10 |
| `promtool check rules` / `promtool test rules` | ✅ 14 rules; fast burn, slow burn (no page), DLQ, backup missing, USSD fallbacks |
| dashboards JSON, cloud-init YAML | ✅ |
| gitleaks | ✅ no leaks |

## 2. Data services

`kubectl apply -k clusters/demo/platform` then `clusters/demo/infra` with local-only credentials:

- `postgres-0`, `rabbitmq-0`, `redis-0` Running; PVCs bound (local-path); CronJobs `postgres-backup` 01:15 and `demo-reset` 02:00 Africa/Harare.
- Init script created one database per system: `claimguard, insureassist, insurehub, lendhub, notifications, payments`.
- RabbitMQ has the `insurehub.events` topic exchange; Redis answers `PONG`.

## 3. Admission controls

| Attempt | Blocked by | Message |
|---|---|---|
| `kubectl run` with `:latest` and no securityContext in `lendhub` | Pod Security Admission (`restricted`) | `allowPrivilegeEscalation != false … runAsNonRoot != true …` |
| PSA-compliant pod with `lendhub-api:latest` | Kyverno `disallow-latest-tag` | `The ':latest' tag is not allowed; pin a version.` |
| Pod without requests/limits | not blocked: the namespace `LimitRange` fills in defaults before validation, which is the intended layering | – |
| Restart of `insurehub-ussd` after enforcing `verify-image-signatures` (image built locally, not signed by CI) | Kyverno `verify-image-signatures` (autogen rule on the Deployment) | `missing digest for ghcr.io/momosto/insurehub-ussd:0.1.0`. The running pods kept serving. |

## 4. An application under the guardrails

`insurehub-ussd/deploy/base` with image `ghcr.io/momosto/insurehub-ussd:0.1.0` (imported into k3d), sessions in the shared Redis:

- 2/2 replicas Ready after two fixes (below).
- `POST /ussd` without `X-Ussd-Secret` → **401**.
- Dial → `CON Welcome to InsureHub` menu; option 3 → OTP prompt; session key `ussd:s:k1` written to Redis DB 3.

## 5. Defects found and fixed

| # | Defect | Fix |
|---|---|---|
| 1 | USSD image ran as the named user `app`; with `runAsNonRoot: true` the kubelet cannot verify it and refuses to start (`CreateContainerConfigError`) | insurehub-ussd: `USER 1654` in the Dockerfile, `runAsUser/runAsGroup: 1654` in the Deployment |
| 2 | USSD namespace quota `limits.memory: 512Mi` could not fit a rolling update (2 × 192Mi + 1 surge pod) | quota 640Mi / 320Mi requests; insureassist raised to 1400Mi / 700Mi for the same reason (agent + MCP surging together) |
| 3 | kustomize could not match the ArgoCD patches (patch metadata carried `namespace: argocd`, the upstream manifest has none until the namespace transformer runs) | namespace removed from the patch targets |
| 4 | Kyverno regex in a double-quoted YAML string (`\.`) was an invalid escape | single-quoted |
| 5 | k3d kubeconfig pointed at `host.docker.internal`, unreachable from Windows | `--api-port 127.0.0.1:6550` in `scripts/local-cluster.sh` |

Cluster deleted afterwards (`k3d cluster delete insurehub-local`).
