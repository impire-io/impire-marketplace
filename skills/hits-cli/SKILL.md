---
name: hits-cli
description: Operate the HITS tracker with the `hits` CLI — file items, move them through the lifecycle, claim work, append notes, and query by text, meaning, or graph. Use when asked to create, update, or look up items in a HITS instance, or when working an issue tracked in hits.
license: Sustainable Use License 1.0 (see LICENSE at the repo root)
metadata:
  author: impire
  version: "0.10.0"
---

# hits-cli — using the hits client

HITS is a headless, agent-native issue tracker. A HITS is one store in a chronicle account — four types, three indexes, every change an operation with an author in the store's history — and nothing of HITS runs as a service: the `hits` binary and the `hits-mcp` server are clients of that store. The same two binaries still speak to a HITS of release 0.7.0, the one that ran its own fleet (hits-node and three index services); that fleet is frozen at its release, gets no fix, and the sentences are the same on both. The platform tracks its own issues — its builders file, claim, work, and close their own items through these same flows. This skill teaches the semantics — the lifecycle and the flows, which are stable. Flag signatures drift: `hits <command> -h` is authoritative, and you should prefer it over anything you think you already know about the flags.

## First: check the binary

Run `hits version`. This skill assumes a client **v0.10.0 or newer** — the first release that serves both substrates, a HITS on chronicle and a 0.7 fleet. A 0.8.x client speaks chronicle only and cannot reach a fleet; a 0.7.x client speaks the fleet only and cannot reach chronicle. Upgrade rather than adapt. If the command is missing, install it:

- **Homebrew (macOS/Linux):** `brew install impire-io/tap/hits` — installs `hits` and `hits-mcp` together
- **Prebuilt binaries:** https://github.com/impire-io/hits/releases — one archive per platform (darwin, linux, windows; amd64, arm64) carrying both binaries and `install.json`, the store manifest; `checksums.txt` beside the archives
- **From source:** `go install github.com/impire-io/hits/cmd/hits@latest` and the same for `cmd/hits-mcp`

## Setup

- **Global flags go before the command, command flags after the leading `<id>`.**
- **The connection is a saved context, and the context chooses the substrate.** Two families exist. A **chronicle context** is saved by chronicle's own CLI (`brew install impire-io/tap/chronicle`), never by hits: a person signs in to the hosted account with `chronicle login`; a credential on a NATS you run yourself is saved with `chronicle context add`. It reaches a HITS on chronicle — the context's selected store, or `hits`. A **hits context** is saved by `hits context add`, or by `hits context import` from a nats CLI context, and reaches a fleet of release 0.7.0; `hits context` and `hits auth` manage hits contexts and the token exchange for them, as 0.7 had them, and say nothing about chronicle contexts. `--context <name>` names one: the name resolves against chronicle's contexts first, then hits's own, and a name both families hold is refused — rename one. With no name, `hits` speaks through chronicle's selection, else hits's default context. `hits ping` names what answered on either substrate — the store's announcement on chronicle, the node's name and version on the fleet. Nothing of HITS runs from this client: there is no `hits up`.
- **The author of a write depends on the substrate.** On a chronicle context it is the context's principal — a person's GitHub login on the hosted account, a service account's name for an agent — stamped and vouched for by chronicle; `--actor` and `HITS_ACTOR` are refused there, and a write names nobody else. On a hits context a write needs an **actor** — a stable lowercase handle (`daan`, `claude`) from `--actor`, `$HITS_ACTOR`, or the hits config's default, in that order — because the 0.7 node validates a claimed actor and chronicle vouches for nobody on a fleet write. An agent that must write as itself on chronicle needs its own service account and its own context.
- Filing needs an **initiative** — the group of projects an item's ID mints from. Select yours once with `hits initiative select <slug>` — it lands in hits's own config file, beside the fleet's default actor and context when you have them; `--initiative` or `$HITS_INITIATIVE` overrides per call. Selection is a **filing default, never a read scope** — queries stay corpus-wide unless you narrow them explicitly.
- `--json` for machine-readable output — prefer it when you are parsing.
- A chronicle account has no HITS until `hits store init` declares one: the store with full history, the four types with their lifecycle rules, the three indexes, and the announcement to the account's console. An admin of the account runs it once; every step is idempotent, so running it again finishes what was left and changes nothing that exists. The same declaration ships in the release as `install.json`. It is a chronicle-only verb, refused on a hits context: a 0.7 fleet is not declared, it runs. On the shared Impire install this is the cutover's first step, done by its admin.

