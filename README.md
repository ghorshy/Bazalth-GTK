## Bazalth

Dark, monochrome theme for GTK 3, GTK 4 and libadwaita apps, the sibling of
[Bazalth-KDE](https://github.com/ghorshy/Bazalth-KDE). Flat, compact widgets in shades of
grey, with small rounded corners.

- `Bazalth/`: the theme, ready to install (`gtk-3.0/`, `gtk-4.0/`, `index.theme`)

## Install

```sh
./install.sh            # copy the theme to ~/.local/share/themes
./install.sh --apply    # also select it in gsettings and link it into ~/.config/gtk-4.0
```

`--apply` sets `gtk-theme` and `color-scheme` (`prefer-dark`) in gsettings and links
`gtk.css`, `gtk-dark.css` and `assets` into `~/.config/gtk-4.0`, which is the only way
libadwaita apps pick up a theme. Whatever it replaces is kept in
`~/.local/state/bazalth-gtk`. It leaves `settings.ini` alone; if you keep one, set
`gtk-theme-name=Bazalth` in `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`.

To try it in one app without installing anything else: `GTK_THEME=Bazalth app`.

## Uninstall

```sh
./uninstall.sh          # remove the theme
./uninstall.sh --apply  # also restore what install.sh --apply replaced
```

## Customize

Every color, opacity and size lives in `palette.toml`. Change it, then rebuild:

```sh
./build.py   # Python 3.11+, no dependencies
```

`Bazalth/` is generated from `palette.toml` and the files in `templates/`, and committed so
installing needs no build. `templates/gtk-3.0.css` and `gtk-4.0.css` come from Graphite;
`templates/bazalth.css` is appended to both and draws every widget the Qt theme has the way
the Qt theme draws it (buttons, fields, check boxes, sliders, progress bars, tabs, views, table
headers, scroll bars, spin buttons, menus), plus the switch and headerbar after the desktop.

## Credits

Based on [Graphite GTK theme](https://github.com/vinceliuice/Graphite-gtk-theme) by
vinceliuice: its compiled stylesheets, with every color replaced by a palette token, and its
cursor handle icon, unchanged. The check, dot and line marks are redrawn with the Qt theme's
geometry.

## License

GNU GPL v3
