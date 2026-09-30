# ADR-0002: Deploy with GitOps (ArgoCD app-of-apps) instead of push-based CI deploys

- **Status:** Accepted · **Date:** 2026-09-30

## Context
Each app repo has CI. Deploying from CI with `kubectl apply` needs cluster credentials in GitHub and gives no drift detection or easy rollback.

## Options
1. CI pushes to the cluster (`kubectl`/`helm upgrade` from Actions).
2. **ArgoCD pulls desired state from git** (app-of-apps).
3. Flux CD.

## Decision
ArgoCD with an app-of-apps root, sync waves (infra → observability → apps), and image tags bumped by a bot PR to this repo.

## Consequences
- ➕ No cluster credentials in CI; the cluster pulls.
- ➕ Rollback = `git revert`; drift is visible and self-healed.
- ➕ ArgoCD UI is a strong visual for demos (read-only account).
- ➖ ~0.8 GB RAM; one more component to operate.
- Flux would work equally well; ArgoCD chosen for its UI and wider use in job adverts.
