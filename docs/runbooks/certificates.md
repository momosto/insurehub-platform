# Runbook: TLS certificate expiring or failing

**Alert:** certificate expires in < 14 days, or browsers show TLS errors

1. `kubectl get certificates -A`, then `kubectl describe certificate <name> -n <ns>`.
2. Check the `CertificateRequest` → `Order` → `Challenge` status. The usual cause is an HTTP-01 challenge that can't reach Traefik (a Cloudflare redirect rule or a firewall).
3. If Cloudflare is in the way, set the record to DNS-only (grey cloud) until the certificate is issued, then turn the proxy back on.
4. Check Let's Encrypt rate limits before retrying repeatedly.
5. Force a renewal: `cmctl renew <name> -n <ns>`.
6. Verify: `curl -vI https://<host>` shows the new expiry date.
