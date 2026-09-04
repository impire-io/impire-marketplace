---
description: Block a hits item on the thing that's in its way
argument-hint: "<item id> <what it's blocked by>"
---

Block the item named in $ARGUMENTS on the stated obstacle (`block_item` via the hits MCP tools, or `hits block`). Name the blocker concretely — the item, decision, dependency, or person being waited on — so the next reader knows what has to change before work resumes. If the blocker is itself a tracked item, also link the two (/hits:link, `relates-to`).

The record remembers the status the block interrupted; do not track it yourself. Unblocking (/hits:unblock) restores it exactly.
