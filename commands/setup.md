---
description: First-run hits setup — install the binaries, set up a context, log in, set the actor, verify with ping
argument-hint: "[context name]"
---

Walk the user through getting hits working end to end. Fix each step before moving to the next; finish by reporting what is configured and what (if anything) still needs a restart.

1. **Binaries.** Run `hits version`. If missing, install: `brew install impire-io/tap/hits` (installs `hits` and `hits-mcp` together), a release tarball from https://github.com/impire-io/hits/releases, or `go install github.com/impire-io/hits/cmd/hits@latest` plus `.../cmd/hits-mcp@latest`.
2. **Context.** `hits context ls`. If the user named one in $ARGUMENTS, target that. If none exist: `hits context import <name>` brings over a nats CLI context, `hits context add <name>` creates one fresh. Make one the default with `hits context select <name>` — the MCP server connects with the selected context.
3. **Auth.** If the context carries an `oauth` block, run `hits auth login --context <name>` (device flow — show the user the URL and code) and confirm with `hits auth status`.
4. **Actor.** Every write needs a stable lowercase handle. Ask the user for theirs and set `defaults.actor` in `~/.config/hits/config.json` — that file is where both the CLI and `hits-mcp` pick it up without per-command flags.
5. **Verify.** `hits ping`. If it hangs, no fleet is running on that context — `hits up` runs the whole thing in the foreground, or point the context at a deployment that has one.
6. **MCP server.** If the hits MCP tools are not present in this session, the server was not connected at startup — now that config exists, reconnect it (`/mcp`) or restart Claude Code.
