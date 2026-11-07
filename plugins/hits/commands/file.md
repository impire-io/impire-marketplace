---
description: File a hits item properly — dedup check first, symptom-not-diagnosis report
argument-hint: "<what happened>"
---

File $ARGUMENTS as a hits item. Use the hits MCP tools when connected; otherwise the `hits` CLI.

1. **Dedup first.** Run a semantic search (`semantic_search` / `hits semantic`) for the symptom. If a near-match exists, show it and ask whether this is the same defect — if so, add what's new as a note on the existing item instead of filing a duplicate.
2. **Write the report as the symptom**, in plain terms, with how it was observed — never a diagnosis or a proposed fix. Those belong in notes once someone works the item.
3. **Pick the type.** `bug` for observed misbehavior, `task` for known work (must name a project from `list_projects` — register the slug first if it's genuinely new), `improvement` for making something better. Add what the reporter was doing when they hit it (`discovered-while`); set a priority only when it genuinely differs from normal.
4. **Create it** (`create_item` / `hits create`) and report the new item ID back to the user.
