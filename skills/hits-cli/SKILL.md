---
name: hits-cli
description: Operate the HITS tracker with the `hits` CLI — file items, move them through the lifecycle, claim work, append notes, and query by text, meaning, or graph. Use when asked to create, update, or look up items in a HITS instance, or when working an issue tracked in hits.
license: Sustainable Use License 1.0 (see LICENSE at the repo root)
metadata:
  author: impire
  version: "0.2.0"
---

# hits-cli — using the hits client

HITS is a headless, agent-native issue tracker running on NATS; the `hits` binary is the terminal view of its full client surface. This skill teaches the semantics — the lifecycle and the flows, which are stable. Flag signatures drift: `hits <command> -h` is authoritative, and you should prefer it over anything you think you already know about the flags.

## First: check the binary

Run `hits version`. This skill assumes a client **newer than v0.2.0**: standalone hits contexts and the `hits context` verbs. A v0.2.0-or-older client resolves nats CLI contexts directly and lacks those verbs — upgrade rather than adapt. If the command is missing, install it:

- **Homebrew (macOS/Linux):** `brew install impire-io/tap/hits`
- **Prebuilt binaries:** https://github.com/impire-io/hits/releases — darwin, linux, and windows tarballs for amd64 and arm64
- **From source:** `go install github.com/impire-io/hits/cmd/hits@latest`

## Setup

- **Global flags go before the command, command flags after the leading `<id>`.**
- `--context <name>` selects a **hits context** — a hits-owned document at `~/.config/hits/context/<name>.json`: the NATS connection nested under a `nats` key (the nats CLI's context schema, unchanged), plus optional hits blocks like `oauth` (`issuer` and `client_id`). hits never reads the nats CLI's contexts at connect time; bring one over once with `hits context import <name>`. The `hits context` family (`ls`, `add`, `import`, `edit`, `rm`, `select`) manages the directory — `select` just records the default in the config file. `hits ping` verifies the service is reachable before anything else.
- An `oauth` context (deployments whose NATS auth callout accepts IDP access tokens) needs one interactive login before anything connects: `hits auth login --context <name>` — device flow, open the URL, enter the code. Refresh is transparent afterward, across reconnects too; `hits auth status` shows where things stand, `hits auth logout` clears the cached tokens.
- Every write carries an **actor**: a stable lowercase handle (`daan`, `claude`) from `--actor`, `$HITS_ACTOR`, or `defaults.actor` in `~/.config/hits/config.json` (which also takes `defaults.context`). Set one before writing; commands without one are rejected.
- `--json` for machine-readable output — prefer it when you are parsing.
- No service running yet? `hits up` runs the whole fleet — hits-node plus the graph, search, and semantic indexes — in this process, in the foreground, against whatever NATS system the context points at.

## The model in one breath

Items are `bug` | `task` | `improvement`. Statuses: `open → diagnosing → located → resolved | wontfix`. A **bug** walks the localization stages (`located` requires a project in `located-in`); a **task** already knows its project — it must be created with `--project` and moves straight from `open` to a terminal status; an **improvement** takes either path depending on whether it was filed with a project. Projects are registered slugs (`hits project list`), never free text.

## Flows

**File:** `hits create --type bug "<report>"` — the report is the symptom in plain terms and how it was observed, not a diagnosis. Run `hits semantic "<symptom>"` first to check for an existing item. `--discovered-while` is cheap context the next reader otherwise rediscovers; `--priority` only when it genuinely differs from normal. Create prints the item ID — report it back.

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

## Do not

- Do not reopen a terminal item — file a new one and `link` it if related.
- Do not edit or rewrite the trail; notes are append-only history.
- Do not tombstone a real item — `tombstone` voids filing mistakes (a duplicate filed in error, a test record) and nothing else.
- Do not invent project slugs; `located-in` accepts registered projects only.
- Do not restate flag lists from this skill elsewhere — point at `hits <command> -h`.
