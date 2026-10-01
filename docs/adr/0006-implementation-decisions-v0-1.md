# ADR-0006: Implementation decisions for v0.1

**Status:** Accepted · **Date:** 2026-10-01

## Context

Building the platform turned up places where the planning pack (docs/03, docs/06) was wrong about a tool's constraints or where a simpler choice fits the $0 budget better. They are recorded together here.

## Decisions

1. **Reusable workflow in `.github/workflows/`, not `.github/reusable/`.** GitHub only resolves `uses: owner/repo/.github/workflows/<file>@ref`, so the planned folder cannot work. A useful side effect: the Sigstore certificate of every signed image names `.github/workflows/build-scan-sign.yml`, and the Kyverno policy pins exactly that identity.
2. **ArgoCD "core" install.** No Dex, notifications or ApplicationSet controller UI components: saves about 400 MB on a 12 GB node. The UI is reached with `argocd admin dashboard` through the SSH tunnel; nothing ArgoCD-related is exposed publicly.
3. **cert-manager HTTP-01 through Traefik**, not DNS-01. No Cloudflare token has to live in the cluster. Cloudflare runs in Full (strict) mode in front.
4. **Grafana Cloud free tier** for metrics, logs and traces instead of in-cluster Prometheus/Loki/Tempo. The collector redacts PII and tail-samples before export. SLO rules are loaded into the hosted ruler with `mimirtool`, and checked with `promtool` in CI.
5. **Pod Security Admission (`restricted`) plus Kyverno.** PSA blocks the obvious things built in; Kyverno adds what PSA cannot (tags, signatures, resources). A namespace `LimitRange` supplies default resources, so the "require limits" rule mostly acts as a backstop.
6. **Quotas include rolling-update headroom.** Found on the local cluster: a quota sized for steady state blocks the surge pod. Each namespace quota now covers replicas + one surge per Deployment.
7. **Image tags live in this repo** (`clusters/demo/applications/apps.yaml`, kustomize `images`), changed only by `bump-image.yml`. Apps' own `deploy/` folders may keep `:latest` as a placeholder; the override always wins, and Kyverno would reject the placeholder anyway.
8. **Secrets folder builds empty until real secrets exist**, so the ArgoCD `secrets` Application is never stuck on a missing file during bootstrap.

## Consequences

The planning documents reference `.github/reusable/`; this ADR supersedes those mentions. Anyone reproducing the setup must create the `demo` GitHub environment with a required reviewer, otherwise `terraform apply` would run unattended.
