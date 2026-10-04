# shellcheck shell=bash
# Defaults for dots/kde. They reproduce the reference laptop.
#
# Override any value in ~/.config/dots/kde.conf (plain VAR=value lines) or as
# an environment variable; the environment wins over the file, the file wins
# over these defaults. Every section can be switched off with 0.

# ---------------------------------------------------------------- sections ---
: "${DOTS_KDE_FONTS:=1}"        # bundled fonts + fontconfig fallbacks
: "${DOTS_KDE_THEMES:=1}"       # fetch / upgrade the upstream components below
: "${DOTS_KDE_KLASSY:=auto}"    # auto: build if missing, upgrade if built by dots | build | skip
: "${DOTS_KDE_APPEARANCE:=1}"   # colors, Plasma style, icons, cursor, fonts, GTK, splash
: "${DOTS_KDE_WINDOWS:=1}"      # window decoration, title-bar buttons, Klassy, effects, task switcher
: "${DOTS_KDE_INPUT:=1}"        # keyboard layouts, touchpad
: "${DOTS_KDE_KONSOLE:=1}"      # Konsole profile + color scheme
: "${DOTS_KDE_SESSION:=1}"      # screen lock, power button, region formats, shortcuts, menubars
: "${DOTS_KDE_LAYOUT:=once}"    # panel (+ optional wallpaper): once | always | never (replaces existing panels)

# -------------------------------------------------- upstream components ---
# Cloned into ~/.local/share/dots/src and reinstalled only when upstream changes.
: "${DOTS_KDE_GIT_BASE:=https://github.com}"
: "${DOTS_KDE_GET_ORCHIS_GTK:=1}"   # vinceliuice/Orchis-theme   -> ~/.themes
: "${DOTS_KDE_GET_ORCHIS_KDE:=1}"   # vinceliuice/Orchis-kde     -> Plasma style only
: "${DOTS_KDE_GET_TELA:=1}"         # vinceliuice/Tela-icon-theme -> ~/.local/share/icons
: "${DOTS_KDE_GET_OREO:=1}"         # varlesh/oreo-cursors (built) -> ~/.local/share/icons
: "${DOTS_KDE_GET_NETSPEED:=1}"     # dfaust/plasma-applet-netspeed-widget (kpackagetool6)
: "${DOTS_KDE_ORCHIS_GTK_ARGS:=-t default -c dark -s compact}"
: "${DOTS_KDE_TELA_VARIANT:=standard}"
: "${DOTS_KDE_OREO_COLOR:=teal}"
: "${DOTS_KDE_KLASSY_BRANCH:=auto}" # auto = newest plasmaX.Y branch not newer than the running Plasma

# -------------------------------------------------------------- appearance ---
: "${DOTS_KDE_COLOR_SCHEME:=OrchisDark-AHMZ}"
: "${DOTS_KDE_PLASMA_THEME:=Orchis-dark}"
: "${DOTS_KDE_ICON_THEME:=Tela-dark}"
: "${DOTS_KDE_CURSOR_THEME:=oreo_${DOTS_KDE_OREO_COLOR}_cursors}"
: "${DOTS_KDE_CURSOR_SIZE:=32}"
: "${DOTS_KDE_GTK_THEME:=Orchis-Dark-Compact}"
: "${DOTS_KDE_WIDGET_STYLE:=Klassy}"   # falls back to Breeze when Klassy is not installed
: "${DOTS_KDE_SPLASH:=}"               # e.g. Fedora-Minimalistic; applied only if installed
: "${DOTS_KDE_FONT_UI:=Cantarell}"
: "${DOTS_KDE_FONT_UI_SIZE:=11}"
: "${DOTS_KDE_FONT_SMALL_SIZE:=9}"
: "${DOTS_KDE_FONT_FIXED:=FiraMono Nerd Font}"
: "${DOTS_KDE_FONT_FIXED_SIZE:=11}"

# ----------------------------------------------------------------- windows ---
: "${DOTS_KDE_BORDER_SIZE:=None}"
: "${DOTS_KDE_BUTTONS_LEFT:=M}"        # M = window menu
: "${DOTS_KDE_BUTTONS_RIGHT:=IAX}"     # minimize, maximize, close
: "${DOTS_KDE_EFFECTS_ON:=wobblywindows magiclamp}"
: "${DOTS_KDE_EFFECTS_OFF:=squash}"
: "${DOTS_KDE_TASK_SWITCHER:=thumbnail_grid}"
: "${DOTS_KDE_TASK_SWITCHER_ALT:=coverswitch}"

# ------------------------------------------------------------------- input ---
: "${DOTS_KDE_KEYBOARD_LAYOUTS:=us,ir}"
: "${DOTS_KDE_TOUCHPAD_TAP:=true}"
: "${DOTS_KDE_TOUCHPAD_NATURAL_SCROLL:=true}"
: "${DOTS_KDE_TOUCHPAD_ACCEL:=0.2}"

# ----------------------------------------------------------------- konsole ---
: "${DOTS_KDE_KONSOLE_PROFILE:=ZSH}"
: "${DOTS_KDE_KONSOLE_SHELL:=}"        # empty = zsh if installed, else bash
: "${DOTS_KDE_KONSOLE_COLORS:=Linux}"
: "${DOTS_KDE_KONSOLE_FONT_SIZE:=13}"

# ----------------------------------------------------------------- session ---
: "${DOTS_KDE_LOCK_TIMEOUT:=2}"        # minutes
: "${DOTS_KDE_POWER_BUTTON:=1}"        # 1 sleep, 2 hibernate, 8 shut down, 16 lock, 32 ask
: "${DOTS_KDE_FORMATS_C:=1}"           # 24h time, metric, ISO dates (LC_TIME/MEASUREMENT/PAPER/ADDRESS=C)
: "${DOTS_KDE_SPECTACLE_KEYS:=Print	Meta+ScrollLock	Meta+Shift+S}"   # tab separated
: "${DOTS_KDE_HIDE_MENUBARS:=1}"       # Konsole and Dolphin
: "${DOTS_KDE_DOLPHIN_DEFAULT:=1}"     # folders always open in Dolphin (MIME default + FileManager1 D-Bus)

# ------------------------------------------------------- layout (panel) ---
: "${DOTS_KDE_PANEL_HEIGHT:=40}"
: "${DOTS_KDE_PANEL_FLOATING:=true}"
: "${DOTS_KDE_PANEL_LAUNCHERS:=org.kde.konsole preferred://browser code preferred://filemanager com.mattermost.Desktop org.mozilla.firefox}"
: "${DOTS_KDE_LAUNCHER_ICON:=}"        # e.g. fedora-logo-icon; empty keeps the Plasma default
: "${DOTS_KDE_CLOCK_FIRST_DAY:=6}"     # 0 Sunday ... 6 Saturday
: "${DOTS_KDE_WALLPAPER_DIRS:=}"          # optional, one slideshow folder per screen, ":" separated
: "${DOTS_KDE_LOCK_WALLPAPER_DIR:=}"       # optional slideshow folder for the lock screen
: "${DOTS_KDE_WALLPAPER_INTERVAL:=86400}"
