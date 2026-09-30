# Runbook: messages in a dead-letter queue

**Alert:** `DLQ not empty` · **Severity:** warning (critical if a `payments.*` DLQ) · **Owner:** on-call engineer

## Check
1. RabbitMQ management → Queues → filter `.dlq`. Note the queue, message count and oldest message age.

## Diagnose
2. Inspect a message: headers `x-death`, last error, `eventId`, `traceparent`.
3. Open the trace in Grafana/Tempo using the trace ID from `traceparent` to find the failing span.
4. Classify it:
   - **Transient** (provider outage or timeouts, now recovered) → replay.
   - **Poison** (bad payload, schema mismatch, bug) → don't replay yet. Open an issue, fix, deploy, then replay.

## Fix
5. Replay with the DLQ replay tool (planned in Integrations: `POST /admin/dlq/{queue}/replay?max=100`), or shovel messages back to the source queue from the management UI.

## Verify
6. DLQ is empty and the consumer's inbox table shows the events processed once. Consumers are idempotent, so duplicates are ignored.

## Escalate
7. If payments are affected for > 30 min, notify finance ops. Write a postmortem if customers were affected.
