# SLOs and alerting

Window: 30 days rolling. Alerting uses multi-window burn rates (fast: 1 h/5 min at 14.4×; slow: 6 h/30 min at 6×).

| Service | SLI | SLO (demo) | Production target (paper) |
|---|---|---|---|
| InsureHub API | successful requests (non-5xx) / all | 99.0% | 99.9% |
| InsureHub API | p95 latency of `/api/policies*` | < 500 ms | < 300 ms |
| Payments API | payments reaching a final state within 10 min | 99.0% | 99.9% |
| Payments API | webhook processing success | 99.5% | 99.95% |
| Notifications | messages delivered or correctly fallen back within 5 min | 99.0% | 99.5% |
| ClaimGuard | claims triaged within 2 min of upload | 95% | 99% |
| LendHub | end-of-day batch completes before 05:00 | 99% of days | 99.9% |
| LendHub API | non-5xx | 99.0% | 99.9% |
| InsureAssist | first reply within 10 s | 95% | 99% |
| InsureAssist | eval pass rate on release (quality SLO) | ≥ 90% | ≥ 95% |
| USSD gateway | response within 2 s (aggregators time out quickly) | 99% | 99.5% |

## Non-SLO alerts

| Alert | Condition | Runbook |
|---|---|---|
| DLQ not empty | `rabbitmq_queue_messages{queue=~".*\\.dlq"} > 0` for 10 min | `runbooks/dead-letter-queue.md` |
| Reconciliation mismatch | `reconciliation_mismatches_total` increased | `runbooks/reconciliation-mismatch.md` |
| Certificate expiry | < 14 days | `runbooks/certificates.md` |
| Disk usage | > 80% | `runbooks/disk-full.md` |
| Backup missing | no successful backup in 26 h | `runbooks/backup-restore.md` |
| AI budget | daily tokens > 80% of budget | `runbooks/ai-budget.md` |
