---
description: Close a hits item as resolved, with the evidence that fixed it
argument-hint: "<item id> <fixed-by, e.g. pr:17>"
---

Resolve the item named in $ARGUMENTS. A resolution carries evidence: a `fixed-by` reference — `pr:<ref>`, `commit:<ref>`, or `action:<what>` for fixes that live outside version control. No evidence, no resolve — ask for it rather than inventing it.

If the closing reasoning isn't already in the trail, append it as a note first. Then close: via the hits MCP tools this is `transition_item` to `resolved` carrying `fixed-by` (`hits resolve` is the CLI's sugar for the same move).

Terminal is terminal: if the defect shows up again later, that is a **new item** linked to this one, never a reopen.