## Two surfaces, one client

`hits-mcp` — installed alongside `hits` by every channel above — serves the same client surface as MCP tools: `create_item` through `graph_walk`, one tool per client method, the same invariants, replies as structured JSON. **When the hits MCP tools are connected, prefer them over shelling out** — same semantics, no output parsing, and read-only tools run without confirmation. The asymmetries to know: the server boots fail-fast on one context — the selection, or the one it is started with — which chooses the substrate exactly as it does for the CLI: it dials, reads what answers (the store's types on chronicle, the node's ping on the fleet), and only then serves. On a chronicle context it carries no actor, because the context is who the agent is; on a hits context it takes the actor at startup (`--actor`, or `HITS_ACTOR`, else the hits config's default) and it refuses one on a chronicle context. One process is one agent on one context, and a host running several agents runs several servers; its optional default initiative is fixed at startup — one filing default; and closing over MCP is `transition_item` to `resolved`/`wontfix` carrying the evidence — `hits resolve` and `hits wontfix` are CLI sugar for that same move.

## The model in one breath

Items are `bug` | `task` | `improvement`. Statuses: `open → diagnosing → located → resolved | wontfix`. A **bug** walks the localization stages (`located` requires a project in `located-in`); a **task** already knows its project — it must be created with `--project` and moves straight from `open` to a terminal status; an **improvement** takes either path depending on whether it was filed with a project. Projects are registered slugs (`hits project list`), never free text — and registration and retirement are their whole lifecycle. A mistyped or superseded slug is retired with a reason (`hits project retire`): it leaves the vocabulary but not history — `located-in` refuses it from then on, while items already naming it keep it and still close. A retired slug is never re-registered and never reused, and there is no rename: register the successor, re-point open items, retire the old slug.

Projects group into **initiatives** — the second registered vocabulary, with exactly the same lifecycle: register and retire with a reason, never reused, no rename. Every project belongs to one initiative (`hits project assign` moves it), and an item's initiative is intrinsic from filing: its ID is initiative-prefixed (`hits-19`), minted dense from that initiative's own counter, so an item can never span initiatives — `located-in` accepts only projects of the item's own initiative. Items from before initiatives keep their bare integer IDs (`17`) forever; such a legacy item takes its initiative by an ordinary edit, the one place item initiative is writable. An initiative is a **lens, not a wall**: everyone on an install reads the whole corpus, and scoping (`--initiative` on search and views) is always explicit. One shape rule keeps IDs parseable: an initiative slug never ends in an all-digit segment — the trailing digits of an ID are always the item number.

A **release** is the third registered vocabulary: a named ship point within an initiative, what an item's `target` names. Its lifecycle is register, then **ship** with verifiable refs — a tag, a commit, an artifact — or **retire** with a reason; both are terminal, and a shipped or retired slug is never re-registered or reused. An item carries at most one `target`, set at filing or by edit while the item is active, naming an unshipped, unretired release of its own initiative. No target means "someday", and that is the whole someday mechanism: no icebox, no dates on releases, no tracked progress. **Shipping is refused while any non-terminal item targets the release** — re-target or clear each straggler first; the cut is the triage pass. "What must still land in a release" is a search over open items filtered by target, never a curated list; resolved, targeted, shipped *is* "shipped in", with no second field.

Who did what is not a vocabulary: `reporter` and `claimed-by` are the authors recorded on the operations — the principal chronicle vouched for, or the actor the 0.7 node accepted — and the graph materializes them as actor nodes beside projects, initiatives and releases.

## Flows

**File:** `hits create --type bug "<report>"` — the report is the symptom in plain terms and how it was observed, not a diagnosis; the ID mints from your selected initiative (`--initiative` overrides). Run `hits semantic "<symptom>"` first to check for an existing item. `--discovered-while` is cheap context the next reader otherwise rediscovers; `--priority` only when it genuinely differs from normal; a target only when the item must land in a known release — otherwise leave it for someday. Create prints the item ID — report it back.

**Work:** `hits claim <id>` records intent before starting (steal only abandoned claims, with `--steal`); `hits release <id>` hands it back. Move status with `hits transition <id> --to <status>`; append the diagnosis trail — hypotheses, evidence, dead ends — as you go with `hits note <id> "<text>"`.

**Blocked:** `hits block <id> --by "<what>"` from any active status; `hits unblock <id>` restores exactly the status it interrupted. The record remembers — do not track the prior status yourself.

**Close:** `hits resolve <id> --fixed-by pr:<ref>` (also `commit:<ref>` or `action:<what>` with evidence), or `hits wontfix <id>` with the reasoning in a note. Terminal is terminal: a defect found later is a **new item**, never a reopen.

**Release:** `hits release register` opens a ship point in your initiative; `hits release ship` closes it with the refs that prove it happened, once no open item targets it; `hits release retire` is the exit for a slug that was a mistake; `hits release list` shows the initiative's releases. One word, two meanings: `hits release <id>` with an item ID hands a claim back, as above.

**Query:** `hits get <id>` for one snapshot — the state, then the trail, each note with the author and time recorded on it; `hits search [<query>]` for full-text over reports and notes, with type, status, initiative and target filters; `hits semantic "<text>"` for nearest-by-meaning — on chronicle it answers only where the install has an embedding provider configured, which is the install's configuration, not HITS's; on a 0.7 fleet the fleet's own meaning index answers; `hits graph neighbors|walk <id>` for the edges — links (`hits link <id> --type duplicates|relates-to <to-id>`), located-in, initiative, targets, reported-by, claimed-by and blocked-by — between items, projects, initiatives, releases and actors.

**Audit:** `hits audit` holds the tracker against git — a resolved item's refs must be true on the named local clones' main, and merged work must not leave its item open — and, on chronicle, reads two more things: the gaps in each initiative's numbering, and the operations after the cutover's sequence whose author chronicle did not vouch for (`--since-seq`, a chronicle-only read, refused on a fleet). It writes nothing.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `command not found: hits` | Install it — see *First: check the binary* above. |
| `no context` | Nothing is selected and nothing was named; the refusal names both ways to get one. For a HITS on chronicle: `chronicle login` for the hosted account, or `chronicle context add` for a credential on your own NATS, then `chronicle context select <name>`. For a 0.7 fleet: `hits context add <name>` (or `hits context import`), then `hits context select <name>`. Or pass `--context` on the call. |
| `context "<name>" is both a chronicle context and a hits context` | The two families hold the same name, so the name does not say which substrate it dials. Rename one. |
| `--actor and HITS_ACTOR name an actor, and a chronicle context's author is its principal` | An actor was given on a chronicle context. Drop `--actor` and unset `HITS_ACTOR`: the author there is the principal. If the fleet was meant, name its hits context. |
| `no actor for the 0.7 fleet` | A write on a hits context names nobody. Pass `--actor`, set `HITS_ACTOR`, or set the default actor in the hits client config, as 0.7 had it. |
| `no token for context "<name>"` | An `oauth` hits context with no login yet — `hits auth login --context <name>` (device flow: open the URL, enter the code); `hits auth status` shows where things stand. |
| `unreachable` | No fleet answers on that hits context: nothing of release 0.7.0 is running there. `hits ping` confirms it; `hits context ls` shows what the context points at. This client starts nothing — the fleet is its operator's to run, from the 0.7.0 release's own binaries. A fleet that needs a fix is not fixed; its operator moves the install to chronicle with `hits migrate`. |
| A connect on a chronicle context fails or hangs | The context does not dial: the sign-in was forgotten, the credential expired, or the NATS is unreachable. Check it with chronicle's own CLI (`chronicle context show`); nothing of HITS is there to start. |
| `this verb speaks to a chronicle context; the context dialled is a 0.7 fleet` | `store init`, `migrate` and `audit --since-seq` are chronicle-only verbs. Name a chronicle context: a fleet is not declared, and a migration runs on the destination's context with the fleet's hits context as its source. |
| A read says the store `hits` or one of its types does not exist | The account has no HITS declared yet. An admin of the account runs `hits store init` once; running it again is safe. |
| `hits-mcp` refuses to start | It boots fail-fast: the context it was given — or the selection — must dial, and what answers must be a HITS (the store's types on chronicle, the node's ping on a fleet). On a hits context it also needs an actor at startup; on a chronicle context it refuses one. Fix the context (chronicle's CLI, or `hits context`), set or unset the actor, or have an admin run `hits store init`, then restart the server. |
| `create --type task` is rejected | Tasks must be born located: add `--project <slug>`, registering the slug first if needed (`hits project register`). |
| A transition is rejected | A lifecycle invariant blocked it: terminal statuses accept no transitions, and `--to located` requires a project. Re-read the model above. |
| A write naming a project is refused `retired-project` | The slug is retired vocabulary — permanently. Point at its successor (`hits project list` shows the live slugs) or register one; never re-register the old slug. |
| A create is refused for a missing, unregistered, or retired initiative | Filing needs a live initiative: `hits initiative list` shows them, `hits initiative select <slug>` sets the default, `--initiative` overrides. Register one first if the install has none. |
| A write is refused `initiative-mismatch` | An item cannot span initiatives — the project named belongs to another one. Use a project of the item's own initiative, or move the project with `hits project assign` if it genuinely belongs there. |
| An edit is refused `initiative-immutable` | Only legacy bare-ID items take an initiative by edit; a prefixed ID carries its initiative for life. |
| A target is refused `unknown-release`, `release-shipped` or `release-retired` | `target` names only a registered, unshipped, unretired release of the item's own initiative. `hits release list` shows the live ones; register the release first, or clear the target. |
| A ship is refused `open-targets` | Non-terminal items still target the release; the refusal lists them. Re-target or clear each one, then ship — the cut is the triage pass. |
| `hits semantic` is refused where `hits search` answers | On chronicle, the install has no embedding provider configured. That is the install's configuration, not HITS's; use `hits search` meanwhile. |
| A report, note, or label is refused as over budget | Free text is budgeted — bodies 8 KiB, labels 1 KiB — and refused whole, never trimmed. Put the artifact in the repo or PR and reference it in the note. |

## Do not

- Do not reopen a terminal item — file a new one and `link` it if related.
- Do not edit or rewrite the trail; notes are append-only history.
- Do not tombstone a real item — `tombstone` voids filing mistakes (a duplicate filed in error, a test record) and nothing else.
- Do not invent project, initiative, or release slugs; `located-in`, filing, and `target` accept live, registered vocabulary only — retired and shipped slugs are refused and never reused.
- Do not look for an actor to set on a chronicle context, and do not try to write as somebody else — there the author is the context's principal, and an agent writes as its own service account, on its own context. On a hits context, set the actor once — the hits config's default, or `HITS_ACTOR` — and keep it; it is your handle, not a per-call choice.
- Do not try to fix a 0.7 fleet. It is frozen at the v0.7.0 release: no fix and no feature reaches hits-node or the index services, and there is no 0.7.1. A defect that is the fleet's is answered by the install's move to chronicle, by its operator.
- Do not run `hits migrate`. It moves a whole 0.7 install into a chronicle account, once, run by a person on the day; it stays in the client as long as a 0.7 fleet exists, and a builder never runs it.
- Do not paste logs or large artifacts into notes — bodies are budgeted (8 KiB) and refused whole when over; the artifact belongs in the repo or PR, its reference in the note.
- Do not restate flag lists from this skill elsewhere — point at `hits <command> -h`.
