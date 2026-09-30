# Runbook: backups and restore

**Backup job:** the `pg-backup` CronJob runs at 02:30 Africa/Harare: `pg_dumpall` → gzip → encrypt with age → upload to object storage. It keeps 14 daily and 8 weekly copies.
**Alert:** no successful backup in 26 h.

## If the backup is missing
1. `kubectl get jobs -n infra | grep pg-backup`; read the logs of the last failed job.
2. Common causes: expired object-storage credentials, a full disk, PostgreSQL unreachable.
3. Fix the cause, then trigger a manual run: `kubectl create job --from=cronjob/pg-backup pg-backup-manual -n infra`.

## Restore a single database
1. Download the latest object and decrypt it with `age -d` using the backup key.
2. Scale the owning app to zero: `kubectl scale deploy/<app> --replicas=0 -n <ns>`.
3. `psql` into the postgres pod, drop and recreate that database, and restore only that database from the dump.
4. Scale the app back up, check `/health/ready` and run the app's smoke test.

## Monthly drill
Restore yesterday's backup into a scratch database, run row-count checks, and record the date and duration in `../evidence/restore-drills.md`.
