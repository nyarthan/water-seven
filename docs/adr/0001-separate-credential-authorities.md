---
status: accepted
---

# Separate credential authorities and revocation domains

Water Seven classifies credentials by their issuing authority and revocation domain rather than treating a workstation role, one GitHub account, SOPS, or one vault as the security boundary. Company policy—not Water Seven—governs work storage and access through facilities such as work Bitwarden and STACKIT Secrets Manager; SOPS delivers only selected personal static machine secrets, and provider-generated sessions remain renewable local state. This keeps work ciphertext out of the public repository and permits overlapping accounts without collapsing recovery or revocation.
