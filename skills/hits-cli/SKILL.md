---
name: hits-cli
description: Operate the HITS tracker with the `hits` CLI — file items, move them through the lifecycle, claim work, append notes, and query by text, meaning, or graph. Use when asked to create, update, or look up items in a HITS instance, or when working an issue tracked in hits.
license: Sustainable Use License 1.0 (see LICENSE at the repo root)
metadata:
  author: impire
  version: "0.6.2"
---

# hits-cli — using the hits client

HITS is a headless, agent-native issue tracker. A HITS is one store in a chronicle account — four types, three indexes, every change an operation with an author in the store's history — and nothing of HITS runs as a service: the `hits` binary and the `hits-mcp` server are clients of that store. The platform tracks its own issues — its builders file, claim, work, and close their own items through these same flows. This skill teaches the semantics — the lifecycle and the flows, which are stable. Flag signatures drift: `hits <command> -h` is authoritative, and you should prefer it over anything you think you already know about the flags.

## First: check the binary

Run `hits version`. This skill assumes a client **v0.8.1 or newer** — the release that runs on chronicle. An older client connects through hits contexts to a service fleet that the shared install no longer runs; upgrade rather than adapt. If the command is missing, install it:

- **Homebrew (macOS/Linux):** `brew install impire-io/tap/hits` — installs `hits` and `hits-mcp` together
- **Prebuilt binaries:** https://github.com/impire-io/hits/releases — one archive per platform (darwin, linux, windows; amd64, arm64) carrying both binaries and `install.json`, the store manifest; `checksums.txt` beside the archives
- **From source:** `go install github.com/impire-io/hits/cmd/hits@latest` and the same for `cmd/hits-mcp`

## Setup

- **Global flags go before the command, command flags after the leading `<id>`.**
- **The connection is a chronicle context**, saved by chronicle's own CLI (`brew install impire-io/tap/chronicle`), never by hits. A person signs in to the hosted account with `chronicle login`; a credential on a NATS you run yourself is saved with `chronicle context add`. `hits` speaks through the selected context; `--context <name>` names another. The store is the context's selected store, or `hits`. There is no hits context, no `hits context` or `hits auth` verb, no `hits ping` and no `hits up`: a context that dials is the health check, and nothing of HITS runs.
- **The author of every write is the context's principal** — a person's GitHub login on the hosted account, a service account's name for an agent — stamped and vouched for by chronicle. There is no actor to set: `--actor` and `HITS_ACTOR` are gone, and a write names nobody else. An agent that must write as itself needs its own service account and its own context.
- Filing needs an **initiative** — the group of projects an item's ID mints from. Select yours once with `hits initiative select <slug>` — the one thing hits keeps in a config file of its own; `--initiative` or `$HITS_INITIATIVE` overrides per call. Selection is a **filing default, never a read scope** — queries stay corpus-wide unless you narrow them explicitly.
- `--json` for machine-readable output — prefer it when you are parsing.
- An account has no HITS until `hits store init` declares one: the store with full history, the four types with their lifecycle rules, the three indexes, and the announcement to the account's console. An admin of the account runs it once; every step is idempotent, so running it again finishes what was left and changes nothing that exists. The same declaration ships in the release as `install.json`. On the shared Impire install this is done.

## Two surfaces, one client

`hits-mcp` — installed alongside `hits` by every channel above — serves the same client surface as MCP tools: `create_item` through `graph_walk`, one tool per client method, the same invariants, replies as structured JSON. **When the hits MCP tools are connected, prefer them over shelling out** — same semantics, no output parsing, and read-only tools run without confirmation. The asymmetries to know: the server boots fail-fast on a chronicle context — the selection, or the one it is started with — dials, reads the store's types, and only then serves; it carries no actor, because the context is who the agent is — one process is one agent on one context, and a host running several agents runs several servers; its optional default initiative is fixed at startup — one filing default; and closing over MCP is `transition_item` to `resolved`/`wontfix` carrying the evidence — `hits resolve` and `hits wontfix` are CLI sugar for that same move.

## The model in one breath

