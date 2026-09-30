# ADR-0003: Keep secrets in git encrypted with SOPS + age

- **Status:** Accepted (Phase 2) · **Date:** 2026-09-30

## Context
GitOps needs every resource in git, including secrets (DB passwords, HMAC webhook secrets, Anthropic API key).

## Options
1. Manual `kubectl create secret` (Day 1 only) — not reproducible.
2. **SOPS + age**, decrypted by ArgoCD (ksops).
3. Sealed Secrets — cluster-bound key; re-seal on rebuild.
4. External Secrets + a cloud vault (OCI Vault / Azure Key Vault) — best for production.

## Decision
SOPS + age for the demo. The age private key is stored offline (password manager) and as one bootstrap secret in the cluster. Production design uses External Secrets + Key Vault (ADR-0005).

## Consequences
- ➕ Reproducible rebuilds; values diffable (keys visible, values encrypted).
- ➖ Losing the age key = re-issuing all secrets; mitigated by offline backup.
- gitleaks in CI blocks accidental plaintext commits.
