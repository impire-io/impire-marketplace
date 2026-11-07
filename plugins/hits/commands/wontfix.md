---
description: Close a hits item as wontfix, with the reasoning on the record
argument-hint: "<item id> [why]"
---

Close the item named in $ARGUMENTS as wontfix. The reasoning is the deliverable: append a note first saying why this won't be fixed — cost, obsolescence, working as intended, superseded by what — so the decision survives the person who made it. If $ARGUMENTS doesn't say why, ask.

Then close: via the hits MCP tools this is `transition_item` to `wontfix` (`hits wontfix` on the CLI). If it's superseded by other work, link the items.

Terminal is terminal: if the problem turns out to matter after all, file a new item and link it back — never reopen.
