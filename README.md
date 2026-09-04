# impire-marketplace

Agent skills and plugins for Impire products. Skills follow the open [Agent Skills](https://agentskills.io) standard — self-contained `skills/<name>/SKILL.md` folders — and the repo doubles as a [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces), so one repo serves every agent.

## Install

**Any agent** (Claude Code, Codex, Cursor, Gemini CLI, and [70+ others](https://github.com/vercel-labs/skills)):

```
npx skills add impire-io/impire-marketplace
```

**Claude Code**, as a plugin:

```
/plugin marketplace add impire-io/impire-marketplace
/plugin install hits@impire
```

**Manual:** copy a folder from `skills/` into your agent's skills directory — `.claude/skills/` for Claude Code, `.agents/skills/` for most other agents.

## Plugins

| Plugin | Skills | Teaches | Requires |
|---|---|---|---|
| `hits` | `hits-cli` | Operating [HITS](https://github.com/impire-io/hits) — headless, agent-native issue tracking — through the `hits` CLI. | The `hits` binary: `brew install impire-io/tap/hits` (the skill covers the alternatives). |

## Derivation

This repo is a **derived view**: no contract is decided or first recorded here. Every skill declares its upstream sources in [`DERIVATION.md`](DERIVATION.md); skills restate decisions and semantics (stable) and never restate flag signatures (they drift — `hits <command> -h` is authoritative).

Sync marker: last synced at `hits-hq` commit `021758a`.

## License

[Sustainable Use License 1.0](LICENSE) — the same fair-code license as HITS itself.
