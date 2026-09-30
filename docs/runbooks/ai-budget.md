# Runbook: AI token budget nearly used up

**Alert:** daily tokens > 80% of `AI_DAILY_TOKEN_BUDGET` (ClaimGuard or InsureAssist)

1. Open the `ai_tokens_used_total` panel, broken down by app and by client IP.
2. If one IP dominates, block it at Cloudflare/Traefik and lower the per-IP rate limit.
3. If the traffic is organic, switch the app to offline/demo mode (`AI_MODE=offline`) until the daily reset.
4. Never raise the budget without checking the provider's billing page first.
5. Verify: the token rate drops and the app shows the "demo mode" banner.
