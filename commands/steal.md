---
description: Take over an abandoned claim on a hits item
argument-hint: "<item id>"
---

Take over the claim on item $ARGUMENTS. Stealing is for **abandoned** claims only — a claimant who stopped without releasing — never for jumping a queue.

1. Fetch the snapshot and check the evidence of abandonment: who holds the claim, when the trail last moved, whether the claimant said anything about stopping. If the claim looks live, stop and report — talk to the claimant instead.
2. If it is abandoned, confirm with the user, then claim with the steal option (`claim_item` with `steal` / `hits claim --steal`). Attribution survives: the record keeps who the claim was stolen from.
3. Append a note saying why the claim was taken over, then continue as /hits:work from wherever the trail left off.
