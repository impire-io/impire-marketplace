#!/usr/bin/env bash
# Launches the hits-mcp stdio server for the Claude Code plugin.
#
# Binary resolution, first hit wins:
#   1. $HITS_MCP_BIN             — developer override, used as-is
#   2. hits-mcp on PATH          — an install the user manages (brew tap, go install)
#   3. cached copy in the plugin data dir, re-verified against its recorded sha256
#   4. download the hits release archive pinned below for this OS/arch from
#      GitHub releases, verify against checksums.txt, cache, run.
#
# Any failure exits 1 with the manual install options; a failed download or
# verification never leaves a cached binary behind.
#
# hits-mcp itself is fail-fast: it needs a chronicle context that dials —
# the selected one, saved by chronicle's own CLI (chronicle login, or
# chronicle context add) — and a store that holds HITS's types, or it
# refuses to serve. There is no actor: the author of every write is the
# context's principal. /hits:setup walks through all of that.
set -euo pipefail

# The hits release this plugin version is paired with. Bump alongside the
# plugin version in .claude-plugin/plugin.json.
HITS_VERSION="0.8.0"

manual_help() {
  cat >&2 <<'EOF'

Manual install options:
  brew install impire-io/tap/hits          # installs hits and hits-mcp
  go install github.com/impire-io/hits/cmd/hits-mcp@latest
  # or download a binary from https://github.com/impire-io/hits/releases
Then either put hits-mcp on PATH or set HITS_MCP_BIN to its path.
Run /hits:setup in Claude Code for a guided setup.
EOF
  exit 1
}

fail() {
  echo "hits plugin: $*" >&2
  manual_help
}

# 1. Explicit override.
if [[ -n "${HITS_MCP_BIN:-}" ]]; then
  exec "$HITS_MCP_BIN" "$@"
fi

# 2. PATH.
if command -v hits-mcp >/dev/null 2>&1; then
  exec hits-mcp "$@"
fi

data_dir="${CLAUDE_PLUGIN_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/hits-plugin}"
bin_dir="$data_dir/bin/v$HITS_VERSION"
cached="$bin_dir/hits-mcp"

sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    fail "neither shasum nor sha256sum is available to verify downloads"
  fi
}

# 3. Verified cache. A recorded digest that no longer matches (truncated or
# tampered download) forces a fresh fetch instead of running the file.
if [[ -x "$cached" && -f "$cached.sha256" ]]; then
  if [[ "$(sha256 "$cached")" == "$(cat "$cached.sha256")" ]]; then
    exec "$cached" "$@"
  fi
  rm -f "$cached" "$cached.sha256"
fi

# 4. Download the pinned release.
case "$(uname -s)" in
  Darwin) os="darwin" ;;
  Linux)  os="linux" ;;
  *) fail "unsupported OS $(uname -s) — install the binary manually" ;;
esac
case "$(uname -m)" in
  arm64|aarch64) arch="arm64" ;;
  x86_64|amd64)  arch="amd64" ;;
  *) fail "unsupported architecture $(uname -m) — install the binary manually" ;;
esac

fetch() { # fetch <url> <outfile>
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  else
    fail "neither curl nor wget is available to download the server binary"
  fi
}

archive="hits_${HITS_VERSION}_${os}_${arch}.tar.gz"
base="https://github.com/impire-io/hits/releases/download/v$HITS_VERSION"

mkdir -p "$data_dir"
tmp="$(mktemp -d "$data_dir/download.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fetch "$base/$archive" "$tmp/$archive" \
  || fail "download failed: $base/$archive"
fetch "$base/checksums.txt" "$tmp/checksums.txt" \
  || fail "download failed: $base/checksums.txt"

expected="$(awk -v f="$archive" '$2 == f {print $1}' "$tmp/checksums.txt")"
[[ -n "$expected" ]] || fail "checksums.txt has no entry for $archive"
actual="$(sha256 "$tmp/$archive")"
[[ "$actual" == "$expected" ]] \
  || fail "checksum mismatch for $archive (expected $expected, got $actual) — refusing to install"

tar -xzf "$tmp/$archive" -C "$tmp" hits-mcp \
  || fail "could not extract hits-mcp from $archive"
chmod +x "$tmp/hits-mcp"
sha256 "$tmp/hits-mcp" > "$tmp/hits-mcp.sha256"

mkdir -p "$bin_dir"
mv "$tmp/hits-mcp" "$cached"
mv "$tmp/hits-mcp.sha256" "$cached.sha256"

# exec never returns, so the EXIT trap cannot clean up — do it now.
rm -rf "$tmp"
trap - EXIT
exec "$cached" "$@"
