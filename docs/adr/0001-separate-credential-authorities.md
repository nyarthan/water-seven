---
status: accepted
---

# Separate credential authorities and revocation domains

Water Seven classifies credentials by their issuing authority and revocation domain rather than treating a workstation role, one GitHub account, SOPS, or one vault as the security boundary. Personal and work Bitwarden accounts remain separate human authorities, STACKIT Secrets Manager owns work application secrets, SOPS delivers only selected personal static machine secrets, and provider-generated sessions remain renewable local state; this keeps work ciphertext out of the public repository and permits overlapping accounts without collapsing recovery or revocation.
