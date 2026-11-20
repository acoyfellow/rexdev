#!/bin/sh
set -eu

here="$(cd "$(dirname "$0")" && pwd -P)"
config_file="${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}"
config="$(dirname "$config_file")"
bindir="${PREFIX:-$HOME/.local}/bin"

fail() { echo "rexdev: $*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || fail "rexdev runs on macOS only for now."
command -v jq >/dev/null 2>&1 || fail "rexdev needs jq. Run: brew install jq"
command -v node >/dev/null 2>&1 || fail "rexdev needs node, which wrangler needs too."
command -v rex >/dev/null 2>&1 || fail "rexdev needs Rex and its rex command: https://www.superlogical.com/rex/docs/installation"
command -v rexweb >/dev/null 2>&1 || echo "warning: rexdev opens its preview with rexweb: https://github.com/acoyfellow/rexweb" >&2

mkdir -p "$bindir"
ln -sf "$here/bin/rexdev" "$bindir/rexdev"
echo "linked $bindir/rexdev"

mkdir -p "$config/rexdev"
sed "s|@BIN@|$bindir/rexdev|" "$here/lua/init.lua" > "$config/rexdev/init.lua"
line='require("rexdev").setup{}'
if ! grep -Eqs "require[[:space:]]*\(?[\"']rexdev[\"']" "$config_file"; then
  [ -f "$config_file" ] && cp "$config_file" "$config_file.before-rexdev"
  printf '\n%s\n' "$line" >> "$config_file"
  if rex config check "$config_file" >/dev/null 2>&1; then
    echo "added $line to $config_file"
  else
    if [ -f "$config_file.before-rexdev" ]; then cat "$config_file.before-rexdev" > "$config_file"; else rm -f "$config_file"; fi
    fail "adding $line made $config_file invalid, so rexdev put it back. Add the line yourself, then run: rex config reload"
  fi
fi
rex config reload >/dev/null 2>&1 || echo "warning: rex config reload failed. Check $config_file with: rex config check" >&2

echo
"$bindir/rexdev" doctor || true
case ":$PATH:" in
  *":$bindir:"*) ;;
  *)
    echo
    echo "$bindir isn't on your PATH. Add it with:"
    echo "  echo 'export PATH=\"$bindir:\$PATH\"' >> ~/.zprofile && export PATH=\"$bindir:\$PATH\""
    ;;
esac
echo
echo "rexdev is installed. In a Worker folder, press Shift-Cmd-D in Rex, or run: rexdev"
