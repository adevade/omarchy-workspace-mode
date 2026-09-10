# Workspace Mode

Two 3-letter codes in the Omarchy bar for this monitor's workspace:
the layout first, then the focused window state. A teaching widget
for beginners — deliberately faded like an inactive workspace number.
Display-only; hover each code for what it means and the shortcut that
changes it.

```
DWD TIL   dwindle layout, normal tiled window
SCR MAX   scrolling layout, maximized (full-width) window
DWD FUL   dwindle layout, fullscreen window
```

## Codes

Layout slot: `DWD` dwindle, `SCR` scrolling (`Super+L`).

Window slot (top priority wins): `TIL` normal tiled, `MAX`
maximized / full-width (`Super+Alt+F`), `FUL` fullscreen
(`Super+F`), `TFS` tiled fullscreen (`Super+Ctrl+F`), `PIN`
popped out (`Super+O`), `FLT` floating (`Super+T`). Empty
workspaces show the layout code only.

## Install

```sh
omarchy plugin add https://github.com/adevade/omarchy-workspace-mode.git --enable
```

## Usage

Hover the layout code for the layout shortcut, hover the window code
for the window shortcut. Clicks do nothing by design.

Move it anywhere on the bar:

```sh
omarchy bar move io.github.adevade.workspace-mode --section left
```

## Remove

```sh
omarchy plugin remove io.github.adevade.workspace-mode
```

## Known limits

Hyprland IPC (tested on 0.56.2) exposes no pseudo-window flag, so
`Super+P` pseudo state cannot be shown. `Super+J` togglesplit is a
next-split direction, not a per-window mode, and is intentionally
skipped. True fullscreen (`Super+F`) covers the bar, so `FUL` is
visible just before entering and after leaving it.
