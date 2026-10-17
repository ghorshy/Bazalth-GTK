#!/usr/bin/env bash
# Removes the installed theme.
#   ./uninstall.sh          remove the theme only
#   ./uninstall.sh --apply  also restore what ./install.sh --apply replaced
set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bazalth-gtk"
NAME=$(sed -n 's/^name *= *"\(.*\)"/\1/p' "$SRC_DIR/palette.toml")
THEME="$DATA_DIR/themes/$NAME"
GTK4="$CONFIG_DIR/gtk-4.0"

case "${1:-}" in
  --apply)
    if [ -e "$STATE_DIR/gsettings" ] && command -v gsettings >/dev/null; then
      while read -r key value; do
        gsettings set org.gnome.desktop.interface "$key" "$value"
        echo "Restored $key $value"
      done < "$STATE_DIR/gsettings"
    fi
    for file in gtk.css gtk-dark.css assets; do
      target="$GTK4/$file"
      [ "$(readlink "$target" 2>/dev/null)" = "$THEME/gtk-4.0/$file" ] && rm -f "$target"
      if [ -e "$STATE_DIR/gtk-4.0/$file" ] || [ -L "$STATE_DIR/gtk-4.0/$file" ]; then
        mv "$STATE_DIR/gtk-4.0/$file" "$target"
        echo "Restored $target"
      fi
    done
    rm -rf "${STATE_DIR:?}" ;;
  "") ;;
  *) echo "usage: $0 [--apply]" >&2; exit 1 ;;
esac

rm -rf "${THEME:?}"
echo "Removed $NAME"
