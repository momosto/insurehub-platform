# ADR-0001: Host the demo environment on an Oracle Always Free VM running k3s

- **Status:** Accepted · **Date:** 2026-09-30

## Context
Seven systems (C#, Java, Python) plus PostgreSQL, RabbitMQ, Redis and an observability stack must be public at $0/month. The hosting itself should demonstrate Kubernetes and GitOps skills from the CV.

## Options
1. PaaS free tiers per service (Render, Koyeb, Azure Container Apps grant) — simple, but services sleep, config is scattered and no Kubernetes is shown.
2. **Oracle Cloud Always Free Ampere A1 VM + k3s** — 2 OCPU / 12 GB RAM (halved from 4/24 in June 2026), enough for all apps on one node if observability goes to Grafana Cloud free; full control.
3. Home server behind Cloudflare Tunnel — free, but load-shedding and home internet make it unreliable.
4. Managed Kubernetes (AKS/EKS/GKE) — production-grade, but worker nodes cost money.

## Decision
Option 2 for the demo environment; Option 1 as fallback per component; SPAs on Cloudflare Pages.

## Consequences
- ➕ $0, always on, shows k3s/ArgoCD/Traefik/cert-manager end to end.
- ➕ Manifests stay portable to AKS (ADR-0005).
- ➖ Arm64: all images must be multi-arch.
- ➖ Single node: no HA; accepted for a demo, mitigated by backups and a < 1 h rebuild.
- ➖ Dependence on a free programme that can change — it already did (June 2026 halving): exit plan = fallback mapping in `free-hosting-plan.md`.
- ➖ CPU (2 OCPU) is the binding constraint: one replica per service, batch jobs at night.

## Sources
- [Oracle — Always Free resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Linuxiac — Oracle quietly cuts free tier Ampere A1 resources in half](https://linuxiac.com/oracle-quietly-cuts-free-tier-ampere-a1-resources-in-half/)
- [Grafana Cloud pricing (free tier)](https://grafana.com/pricing/)
- [Render — free tier article](https://render.com/articles/platforms-with-a-real-free-tier-for-developers-in-2026)
