# Runbook: suspected personal-data breach

The demo only holds fictional data, but this procedure is written so it would work for a real deployment under the Cyber and Data Protection Act [Chapter 12:07].

⏱️ **The 24-hour notification clock starts when you become aware of the breach.** Run steps 1–3 in parallel.

1. **Contain:** revoke exposed credentials and keys, and block the access path. Preserve logs; don't delete evidence.
2. **Assess:** what data was exposed, how many data subjects, which systems and what time window. Use the Loki audit logs and traces.
3. **Escalate:** notify the Data Protection Officer and management immediately.
4. **Notify:** the Act requires the data controller to notify the Data Protection Authority (POTRAZ) **within 24 hours** of becoming aware of the breach. Published guidance describes using notification form DP4, and informing affected data subjects (72 h is cited) where the breach is high-risk. Confirm the current requirements with the DPO or legal counsel. Sources: [the Act (POTRAZ)](https://potraz.gov.zw/wp-content/uploads/2025/02/Cyber-and-Data-Protection-Act-Chapter-1207.pdf) · [DLA Piper Africa guide](https://www.dlapiperafrica.com/en/zimbabwe/insights/2024/A-Quick-Start-Guide-to-Zimbabwes-Data-Protection-Regulations).
5. **Recover:** rotate secrets, patch the weakness, and restore from a clean backup if needed.
6. **Learn:** write a blameless postmortem, then update the threat models and controls.
