#!/usr/bin/env bash
# Rebuild drill (PF-08, docs/runbooks/rebuild-environment.md): replace the VM, bootstrap, wait for every
# application to be healthy, restore the latest backup and record the times in docs/evidence/rebuild-drills.md.
# Destructive: it replaces the demo VM. Run it only against the demo environment, with a recent backup.
set -euo pipefail
cd "$(dirname "$0")/.."
read -r -p "This replaces the demo VM. Type 'rebuild' to continue: " answer
[[ "$answer" == rebuild ]] || exit 1

start=$(date +%s)
terraform -chdir=terraform/oci apply -replace=oci_core_instance.node -auto-approve
ip=$(terraform -chdir=terraform/oci output -raw node_public_ip)
admin="${ADMIN_USER:-ops}"
echo "Waiting for k3s on $ip"
until ssh -o StrictHostKeyChecking=accept-new "$admin@$ip" sudo test -f /etc/rancher/k3s/k3s.yaml; do sleep 10; done
ssh "$admin@$ip" sudo cat /etc/rancher/k3s/k3s.yaml > "$HOME/.kube/insurehub"
export KUBECONFIG="$HOME/.kube/insurehub"
# the API server is not public: tunnel localhost:6443 to the node for the rest of the drill
ssh -N -L 6443:127.0.0.1:6443 "$admin@$ip" &
tunnel=$!
trap 'kill $tunnel' EXIT
sleep 3

scripts/bootstrap-cluster.sh
echo "Waiting for every ArgoCD application to be Healthy"
until [[ -z "$(kubectl -n argocd get applications -o jsonpath='{range .items[?(@.status.health.status!="Healthy")]}{.metadata.name}{"\n"}{end}')" ]]; do
  sleep 20
done
apps_ready=$(date +%s)

echo "Now restore the latest backup: docs/runbooks/backup-restore.md, section 'Restore'."
read -r -p "Press enter when the row counts match. " _
done_at=$(date +%s)

mins() { echo $(( ($1 - start) / 60 )); }
printf '| %s | %s min | %s min | %s |\n' "$(date +%F)" "$(mins "$apps_ready")" "$(mins "$done_at")" "${NOTES:-}" \
  >> docs/evidence/rebuild-drills.md
echo "Recorded in docs/evidence/rebuild-drills.md (target: under 60 minutes)."
