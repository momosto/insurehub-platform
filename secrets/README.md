# Secrets

Every secret the demo cluster needs, encrypted with [SOPS](https://github.com/getsops/sops) and [age](https://age-encryption.org) (ADR-0003, PF-07).

| File | Namespace | Used by |
|---|---|---|
| `postgres-credentials` | data | Postgres, backup and reset jobs |
| `rabbitmq-credentials` | data | RabbitMQ |
| `backup-storage` | data | nightly `pg_dump` upload to OCI Object Storage |
| `grafana-cloud-otlp` | observability | OpenTelemetry Collector |
| `lendhub-secrets`, `insureassist-secrets`, `insurehub-ussd-secrets` | per app | the apps' `envFrom` |

## How it works

1. `examples/` holds templates with placeholder values only. They are not applied to the cluster.
2. `scripts/bootstrap-cluster.sh` copies each example to `secrets/<name>.enc.yaml`, you fill in the values, and `sops --encrypt --in-place` encrypts only `data`/`stringData` using the recipient in `.sops.yaml`.
3. Uncomment the generator in `kustomization.yaml`. ArgoCD's repo server runs KSOPS with the age private key (Kubernetes Secret `sops-age` in `argocd`, created once by the bootstrap script) and applies the decrypted Secrets.
4. CI runs gitleaks on every push and fails if anything that looks like a credential is committed in plain text.

## Rotating

`sops secrets/<name>.enc.yaml` opens the decrypted file in your editor and re-encrypts on save. Commit, then restart the affected deployment (`kubectl rollout restart`). To rotate the age key, add the new recipient to `.sops.yaml`, run `sops updatekeys` on every file, replace the `sops-age` Secret and remove the old recipient.

## Losing the key

Keep a copy of `keys.txt` in a password manager. Without it the encrypted files cannot be read, and every secret has to be re-created from the examples.
