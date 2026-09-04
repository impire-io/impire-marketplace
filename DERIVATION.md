# Derivation

The upstream sources each skill is derived from, per `hits-hq` playbook 06 (builder-skill sync). A skill with no row here cannot be kept current and is not published.

| Skill | Upstream repo | Path | What it takes |
|---|---|---|---|
| `skills/hits-cli` | `hits-hq` | `02-DESIGN/item-model.md` | Item types, statuses and lifecycle, invariants, trail and link semantics, projects and actors. |
| `skills/hits-cli` | `hits-hq` | `02-DESIGN/hits-up.md` | What `hits up` runs and its context/connection semantics. |
| `skills/hits-cli` | `hits` | releases, `Formula` via `impire-io/homebrew-tap` | Distribution channels for the binary (brew tap, release tarballs, `go install`). Flag signatures are pointed at (`hits <command> -h`), never restated. |
