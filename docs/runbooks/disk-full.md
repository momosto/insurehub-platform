# Runbook: disk usage above 80%

1. On the VM: `df -h`, then `sudo du -xh /var/lib/rancher --max-depth=3 | sort -h | tail`.
2. Usual suspects: old container images (`sudo k3s crictl rmi --prune`), Loki/Prometheus retention, PostgreSQL WAL, ClaimGuard uploads.
3. Reduce retention in the observability values if needed (default: 7 days).
4. If the volume must grow: resize it in OCI (within the free allowance), then run `growpart` and `resize2fs`.
5. Verify: usage below 70%, all pods `Running`.
