#!/usr/bin/env bash
# Day-1 bootstrap after `terraform apply` (PF-08). The API server is not public, so run it through the SSH tunnel:
#   $(terraform -chdir=terraform/oci output -raw ssh_tunnel_for_kubectl) &      # forwards localhost:6443
#   ssh <admin>@<ip> sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/insurehub     # already points at 127.0.0.1:6443
#   KUBECONFIG=~/.kube/insurehub scripts/bootstrap-cluster.sh
# Safe to run again. After it finishes, ArgoCD owns everything else.
set -euo pipefail
cd "$(dirname "$0")/.."
AGE_KEY="${AGE_KEY:-$HOME/.config/sops/age/keys.txt}"

echo "1/4 age key for SOPS"
if [[ ! -f "$AGE_KEY" ]]; then
  mkdir -p "$(dirname "$AGE_KEY")"
  age-keygen -o "$AGE_KEY"
  echo "   Created $AGE_KEY. Put its public key in secrets/.sops.yaml and save the file in your password manager."
fi
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd create secret generic sops-age --from-file=keys.txt="$AGE_KEY" --dry-run=client -o yaml | kubectl apply -f -

echo "2/4 encrypted secrets"
for example in secrets/examples/*.yaml; do
  target="secrets/$(basename "$example" .yaml).enc.yaml"
  if [[ ! -f "$target" ]]; then
    cp "$example" "$target"
    echo "   Fill in $target, then: sops --encrypt --in-place $target"
  fi
done
if grep -l "change-me" secrets/*.enc.yaml >/dev/null 2>&1; then
  echo "   Some secrets still contain change-me. Fill them in, encrypt, uncomment the generator in"
  echo "   secrets/kustomization.yaml, commit, push and run this script again."
fi

echo "3/4 ArgoCD (core install + KSOPS)"
kubectl apply -k bootstrap/argocd --server-side
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo "4/4 root application (app-of-apps)"
kubectl apply -f bootstrap/argocd/root-app.yaml
echo "Done. Watch it converge: kubectl -n argocd get applications -w"