Items are `bug` | `task` | `improvement`. Statuses: `open → diagnosing → located → resolved | wontfix`. A **bug** walks the localization stages (`located` requires a project in `located-in`); a **task** already knows its project — it must be created with `--project` and moves straight from `open` to a terminal status; an **improvement** takes either path depending on whether it was filed with a project. Projects are registered slugs (`hits project list`), never free text — and registration and retirement are their whole lifecycle. A mistyped or superseded slug is retired with a reason (`hits project retire`): it leaves the vocabulary but not history — `located-in` refuses it from then on, while items already naming it keep it and still close. A retired slug is never re-registered and never reused, and there is no rename: register the successor, re-point open items, retire the old slug.

Projects group into **initiatives** — the second registered vocabulary, with exactly the same lifecycle: register and retire with a reason, never reused, no rename. Every project belongs to one initiative (`hits project assign` moves it), and an item's initiative is intrinsic from filing: its ID is initiative-prefixed (`hits-19`), minted dense from that initiative's own counter, so an item can never span initiatives — `located-in` accepts only projects of the item's own initiative. Items from before initiatives keep their bare integer IDs (`17`) forever; such a legacy item takes its initiative by an ordinary edit, the one place item initiative is writable. An initiative is a **lens, not a wall**: everyone on an install reads the whole corpus, and scoping (`--initiative` on search and views) is always explicit. One shape rule keeps IDs parseable: an initiative slug never ends in an all-digit segment — the trailing digits of an ID are always the item number.

A **release** is the third registered vocabulary: a named ship point within an initiative, what an item's `target` names. Its lifecycle is register, then **ship** with verifiable refs — a tag, a commit, an artifact — or **retire** with a reason; both are terminal, and a shipped or retired slug is never re-registered or reused. An item carries at most one `target`, set at filing or by edit while the item is active, naming an unshipped, unretired release of its own initiative. No target means "someday", and that is the whole someday mechanism: no icebox, no dates on releases, no tracked progress. **Shipping is refused while any non-terminal item targets the release** — re-target or clear each straggler first; the cut is the triage pass. "What must still land in a release" is a search over open items filtered by target, never a curated list; resolved, targeted, shipped *is* "shipped in", with no second field.

Who did what is not a vocabulary: `reporter` and `claimed-by` are the principals chronicle recorded on the operations, and the graph materializes them as actor nodes beside projects, initiatives and releases.

## Flows

**File:** `hits create --type bug "<report>"` — the report is the symptom in plain terms and how it was observed, not a diagnosis; the ID mints from your selected initiative (`--initiative` overrides). Run `hits semantic "<symptom>"` first to check for an existing item. `--discovered-while` is cheap context the next reader otherwise rediscovers; `--priority` only when it genuinely differs from normal; a target only when the item must land in a known release — otherwise leave it for someday. Create prints the item ID — report it back.

**Work:** `hits claim <id>` records intent before starting (steal only abandoned claims, with `--steal`); `hits release <id>` hands it back. Move status with `hits transition <id> --to <status>`; append the diagnosis trail — hypotheses, evidence, dead ends — as you go with `hits note <id> "<text>"`.

**Blocked:** `hits block <id> --by "<what>"` from any active status; `hits unblock <id>` restores exactly the status it interrupted. The record remembers — do not track the prior status yourself.

**Close:** `hits resolve <id> --fixed-by pr:<ref>` (also `commit:<ref>` or `action:<what>` with evidence), or `hits wontfix <id>` with the reasoning in a note. Terminal is terminal: a defect found later is a **new item**, never a reopen.

**Release:** `hits release register` opens a ship point in your initiative; `hits release ship` closes it with the refs that prove it happened, once no open item targets it; `hits release retire` is the exit for a slug that was a mistake; `hits release list` shows the initiative's releases. One word, two meanings: `hits release <id>` with an item ID hands a claim back, as above.

