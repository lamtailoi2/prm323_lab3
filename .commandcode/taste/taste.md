# Taste

- Writes to the agent in Vietnamese and expects replies in Vietnamese (code, commands, and file paths stay as-is). Confidence: 0.7
- For evidence screenshots, wants one full-screen capture per UI state, taken directly on the emulator he is currently running against the real app/signed-in test account — not rendered from a temporary fake-data harness, and not redacted (no white blocks painted over names/emails/phones). Confidence: 0.8
- Rejects the agent inventing requirements on its own: don't apply a rule found in a repo doc (e.g. evidence/README.md's "Never include personal data") as if he had asked for it, and don't add extra steps like redaction; ask first or do only what was requested. Confidence: 0.75
