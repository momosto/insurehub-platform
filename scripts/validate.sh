#!/usr/bin/env bash
# Offline checks for everything in this repo. CI (.github/workflows/validate.yml) runs exactly this script.
# Needs on PATH: terraform, kustomize, kubeconform, kyverno, promtool, jq, python3 (PyYAML). gitleaks is optional locally.
set -euo pipefail
cd "$(dirname "$0")/.."

CRD_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
K8S_VERSION="${K8S_VERSION:-1.31.0}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
section() { printf '\n== %s\n' "$1"; }

section "Terraform format and validate"
terraform fmt -check -recursive terraform || fail=1
for dir in terraform/oci terraform/cloudflare; do
  terraform -chdir="$dir" init -backend=false -input=false -no-color >/dev/null
  terraform -chdir="$dir" validate -no-color || fail=1
done

section "Kustomize build + kubeconform (Kubernetes $K8S_VERSION, CRDs from the datree catalog)"
dirs=(clusters/demo/platform clusters/demo/ingress clusters/demo/certs clusters/demo/infra clusters/demo/applications policies/kyverno secrets)
[[ "${SKIP_REMOTE:-0}" == 1 ]] || dirs+=(bootstrap/argocd)
for dir in "${dirs[@]}"; do
  echo "-- $dir"
  kustomize build "$dir" > "$TMP/out.yaml" || { fail=1; continue; }
  # upstream CRDs (ArgoCD) have no published schema; they are not ours to validate
  kubeconform -strict -summary -skip CustomResourceDefinition -kubernetes-version "$K8S_VERSION" \
    -schema-location default -schema-location "$CRD_CATALOG" "$TMP/out.yaml" || fail=1
done

section "Kyverno policy tests"
kyverno test policies/kyverno/tests || fail=1

section "Prometheus rules"
promtool check rules slo/rules.yaml || fail=1
promtool test rules slo/tests/*.yaml || fail=1

section "Grafana dashboards are valid JSON with unique panel ids"
for f in dashboards/*.json; do
  jq -e '(.panels | map(.id) | length) == (.panels | map(.id) | unique | length)' "$f" >/dev/null || { echo "bad: $f"; fail=1; }
done

section "Cloud-init is valid YAML"
PY=python3; $PY -c 'import yaml' 2>/dev/null || PY=python
$PY -c 'import yaml; yaml.safe_load(open("bootstrap/cloud-init.yaml"))' || fail=1

if command -v gitleaks >/dev/null; then
  section "gitleaks"
  gitleaks detect --no-banner --redact || fail=1
fi

if [[ $fail == 0 ]]; then echo; echo "All checks passed."; else echo; echo "Some checks failed."; exit 1; fi
