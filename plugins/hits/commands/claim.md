---
description: Claim a hits item — record intent to work it before starting
argument-hint: "<item id>"
---

Claim item $ARGUMENTS (`claim_item` via the hits MCP tools, or `hits claim`). A claim records intent, not started work — take it before touching the item, not after.

If the claim is rejected because someone already holds it (`already-claimed`), report who and stop. Do not steal here: /hits:steal exists for that, and only for claims that are actually abandoned.

After claiming, fetch the snapshot and summarize where the item stands — status, trail so far, links — so work starts from the record.
