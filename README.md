# impire-marketplace

Agent skills and plugins for Impire products. Skills follow the open [Agent Skills](https://agentskills.io) standard — self-contained `skills/<name>/SKILL.md` folders — and the repo doubles as a [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces), so one repo serves every agent.

## Install

**Any agent** (Claude Code, Codex, Cursor, Gemini CLI, and [70+ others](https://github.com/vercel-labs/skills)):

```
npx skills add impire-io/impire-marketplace
```

This installs the skills only. The full plugin — MCP server and slash commands included — is Claude Code's format:

```
/plugin marketplace add impire-io/impire-marketplace
/plugin install hits@impire
```

Then run `/hits:setup` once — the MCP server needs a hits context and an actor before it will boot.

**Manual:** copy a folder from `skills/` into your agent's skills directory — `.claude/skills/` for Claude Code, `.agents/skills/` for most other agents.

## Plugins

| Plugin | Ships | Requires |
|---|---|---|
| `hits` | The `hits-mcp` MCP server (auto-resolved: `$HITS_MCP_BIN` → PATH → verified download of the pinned [hits](https://github.com/impire-io/hits) release), fourteen `/hits:*` lifecycle commands (`setup`, `status`, `file`, `find`, `work`, `claim`, `steal`, `release`, `note`, `block`, `unblock`, `link`, `resolve`, `wontfix`), and the `hits-cli` skill. | A reachable HITS fleet; `brew install impire-io/tap/hits` skips the download step. |

## Derivation

This repo is a **derived view**: no contract is decided or first recorded here. Every published piece declares its upstream sources in [`DERIVATION.md`](DERIVATION.md); skills and commands restate decisions and semantics (stable) and never restate flag signatures (they drift — `hits <command> -h` is authoritative).

Sync marker: last synced at `hits-hq` commit `7476c6d`.

## License

[Sustainable Use License 1.0](LICENSE) — the same fair-code license as HITS itself.
