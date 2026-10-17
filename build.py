#!/usr/bin/env python3
"""Builds the GTK 3 and GTK 4 theme from palette.toml.

Text templates (templates/*) get `{{ expression }}` placeholders filled from the
palette. templates/gtk-3.0.css and gtk-4.0.css come from Graphite; bazalth.css
is appended to both and restyles the widgets that look like the desktop's.
The icons in assets/ are symbolic: GTK recolors them with the text color of the
widget, so they are copied as they are.
"""

import re
import shutil
import tomllib
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parent
TEMPLATES = ROOT / "templates"
GTK_VERSIONS = ("gtk-3.0", "gtk-4.0")


def rgb_tuple(color: str) -> tuple[int, int, int]:
    color = color.lstrip("#")
    return tuple(int(color[i : i + 2], 16) for i in (0, 2, 4))


def mix(fg: str, bg: str, amount: float) -> str:
    """fg drawn over bg at the given opacity, as an opaque #rrggbb (rounded as Qt does)."""
    f, b = rgb_tuple(fg), rgb_tuple(bg)
    return "#%02x%02x%02x" % tuple(round(x * amount + y * (1 - amount)) for x, y in zip(f, b))


def rgba(color: str, alpha: float) -> str:
    """A token at an opacity level, as CSS."""
    return "rgba(%d, %d, %d, %s)" % (*rgb_tuple(color), round(alpha, 4))


def load_palette() -> SimpleNamespace:
    data = tomllib.loads((ROOT / "palette.toml").read_text())
    return SimpleNamespace(
        name=data["name"],
        c=SimpleNamespace(**{k: "#" + v.lower() for k, v in data["colors"].items()}),
        opacity=SimpleNamespace(**data["opacity"]),
        ui=SimpleNamespace(**data["ui"]),
    )


def render(template: str, p: SimpleNamespace) -> str:
    scope = {**vars(p.c), "opacity": p.opacity, "ui": p.ui, "name": p.name, "rgba": rgba, "mix": mix}
    return re.sub(r"\{\{(.*?)\}\}", lambda m: str(eval(m.group(1), {"__builtins__": {}}, scope)), template)


def outrank(css: str) -> str:
    """Give every selector :not(#bazalth) on its first compound: no widget has that ID, so
    the selector still matches the same widgets, but with an ID's weight it beats every
    Graphite rule it overlaps, whatever their order or class count."""
    out, i, depth = [], 0, 0
    while i < len(css):
        if css.startswith("/*", i):
            end = css.index("*/", i) + 2
        elif css.startswith("{{", i):
            end = css.index("}}", i) + 2
        elif css[i] == "{":
            depth, end = depth + 1, i + 1
        elif css[i] == "}":
            depth, end = depth - 1, i + 1
        elif depth == 0 and not css[i].isspace():
            # a selector list: up to the "{" that opens its block
            end = css.index("{", i)
            parts = re.split(r",(?![^()]*\))", css[i:end])
            out.append(",".join(re.sub(r"^(\s*[^\s>+~]+)", r"\1:not(#bazalth)", p) for p in parts))
            i = end
            continue
        else:
            end = i + 1
        out.append(css[i:end])
        i = end
    return "".join(out)


def main() -> None:
    p = load_palette()
    out = ROOT / p.name
    shutil.rmtree(out, ignore_errors=True)
    out.mkdir()
    (out / "index.theme").write_text(render((TEMPLATES / "index.theme").read_text(), p))
    shared = outrank((TEMPLATES / "bazalth.css").read_text())
    for version in GTK_VERSIONS:
        css = render((TEMPLATES / f"{version}.css").read_text() + "\n" + shared, p)
        (out / version).mkdir()
        # One dark variant only: apps asking for the dark one get the same file.
        for name in ("gtk.css", "gtk-dark.css"):
            (out / version / name).write_text(css)
        shutil.copytree(ROOT / "assets", out / version / "assets")
    print(f"Built {out.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
