# ADR-0005: Production target architecture is AKS (paper design)

- **Status:** Proposed · **Date:** 2026-09-30

## Context
Zimbabwean insurers and banks are mostly Microsoft shops; interviewers will ask how the demo becomes production.

## Decision
Production = AKS (zone-redundant, 3 node pools), Azure Database for PostgreSQL Flexible Server (HA), RabbitMQ quorum-queue cluster (or Azure Service Bus behind the same transport interface), Front Door + WAF, Key Vault via External Secrets, Entra ID for staff SSO, and the same ArgoCD app-of-apps with a `clusters/prod` overlay.

## Consequences
- ➕ Only `terraform/` and overlays change; app manifests are reused.
- ➖ Cost (not incurred for the portfolio); documented as a sized estimate when needed.
- Supports AZ-305 study: this ADR doubles as exam practice.
