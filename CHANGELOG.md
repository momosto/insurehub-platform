# Changelog

## 0.1.0 (2026-10-01)

First implementation of the planning pack.

### Added
- Terraform for OCI (network, A1 VM, backup bucket) and Cloudflare (DNS, Pages, TLS), with remote state in OCI Object Storage.
- cloud-init hardening and k3s install; ArgoCD core with KSOPS; app-of-apps with sync waves.
- Cluster baseline: namespaces with Pod Security levels, default-deny NetworkPolicies, quotas and LimitRanges.
- Data services: Postgres with one database per system, RabbitMQ with the `insurehub.events` exchange, Redis; nightly `pg_dump` to object storage; nightly demo reset.
- Kyverno policies (limits, no `:latest`, non-root, keyless signature verification) with CLI tests.
- OpenTelemetry Collector with PII redaction and tail sampling; SLO recording rules and burn-rate alerts with promtool tests; two Grafana dashboards.
- SOPS/age secrets layout with examples only.
- Workflows: validate, terraform plan/apply behind an environment reviewer, reusable build-scan-sign (Trivy, SBOM, cosign), bump-image.
- Scripts: validate, bootstrap-cluster, local-cluster (k3d), rebuild-drill.
- Docs: traceability, test cases, ADR-0006, local-cluster evidence.

### Fixed during the local-cluster run
- Quotas sized for rolling updates (USSD 640Mi, InsureAssist 1400Mi).
- ArgoCD patches no longer carry a namespace (kustomize could not match them).
- Signature policy regex quoting.
