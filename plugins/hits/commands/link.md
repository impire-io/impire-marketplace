---
description: Assert a typed link between two hits items
argument-hint: "<item id> <duplicates|relates-to> <other id>"
---

Link the two items named in $ARGUMENTS with the stated edge type (`link_items` via the hits MCP tools, or `hits link`). `duplicates` says the two records describe the same defect — the newer one usually then closes pointing at the older; `relates-to` is any weaker connection worth the next reader's attention.

Fetch both snapshots first and sanity-check the claim — a `duplicates` edge between items describing different symptoms is worse than no edge. A mistaken edge is retracted with `unlink_items`, not left to mislead the graph.
