# Runbook: rebuild the demo environment from scratch

**Trigger:** VM lost, reclaimed or corrupted · **Target:** under 1 hour

1. `terraform -chdir=terraform/oci apply` creates the VM, networking and bucket.
2. cloud-init installs k3s and applies the hardening. Fetch the kubeconfig through an SSH tunnel.
3. Create the one bootstrap secret, the SOPS age key: `kubectl -n argocd create secret generic sops-age --from-file=keys.txt`.
4. `kubectl apply -k bootstrap/argocd`. ArgoCD then syncs infra → observability → apps.
5. Restore the databases from the latest backup (`backup-restore.md`), or let the apps reseed demo data.
6. `terraform -chdir=terraform/cloudflare apply` if the public IP changed.
7. Verify that all UptimeRobot monitors are green. Record the time taken in `../evidence/rebuild-drills.md`.
