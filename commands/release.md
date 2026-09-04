---
description: Hand a hits claim back, leaving the trail ready for the next actor
argument-hint: "<item id>"
---

Release the claim on item $ARGUMENTS. Before handing it back, make sure the trail says where things stand — append a note (`note_item` / `hits note`) covering what was tried, what was ruled out, and what the next actor should look at first, unless the existing notes already say exactly that.

Then release (`release_item` / `hits release`) and confirm the item is unclaimed. An item released with a good trail is a handoff; one released silently is just abandoned politely.
