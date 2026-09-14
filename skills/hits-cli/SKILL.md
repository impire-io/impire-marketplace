---
name: hits-cli
description: Operate the HITS tracker with the `hits` CLI — file items, move them through the lifecycle, claim work, append notes, and query by text, meaning, or graph. Use when asked to create, update, or look up items in a HITS instance, or when working an issue tracked in hits.
license: Sustainable Use License 1.0 (see LICENSE at the repo root)
metadata:
  author: impire
  version: "0.5.0"
---

# hits-cli — using the hits client

HITS is a headless, agent-native issue tracker running on NATS; the `hits` binary is the terminal view of its full client surface. The platform tracks its own issues — its builders file, claim, work, and close their own items through these same flows. This skill teaches the semantics — the lifecycle and the flows, which are stable. Flag signatures drift: `hits <command> -h` is authoritative, and you should prefer it over anything you think you already know about the flags.

## First: check the binary

Run `hits version`. This skill assumes a client **v0.6.2 or newer**: standalone hits contexts and the `hits context` verbs (post-v0.2.0), project retirement (v0.5.0), and initiatives with initiative-prefixed item IDs (v0.6.0, completed by the v0.6.1–v0.6.2 assignment and replay fixes). An older client lacks part of this surface — upgrade rather than adapt. If the command is missing, install it:

- **Homebrew (macOS/Linux):** `brew install impire-io/tap/hits`
- **Prebuilt binaries:** https://github.com/impire-io/hits/releases — darwin, linux, and windows tarballs for amd64 and arm64
- **From source:** `go install github.com/impire-io/hits/cmd/hits@latest`

## Setup

