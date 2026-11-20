#!/bin/sh
set -eu

config_file="${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}"
config="$(dirname "$config_file")"
bindir="${PREFIX:-$HOME/.local}/bin"
backup="$config_file.before-rexdev"
line='require("rexdev").setup{}'
purge=0
[ "${1:-}" = "--purge" ] && purge=1

if [ -L "$bindir/rexdev" ] || [ -f "$bindir/rexdev" ]; then rm -f "$bindir/rexdev"; fi
rm -rf "$config/rexdev"

if [ -f "$config_file" ] && grep -qxF "$line" "$config_file"; then
  expected="$(mktemp)"
  if [ -f "$backup" ]; then
    { cat "$backup"; printf '\n%s\n' "$line"; } > "$expected"
  else
    printf '\n%s\n' "$line" > "$expected"
  fi
  if cmp -s "$expected" "$config_file"; then
    if [ -f "$backup" ]; then cat "$backup" > "$config_file"; else : > "$config_file"; fi
  else
    tmp="$(mktemp)"
    grep -vxF "$line" "$config_file" > "$tmp" || true
    cat "$tmp" > "$config_file"; rm -f "$tmp"
  fi
  rm -f "$expected" "$backup"
  rex config reload >/dev/null 2>&1 || true
elif [ -f "$config_file" ] && grep -q 'require("rexdev")' "$config_file"; then
  echo "note: remove your require(\"rexdev\") lines from $config_file yourself" >&2
fi

if [ -f "$config_file" ] && ! grep -q '[^[:space:]]' "$config_file"; then rm -f "$config_file"; fi

if [ "$purge" = 1 ]; then
  rm -rf "$HOME/.rexdev"
fi

echo "rexdev is uninstalled."
[ "$purge" = 1 ] || echo "To delete its saved state in ~/.rexdev too, run: ./uninstall.sh --purge"