**Query:** `hits get <id>` for one snapshot — the state, then the trail, each note with the author and time chronicle recorded; `hits search [<query>]` for full-text over reports and notes, with type, status, initiative and target filters; `hits semantic "<text>"` for nearest-by-meaning — it answers only where the chronicle install has an embedding provider configured, which is the install's configuration, not HITS's; `hits graph neighbors|walk <id>` for the edges — links (`hits link <id> --type duplicates|relates-to <to-id>`), located-in, initiative, targets, reported-by, claimed-by and blocked-by — between items, projects, initiatives, releases and actors.

**Audit:** `hits audit` holds the tracker against git — a resolved item's refs must be true on the named local clones' main, and merged work must not leave its item open — and, since the port, reads two more things: the gaps in each initiative's numbering, and the operations after the cutover's sequence whose author chronicle did not vouch for. It writes nothing.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `command not found: hits` | Install it — see *First: check the binary* above. |
| `no chronicle context` | Nothing is selected and nothing was named. `chronicle login` for the hosted account, or `chronicle context add` for a credential on your own NATS; then `chronicle context select <name>`, or pass `--context`. |
| A connect fails or hangs | The context does not dial: the sign-in was forgotten, the credential expired, or the NATS is unreachable. Check it with chronicle's own CLI (`chronicle context show`); nothing of HITS is there to start. |
| A read says the store `hits` or one of its types does not exist | The account has no HITS declared yet. An admin of the account runs `hits store init` once; running it again is safe. |
| `hits-mcp` refuses to start | It boots fail-fast: the context it was given — or the selection — must dial, and the store must hold HITS's types. Fix the context with chronicle's CLI, or have an admin run `hits store init`, then restart the server. |
| `create --type task` is rejected | Tasks must be born located: add `--project <slug>`, registering the slug first if needed (`hits project register`). |
| A transition is rejected | A lifecycle invariant blocked it: terminal statuses accept no transitions, and `--to located` requires a project. Re-read the model above. |
| A write naming a project is refused `retired-project` | The slug is retired vocabulary — permanently. Point at its successor (`hits project list` shows the live slugs) or register one; never re-register the old slug. |
| A create is refused for a missing, unregistered, or retired initiative | Filing needs a live initiative: `hits initiative list` shows them, `hits initiative select <slug>` sets the default, `--initiative` overrides. Register one first if the install has none. |
| A write is refused `initiative-mismatch` | An item cannot span initiatives — the project named belongs to another one. Use a project of the item's own initiative, or move the project with `hits project assign` if it genuinely belongs there. |
| An edit is refused `initiative-immutable` | Only legacy bare-ID items take an initiative by edit; a prefixed ID carries its initiative for life. |
| A target is refused `unknown-release`, `release-shipped` or `release-retired` | `target` names only a registered, unshipped, unretired release of the item's own initiative. `hits release list` shows the live ones; register the release first, or clear the target. |
| A ship is refused `open-targets` | Non-terminal items still target the release; the refusal lists them. Re-target or clear each one, then ship — the cut is the triage pass. |
| `hits semantic` is refused where `hits search` answers | The chronicle install has no embedding provider configured. That is the install's configuration, not HITS's; use `hits search` meanwhile. |
| A report, note, or label is refused as over budget | Free text is budgeted — bodies 8 KiB, labels 1 KiB — and refused whole, never trimmed. Put the artifact in the repo or PR and reference it in the note. |

## Do not

- Do not reopen a terminal item — file a new one and `link` it if related.
- Do not edit or rewrite the trail; notes are append-only history.
- Do not tombstone a real item — `tombstone` voids filing mistakes (a duplicate filed in error, a test record) and nothing else.
- Do not invent project, initiative, or release slugs; `located-in`, filing, and `target` accept live, registered vocabulary only — retired and shipped slugs are refused and never reused.
- Do not look for an actor to set, and do not try to write as somebody else — the author is the context's principal. An agent writes as its own service account, on its own context.
- Do not run `hits migrate`. It exists in the 0.8 releases alone, for the one cutover a person runs on the day; 0.9.0 removes it.
- Do not paste logs or large artifacts into notes — bodies are budgeted (8 KiB) and refused whole when over; the artifact belongs in the repo or PR, its reference in the note.
- Do not restate flag lists from this skill elsewhere — point at `hits <command> -h`.
