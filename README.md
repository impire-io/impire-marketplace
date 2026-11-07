# impire-marketplace

Agent skills and plugins for Impire products. The root is the marketplace; each product's plugin lives under `plugins/<name>/`. Skills follow the open [Agent Skills](https://agentskills.io) standard — self-contained `plugins/<plugin>/skills/<name>/SKILL.md` folders — and the repo doubles as a [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces), so one repo serves every agent.

## Install

**Any agent** (Claude Code, Codex, Cursor, Gemini CLI, and [70+ others](https://github.com/vercel-labs/skills)):

```
npx skills add impire-io/impire-marketplace
```

This installs the skills only — `skills.sh.json` names every skill directory, so `--skill impire-agents` or `--skill hits-cli` picks one. The full plugins — the hits MCP server and slash commands included — are Claude Code's format:

```
/plugin marketplace add impire-io/impire-marketplace
/plugin install impire@impire
/plugin install hits@impire
```

`impire` needs nothing but the Impire terminal client signed in (`impire login <workspace>`), or the console. For `hits`, run `/hits:setup` once — the MCP server boots on one context that dials, and the context chooses the substrate: a chronicle context, where the author of every write is the context's principal and there is no actor to set; or a hits context of a 0.7 fleet, where the actor is set once (`HITS_ACTOR`, or the hits config's default).

**Manual:** copy a skill folder — `plugins/hits/skills/hits-cli`, `plugins/impire/skills/impire-agents` — into your agent's skills directory — `.claude/skills/` for Claude Code, `.agents/skills/` for most other agents.

## Plugins

| Plugin | Ships | Requires |
|---|---|---|
| `impire` | The `impire-agents` skill: adding and operating an agent in an Impire workspace — the document, whom it acts as, the four trigger kinds, runs and their bounds, approvals, the status words, the `impire agents` verbs. | An Impire workspace you administer; the `impire` terminal client v0.13.0 or newer, or the console. |
| `hits` | The `hits-mcp` MCP server (auto-resolved: `$HITS_MCP_BIN` → PATH → verified download of the pinned [hits](https://github.com/impire-io/hits) release), fourteen `/hits:*` lifecycle commands (`setup`, `status`, `file`, `find`, `work`, `claim`, `steal`, `release`, `note`, `block`, `unblock`, `link`, `resolve`, `wontfix`), and the `hits-cli` skill. | A context that dials, of either family: a chronicle context — `chronicle login` for the hosted account, `chronicle context add` for a credential on your own NATS — into an account where `hits store init` has declared the store; or a hits context (`hits context add`) of a HITS of release 0.7.0, with an actor for writes. `brew install impire-io/tap/hits` skips the download step. |

## Derivation

This repo is a **derived view**: no contract is decided or first recorded here. Every published piece declares its upstream sources in [`DERIVATION.md`](DERIVATION.md); skills and commands restate decisions and semantics (stable) and never restate flag signatures (they drift — `hits <command> -h` and `impire <group> <verb> -h` are authoritative).

Sync markers: `hits` last synced at `hits-hq` commit `ad4f6c4`; `impire` last synced at `impire-hq` commit `3e6e489`.

## License

[Sustainable Use License 1.0](LICENSE) — the same fair-code license as HITS itself.