- **Global flags go before the command, command flags after the leading `<id>`.**
- `--context <name>` selects a **hits context** — a hits-owned document at `~/.config/hits/context/<name>.json`: the NATS connection nested under a `nats` key (the nats CLI's context schema, unchanged), plus optional hits blocks like `oauth` (`issuer` and `client_id`). hits never reads the nats CLI's contexts at connect time; bring one over once with `hits context import <name>`. The `hits context` family (`ls`, `add`, `import`, `edit`, `rm`, `select`) manages the directory — `select` just records the default in the config file. `hits ping` verifies the service is reachable before anything else.
- An `oauth` context (deployments whose NATS auth callout accepts IDP access tokens) needs one interactive login before anything connects: `hits auth login --context <name>` — device flow, open the URL, enter the code. Refresh is transparent afterward, across reconnects too; `hits auth status` shows where things stand, `hits auth logout` clears the cached tokens.
- Every write carries an **actor**: a stable lowercase handle (`daan`, `claude`) from `--actor`, `$HITS_ACTOR`, or `defaults.actor` in `~/.config/hits/config.json` (which also takes `defaults.context`). Set one before writing; commands without one are rejected.
- Filing needs an **initiative** — the group of projects an item's ID mints from. Select yours once with `hits initiative select <slug>` (it lands in the config beside the default actor); `--initiative` or `$HITS_INITIATIVE` overrides per call. Selection is a **filing default, never a read scope** — queries stay corpus-wide unless you narrow them explicitly.
- `--json` for machine-readable output — prefer it when you are parsing.
- No service running yet? `hits up` runs the whole fleet — hits-node plus the graph, search, and semantic indexes — in this process, in the foreground, against whatever NATS system the context points at.

## Two surfaces, one client

`hits-mcp` — installed alongside `hits` by every channel above — serves the same client surface as MCP tools: `create_item` through `graph_walk`, one tool per endpoint, the same invariants, replies as structured JSON. **When the hits MCP tools are connected, prefer them over shelling out** — same semantics, no output parsing, and read-only tools run without confirmation. The asymmetries to know: setup stays on the CLI (contexts, auth, `hits up` — the server refuses to boot without a working context and an actor); the server fixes its actor, and its optional default initiative, at startup — one process, one identity, one filing default; and closing over MCP is `transition_item` to `resolved`/`wontfix` carrying the evidence — `hits resolve` and `hits wontfix` are CLI sugar for that same move.

## The model in one breath

Items are `bug` | `task` | `improvement`. Statuses: `open → diagnosing → located → resolved | wontfix`. A **bug** walks the localization stages (`located` requires a project in `located-in`); a **task** already knows its project — it must be created with `--project` and moves straight from `open` to a terminal status; an **improvement** takes either path depending on whether it was filed with a project. Projects are registered slugs (`hits project list`), never free text — and registration and retirement are their whole lifecycle. A mistyped or superseded slug is retired with a reason (`hits project retire`): it leaves the vocabulary but not history — `located-in` refuses it from then on, while items already naming it keep it and still close. A retired slug is never re-registered and never reused, and there is no rename: register the successor, re-point open items, retire the old slug.

Projects group into **initiatives** — the second registered vocabulary, with exactly the same lifecycle: register and retire with a reason, never reused, no rename. Every project belongs to one initiative (`hits project assign` moves it), and an item's initiative is intrinsic from filing: its ID is initiative-prefixed (`hits-19`), minted dense from that initiative's own counter, so an item can never span initiatives — `located-in` accepts only projects of the item's own initiative. Items from before initiatives keep their bare integer IDs (`17`) forever; such a legacy item takes its initiative by an ordinary edit, the one place item initiative is writable. An initiative is a **lens, not a wall**: everyone on an install reads the whole corpus, and scoping (`--initiative` on search and views) is always explicit. One shape rule keeps IDs parseable: an initiative slug never ends in an all-digit segment — the trailing digits of an ID are always the item number.

## Flows

**File:** `hits create --type bug "<report>"` — the report is the symptom in plain terms and how it was observed, not a diagnosis; the ID mints from your selected initiative (`--initiative` overrides). Run `hits semantic "<symptom>"` first to check for an existing item. `--discovered-while` is cheap context the next reader otherwise rediscovers; `--priority` only when it genuinely differs from normal. Create prints the item ID — report it back.

**Work:** `hits claim <id>` records intent before starting (steal only abandoned claims, with `--steal`); `hits release <id>` hands it back. Move status with `hits transition <id> --to <status>`; append the diagnosis trail — hypotheses, evidence, dead ends — as you go with `hits note <id> "<text>"`.

**Blocked:** `hits block <id> --by "<what>"` from any active status; `hits unblock <id>` restores exactly the status it interrupted. The record remembers — do not track the prior status yourself.

**Close:** `hits resolve <id> --fixed-by pr:<ref>` (also `commit:<ref>` or `action:<what>` with evidence), or `hits wontfix <id>` with the reasoning in a note. Terminal is terminal: a defect found later is a **new item**, never a reopen.

**Query:** `hits get <id>` for one snapshot; `hits search [<query>]` for full-text with status/type filters; `hits semantic "<text>"` for nearest-by-meaning; `hits graph neighbors|walk <id>` for the edges — links (`hits link <id> --type duplicates|relates-to <to-id>`), projects, and actors.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `command not found: hits` | Install it — see *First: check the binary* above. |
| `hits ping` hangs or errors | No service on that context. Start one with `hits up --context <name>`, or check the context with `hits context ls`. |
| `no context "<name>"` | The name has no file in hits' context directory — `hits context add <name>` creates one, `hits context import <name>` brings a nats CLI context over. |
| `no token for context "<name>"` | An `oauth` context with no login yet — run `hits auth login --context <name>`. |
| A write is rejected for a missing actor | Set `--actor` or `$HITS_ACTOR` to a stable lowercase handle. |
| `create --type task` is rejected | Tasks must be born located: add `--project <slug>`, registering the slug first if needed (`hits project register`). |
| A transition is rejected | A lifecycle invariant blocked it: terminal statuses accept no transitions, and `--to located` requires a project. Re-read the model above. |
| A write naming a project is refused `retired-project` | The slug is retired vocabulary — permanently. Point at its successor (`hits project list` shows the live slugs) or register one; never re-register the old slug. |
| A create is refused for a missing, unregistered, or retired initiative | Filing needs a live initiative: `hits initiative list` shows them, `hits initiative select <slug>` sets the default, `--initiative` overrides. Register one first if the install has none. |
| A write is refused `initiative-mismatch` | An item cannot span initiatives — the project named belongs to another one. Use a project of the item's own initiative, or move the project with `hits project assign` if it genuinely belongs there. |
| An edit is refused `initiative-immutable` | Only legacy bare-ID items take an initiative by edit; a prefixed ID carries its initiative for life. |
| A report, note, or label is refused as over budget | Free text is budgeted — bodies 8 KiB, labels 1 KiB — and refused whole, never trimmed. Put the artifact in the repo or PR and reference it in the note. |

## Do not

- Do not reopen a terminal item — file a new one and `link` it if related.
- Do not edit or rewrite the trail; notes are append-only history.
- Do not tombstone a real item — `tombstone` voids filing mistakes (a duplicate filed in error, a test record) and nothing else.
- Do not invent project or initiative slugs; `located-in` and filing accept live, registered vocabulary only — retired slugs are refused and never reused.
- Do not paste logs or large artifacts into notes — bodies are budgeted (8 KiB) and refused whole when over; the artifact belongs in the repo or PR, its reference in the note.
- Do not restate flag lists from this skill elsewhere — point at `hits <command> -h`.
