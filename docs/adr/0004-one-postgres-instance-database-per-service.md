# ADR-0004: One PostgreSQL instance, one database and role per system

- **Status:** Accepted · **Date:** 2026-09-30

## Context
Principle P1 says each system owns its data. Running six PostgreSQL instances on one free VM wastes RAM.

## Decision
One PostgreSQL 16 StatefulSet; a separate database **and** login role per system; no role can connect to another system's database. Integration only via APIs and events.

## Consequences
- ➕ Data ownership preserved logically; ~5 GB RAM saved.
- ➖ Shared failure domain and noisy neighbours; acceptable for a demo. Production uses separate managed servers, or at least a separate server for LendHub (financial core).
