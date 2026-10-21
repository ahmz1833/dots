# kde

Fonts, themes and Plasma 6 settings. `bootstrap.sh` runs it automatically when
Plasma 6 is installed (`--no-kde` skips it). It does nothing on other systems.

```sh
kde/install.sh --deps     # what this configuration needs on this distro
kde/install.sh            # apply; safe to re-run, also upgrades the themes
kde/install.sh --no-sudo  # skip the Klassy build (the only root step)
```

## Dependencies

`deps.list` maps every requirement to its Fedora, Debian/Ubuntu and Arch package.
Only rows for enabled sections are checked. If anything is missing, the script
stops before changing anything and prints the install command for your distro.
On a fresh system, run `--deps` first.

## Configuration

Defaults (the reference laptop) and a description of every option are in
`config.sh`. Override them in `~/.config/dots/kde.conf`:

```sh
DOTS_KDE_LAYOUT=never              # keep my panels
DOTS_KDE_GET_OREO=0                # don't build the cursor theme
DOTS_KDE_FONT_FIXED="JetBrains Mono"
DOTS_KDE_PANEL_LAUNCHERS="org.kde.konsole preferred://browser code|com.microsoft.VSCode"
```

Nothing personal is set by default: panel launchers and wallpaper folders are empty
unless you set them. `a|b` means "the first one that is installed".

Environment variables override that file, e.g. `DOTS_KDE_KLASSY=skip kde/install.sh`.

| Section | Option | What it does |
|---|---|---|
| Fonts | `DOTS_KDE_FONTS` | Fonts in `assets/fonts` → `~/.local/share/fonts/dots`, Persian fallbacks in `~/.config/fontconfig/conf.d/60-dots-fonts.conf` |
| Themes | `DOTS_KDE_THEMES`, `DOTS_KDE_GET_*` | Orchis GTK, Orchis Plasma style, Tela icons, Oreo cursors, Netspeed widget |
| Klassy | `DOTS_KDE_KLASSY` | `auto` builds it if missing and upgrades it if dots built it; `build`; `skip` |
| Appearance | `DOTS_KDE_APPEARANCE` | Color scheme, Plasma style, icons, cursor, fonts, GTK theme, app style, splash |
| Windows | `DOTS_KDE_WINDOWS` | Decoration, title-bar buttons, Klassy options, effects, task switcher |
| Input | `DOTS_KDE_INPUT` | Keyboard layouts, touchpad (every touchpad KWin reports) |
| Konsole | `DOTS_KDE_KONSOLE` | Profile, color scheme, default profile |
| Session | `DOTS_KDE_SESSION` | Lock timeout, power button, region formats, Spectacle keys, menubars, Dolphin as the folder handler |
| Layout | `DOTS_KDE_LAYOUT` | Bottom panel (`once` by default, because it replaces existing panels), optional wallpaper folders |

## How it stays compatible with System Settings

- Themes are installed into the user folders System Settings lists
  (`~/.themes`, `~/.local/share/{icons,color-schemes,plasma}`), and widgets through
  `kpackagetool6`, so you can switch or remove them there.
- Settings are applied the way each settings page applies them: the
  `plasma-apply-*` tools, the GTK config service, and single keys through
  `kwriteconfig6 --notify`. Whole config files are never replaced.
- Files you may edit in the UI (the color scheme, Konsole colors) are updated only
  while they're unchanged since dots installed them.
- Without a running Plasma session, it writes the same keys and the theme applies
  at the next login. Re-run from inside Plasma to apply everything live.

## Upgrades

Upstream components are cloned into `~/.local/share/dots/src` and reinstalled
only when upstream or the chosen variant changes. State and logs are kept in
`~/.local/state/dots/kde`. Klassy follows the newest `plasmaX.Y` branch that
isn't newer than the running Plasma; set `DOTS_KDE_KLASSY_BRANCH` to pin one.
Klassy is installed into `/usr`, because KWin only loads decorations from system paths.
