# Runbook: payment reconciliation mismatch

**Alert:** `reconciliation.mismatch` event → Notifications ops alert · **Owner:** finance ops + on-call engineer

1. Open the Payments reconciliation report for the date. The categories are `AmountMismatch`, `StatusMismatch`, `MissingInLedger` and `MissingAtProvider`.
2. **MissingInLedger** (the provider has it, we don't): check the sweeper logs for the reference. If the payment is genuine, resolve it via the status-poll path so the normal event flow runs. Never insert rows by hand.
3. **MissingAtProvider:** check whether the payment is still `Pending` or expired. Confirm with the provider before marking it failed.
4. **AmountMismatch:** the payment stays in `NeedsReview`. Finance approves it or refunds it, and records the decision with a reason.
5. **StatusMismatch:** trust the provider's settlement file. Trigger a status poll and check that the state machine moved correctly.
6. Close each item with a note. If there are more than 5 mismatches in a day, raise an incident.
