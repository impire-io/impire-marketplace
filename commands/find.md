---
description: Find hits items by text, meaning, and graph
argument-hint: "<what you're looking for>"
---

Find the items matching $ARGUMENTS. Use the hits MCP tools when connected; otherwise the `hits` CLI with `--json`.

1. Run both searches — full-text (`search_items`) and by meaning (`semantic_search`) — the query verbatim for the first, the symptom rephrased in plain terms for the second. They surface different things; neither alone is the answer.
2. Fetch snapshots (`get_item`) for the plausible hits and, when one item is clearly the center, pull its edges (`graph_neighbors`) — duplicates and related items often answer the real question.
3. Present the matches with ID, type, status, claim, and a one-line report each; say which one you'd bet on and why. If nothing convincing comes back, say so plainly — a clean miss is what makes filing a new item safe.

Read-only: this command never writes to the tracker.
