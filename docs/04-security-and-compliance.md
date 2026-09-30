# Platform security & compliance

## 1. Threat model (STRIDE, platform scope)

| Threat | Example | Control |
|---|---|---|
| **S**poofing | attacker calls a webhook pretending to be EcoCash | HMAC signatures + replay window (Integrations); mTLS/OIDC between services in phase 3 |
| **T**ampering | malicious image pushed to the registry | cosign keyless signing in CI; Kyverno verifies signatures at admission |
| **R**epudiation | "who deployed this?" | every change is a git commit/PR; ArgoCD sync history; audit logs to Loki |
| **I**nformation disclosure | secrets leaked in git; PII in logs | SOPS + gitleaks; Collector redaction processor; log review checklist |
| **D**enial of service | public demo flooded; LLM budget drained | Traefik rate limits; Cloudflare proxy; AI daily budget |
| **E**levation of privilege | container escape, over-privileged pod | non-root, read-only root FS, drop all capabilities, no privileged pods (Kyverno), least-privilege ServiceAccounts |

## 2. Supply-chain security (SLSA-inspired)

- Source: branch protection, required reviews (self-review with checklist for solo work), signed commits (optional).
- Build: ephemeral GitHub-hosted runners, pinned action SHAs, Dependabot for actions + packages.
- Artefacts: SBOM (Syft, SPDX JSON) attached to each release; provenance attestation (`actions/attest-build-provenance`).
- Deploy: only signed images from `ghcr.io/momosto/*` admitted.

## 3. Host hardening checklist (VM)

- [ ] SSH key-only, root login disabled, port 22 allowlisted to my IP
- [ ] `ufw` default deny, allow 80/443 (and OCI security list mirrored)
- [ ] unattended security upgrades
- [ ] fail2ban
- [ ] kube API (6443) not exposed; accessed via SSH tunnel
- [ ] CIS k3s benchmark reviewed with `kube-bench` (report in `docs/evidence/`)

## 4. Data protection (Zimbabwe)

The demo holds only fictional data, but the design follows the **Cyber and Data Protection Act [Chapter 12:07]** so it could be used for real:
- data minimisation in events (IDs, not profiles);
- PII redaction in telemetry;
- encryption in transit (TLS) and at rest (volume encryption; DB backups encrypted before upload);
- retention schedules per data class (ecosystem-architecture §7);
- a data breach response runbook (`runbooks/data-breach.md`).

## 5. ISO/IEC 27001:2022 Annex A — control mapping (selected)

| Control | How the platform meets it |
|---|---|
| 5.15 Access control | Keycloak roles (phase 3), k8s RBAC, least privilege |
| 5.23 Information security for use of cloud services | provider assessment in ADR-0001; exit plan (portable manifests) |
| 8.8 Management of technical vulnerabilities | Trivy + Dependabot + weekly report |
| 8.9 Configuration management | everything as code in git |
| 8.13 Information backup | nightly `pg_dump` off-box + monthly restore drill |
| 8.15 Logging / 8.16 Monitoring activities | Loki + Grafana alerting; audit trails in apps |
| 8.24 Use of cryptography | TLS, SOPS/age, HMAC webhooks |
| 8.25 Secure development life cycle | PR reviews, SAST, secret scanning, test gates |
| 8.28 Secure coding | coding standards, OWASP ASVS checklist per app |
| 8.32 Change management | PR = change record; change request template for infra changes |

Evidence (screenshots, reports) is collected in `docs/evidence/` as each phase completes.
