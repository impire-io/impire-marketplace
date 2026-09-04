---
description: Work a hits item end to end — claim, diagnose on the record, close with evidence
argument-hint: "<item id>"
---

Work item $ARGUMENTS to a conclusion. Use the hits MCP tools when connected; otherwise the `hits` CLI.

1. **Read before touching.** Fetch the snapshot (`get_item`) and the surrounding graph (`graph_neighbors`) — linked items, project, prior actors. The trail is the diagnosis so far; start from it, don't rediscover it.
2. **Claim it** (`claim_item`) before doing anything. If it's already claimed, stop and report the claimant — take over only via /hits:steal, and only for an abandoned claim.
3. **Diagnose on the record.** Move status as reality changes (`transition_item`: `open → diagnosing → located`; `located` needs a registered project in `located-in`). Append every hypothesis, piece of evidence, and dead end as notes (`note_item`) as you go — the trail is for the next reader, not a summary written at the end.
4. **If blocked**, record it (`block_item`) with what it's blocked by, and stop; unblocking restores the interrupted status automatically.
5. **Close with evidence.** Resolved needs a `fixed-by` (`pr:`, `commit:`, or `action:` reference) — /hits:resolve covers it; a wontfix needs the reasoning in a note first — /hits:wontfix. If you must stop without finishing, note where things stand and release the claim (/hits:release) so the next actor starts from your trail.
