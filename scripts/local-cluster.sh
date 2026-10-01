#!/usr/bin/env bash
# A throwaway k3s cluster in Docker (k3d) to try the manifests before they reach the VM.
#   scripts/local-cluster.sh up      create the cluster, apply the platform baseline, policies and data services
#   scripts/local-cluster.sh down    delete it
# ArgoCD is not installed here: the point is to prove the manifests are admitted and the pods become healthy.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=insurehub-local

case "${1:-up}" in
  up)
    k3d cluster create "$NAME" --image rancher/k3s:v1.31.4-k3s1 --agents 0 --wait --api-port 127.0.0.1:6550 \
      -p "8088:80@loadbalancer" --k3s-arg "--disable=metrics-server@server:0"
    kubectl apply -k clusters/demo/platform
    # local-only credentials; the real ones come from SOPS (secrets/)
    pg_args=(--from-literal=POSTGRES_USER=postgres --from-literal=POSTGRES_PASSWORD=local)
    for app in INSUREHUB PAYMENTS NOTIFICATIONS CLAIMGUARD LENDHUB INSUREASSIST; do
      pg_args+=("--from-literal=${app}_PASSWORD=local")
    done
    kubectl -n data create secret generic postgres-credentials "${pg_args[@]}" --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n data create secret generic rabbitmq-credentials --dry-run=client -o yaml \
      --from-literal=RABBITMQ_DEFAULT_USER=insurehub --from-literal=RABBITMQ_DEFAULT_PASS=local | kubectl apply -f -
    kubectl apply -k clusters/demo/infra
    kubectl -n data rollout status statefulset/postgres --timeout=300s
    kubectl -n data rollout status statefulset/rabbitmq --timeout=300s
    kubectl -n data rollout status statefulset/redis --timeout=300s
    kubectl -n data get pods,pvc,cronjobs
    ;;
  down) k3d cluster delete "$NAME" ;;
  *) echo "usage: $0 up|down" >&2; exit 2 ;;
esac
