# Derivation

The upstream sources each published piece is derived from, per `hits-hq` playbook 06 (builder-skill sync). A piece with no row here cannot be kept current and is not published.

| Piece | Upstream repo | Path | What it takes |
|---|---|---|---|
| `skills/hits-cli` | `hits-hq` | `02-DESIGN/item-model.md` | Item types, statuses and lifecycle, invariants, trail and link semantics, projects and actors. |
| `skills/hits-cli` | `hits-hq` | `02-DESIGN/hits-up.md` | What `hits up` runs and its context/connection semantics. |
| `skills/hits-cli` | `hits-hq` | `02-DESIGN/idp-auth.md` | hits contexts (standalone documents: nats subtree + oauth block), the context and auth verb families, config defaults, and the exchange-vs-validation dividing line. |
| `skills/hits-cli` | `hits-hq` | `02-DESIGN/mcp-server.md` | The MCP tool surface (one tool per client endpoint), read-only annotations, transition-carries-closing semantics, and the fail-fast boot contract (context, actor, ping). |
| `skills/hits-cli` | `hits-hq` | `03-DECISIONS/0013-issue-tracking-cutover.md` | That the platform tracks its own issues — the tracker is the front door for hits' own development. |
| `skills/hits-cli` | `hits` | releases, `Formula` via `impire-io/homebrew-tap` | Distribution channels for the binaries (brew tap, release tarballs, `go install`). Flag signatures are pointed at (`hits <command> -h`), never restated. |
| `commands/*` | `hits-hq` | `02-DESIGN/item-model.md` | The lifecycle flows each command walks — dedup-before-file, claim-before-work, steal-only-abandoned, blocked-status-remembered, close-with-evidence, terminal-is-terminal. |
| `.mcp.json`, `scripts/hits-mcp.sh` | `hits-hq` | `02-DESIGN/mcp-server.md` | That `hits-mcp` is a per-agent stdio process configured by context and actor, refusing to serve when the fleet is unreachable. |
| `scripts/hits-mcp.sh` | `hits` | releases (`checksums.txt`), `.goreleaser.yaml` | Archive naming and checksum verification for the pinned release download; the pin (`HITS_VERSION`) bumps with the plugin version. |
