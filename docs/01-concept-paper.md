# Concept paper — a shared delivery platform for InsureHub Group

**Prepared for:** Head of IT / Programme Manager (fictional) · **Prepared by:** Simbarashe Nyamusa · **Date:** 2026-09-30 · **Status:** Draft for approval

## 1. Problem statement

InsureHub Group runs (or will run) seven systems in three languages. Today each is built, deployed and monitored by hand in its own way. That means:
- slow, risky releases (manual steps, no rollback path);
- no single view of health: failures are discovered by customers;
- inconsistent security: secrets in config files, unscanned images, no record of what is running;
- audit findings under ISO/IEC 27001 (change management, logging, vulnerability management).

## 2. Objectives

1. Every system deployable from git in under 10 minutes, with one-command rollback.
2. One observability stack: traces, metrics and logs for every service, with SLOs.
3. A secure software supply chain: every image scanned, signed and traceable to a commit.
4. Infrastructure reproducible from code in under 1 hour.
5. Run cost as close to zero as possible for the demo environment.

## 3. Options considered

| Option | Description | Cost (demo) | Pros | Cons |
|---|---|---|---|---|
| 1. Status quo | manual deploys per app | $0 | nothing to build | all problems remain |
| 2. PaaS per app | Render/Koyeb/Azure Container Apps per service | $0 on free tiers, rising fast on paid | least ops | services sleep, scattered config, no k8s skills shown, vendor limits |
| 3. **Self-managed k3s + GitOps on an always-free VM** | Oracle A1 VM, k3s, ArgoCD, OTel/Grafana | **$0** (+ optional domain ~US$10/yr) | one place, full control, matches the group's on-prem k3s practice, portable to AKS/EKS later | we operate it; single node = no HA |
| 4. Managed Kubernetes (AKS/EKS/GKE) | cloud-managed control plane | control plane may be free, nodes are not (≈US$30–70+/month) | production-grade HA | cost |

## 4. Recommendation

**Option 3** for the demo/non-production environment, designed so the same manifests move to **Option 4 (AKS)** for production with only the Terraform layer changing. This keeps cost at zero, demonstrates the target operating model, and avoids lock-in.

## 5. Benefits (targets)

| Measure | Before | Target |
|---|---|---|
| Lead time from merge to live | hours / manual | < 10 min |
| Change failure recovery | manual rebuild | `git revert` → auto-sync < 5 min |
| Mean time to detect an outage | customer complaint | < 5 min (alert) |
| Images with known critical CVEs in prod | unknown | 0 (with a fix available) |
| Environment rebuild | days | < 1 h from code |

## 6. Costs

| Item | Cost |
|---|---|
| Compute, storage, networking (Always Free) | $0 |
| DNS, CDN, Pages (Cloudflare free) | $0 |
| CI/CD, registry (GitHub public repos) | $0 |
| Domain name (optional) | ~US$10/year |
| Effort | ~3 weeks part-time across phases |

## 7. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Free tier withdrawn or instance reclaimed | medium | everything as code; rebuild in < 1 h; fallback to PaaS mix |
| Single node failure | medium | nightly backups off-box; documented restore runbook; accepted for demo |
| Operator time | medium | keep the stack small; use k3s defaults (Traefik, local-path) |

## 8. Decision requested

Approve Option 3 for the demo environment and the three-phase plan in `06-delivery-plan.md`.
