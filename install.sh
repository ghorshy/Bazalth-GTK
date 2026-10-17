#!/usr/bin/env bash
# Installs the GTK theme for the current user.
#   ./install.sh          copy the theme to ~/.local/share/themes
#   ./install.sh --apply  also select it: gsettings (GTK 3 and GTK 4 apps) and
#                         ~/.config/gtk-4.0 (libadwaita apps); the previous state
#                         is kept for ./uninstall.sh --apply
set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bazalth-gtk"
NAME=$(sed -n 's/^name *= *"\(.*\)"/\1/p' "$SRC_DIR/palette.toml")
THEME="$DATA_DIR/themes/$NAME"
GTK4="$CONFIG_DIR/gtk-4.0"
GTK4_FILES=(gtk.css gtk-dark.css assets)

apply=false
case "${1:-}" in
  --apply) apply=true ;;
  "") ;;
  *) echo "usage: $0 [--apply]" >&2; exit 1 ;;
esac

mkdir -p "$DATA_DIR/themes"
rm -rf "${THEME:?}"
cp -r "$SRC_DIR/$NAME" "$THEME"
echo "Installed $NAME to $THEME"

if ! $apply; then
  cat <<EOF

To use it:
  - GTK 3 and GTK 4: gtk-theme-name=$NAME in ~/.config/gtk-{3,4}.0/settings.ini,
    or: gsettings set org.gnome.desktop.interface gtk-theme $NAME
  - libadwaita apps ignore the theme name; link $THEME/gtk-4.0/{gtk.css,gtk-dark.css,assets}
    into $GTK4
Or run: $0 --apply
EOF
  exit 0
fi

mkdir -p "$STATE_DIR" "$GTK4"

# Remember the previous settings once, so a second --apply keeps the original ones.
if [ ! -e "$STATE_DIR/gsettings" ] && command -v gsettings >/dev/null; then
  for key in gtk-theme color-scheme; do
    echo "$key $(gsettings get org.gnome.desktop.interface "$key")"
  done > "$STATE_DIR/gsettings"
fi
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme "$NAME"
  # libadwaita picks its light or dark colors from this, not from the theme
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi

for file in "${GTK4_FILES[@]}"; do
  target="$GTK4/$file"
  if [ "$(readlink "$target" 2>/dev/null)" != "$THEME/gtk-4.0/$file" ]; then
    if [ -e "$target" ] || [ -L "$target" ]; then
      mkdir -p "$STATE_DIR/gtk-4.0"
      backup="$STATE_DIR/gtk-4.0/$file"
      # the first backup is what uninstall restores; later ones are only kept
      { [ -e "$backup" ] || [ -L "$backup" ]; } && backup="$backup.$(date +%s)"
      mv "$target" "$backup"
    fi
    ln -s "$THEME/gtk-4.0/$file" "$target"
  fi
done

echo "Applied $NAME (previous settings saved in $STATE_DIR). Restart GTK apps to see it."
echo "settings.ini is left alone: set gtk-theme-name=$NAME there yourself if you manage it."
