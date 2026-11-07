---
description: The "what's open" view — open hits items with claims and blockers
argument-hint: "[filter, e.g. a project or search text]"
---

Report where the tracker stands. Use the hits MCP tools when connected; otherwise the `hits` CLI with `--json`.

1. Search for non-terminal items (`search_items` / `hits search`), narrowed by $ARGUMENTS if given. Fetch snapshots for the hits (`get_item` / `hits get`).
2. Group by status — `open`, `diagnosing`, `located`, `blocked` — and for each item show its type, one-line report, who holds the claim (and how stale it looks), and for blocked items what they are blocked by.
3. Lead with the shape: how many items open, how many claimed vs unclaimed, how many blocked and on what. Call out anything that looks stuck — long-held claims with no recent notes, blockers nobody owns.

Read-only: this command never writes to the tracker.
