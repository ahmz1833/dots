#!/usr/bin/env bash
# dots/kde: fonts, themes and Plasma 6 settings. Does nothing on systems without Plasma 6.
#
#   kde/install.sh            apply (exit 0 = changed, 10 = nothing to do)
#   kde/install.sh --deps     list the packages this configuration needs, then exit
#   kde/install.sh --no-sudo  skip everything that needs root (Klassy)
#
# Configure in ~/.config/dots/kde.conf; defaults and docs are in kde/config.sh.

set -eo pipefail

KDE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dots/kde.conf"
SKIP_SUDO=0
MODE=apply

for arg in "$@"; do
    case "$arg" in
        --no-sudo) SKIP_SUDO=1 ;;
        --deps)    MODE=deps ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done

# Config precedence: environment > ~/.config/dots/kde.conf > kde/config.sh.
_dots_env_vars=$(compgen -v DOTS_KDE_ || true)
_dots_env=""
# shellcheck disable=SC2086 # one name per word
[ -n "$_dots_env_vars" ] && _dots_env=$(declare -p $_dots_env_vars | sed -E 's/^declare -[-a-zA-Z]* /declare -g /')
# shellcheck disable=SC1090
[ -f "$LOCAL_CONF" ] && . "$LOCAL_CONF"
[ -n "$_dots_env" ] && eval "$_dots_env"
# shellcheck source=kde/config.sh
. "$KDE_DIR/config.sh"
# shellcheck source=kde/lib.sh
. "$KDE_DIR/lib.sh"

if [ "$MODE" = deps ]; then
    deps_print
    exit 0
fi

if ! is_plasma6; then
    show_message "KDE Plasma 6 not found; skipping KDE setup."
    exit 10
fi

show_progress "Checking KDE setup dependencies..."
deps_check || exit 1

# shellcheck source=kde/components.sh
. "$KDE_DIR/components.sh"
# shellcheck source=kde/settings.sh
. "$KDE_DIR/settings.sh"

enabled "$DOTS_KDE_FONTS"      && setup_fonts
enabled "$DOTS_KDE_THEMES"     && setup_components
enabled "$DOTS_KDE_KLASSY"     && setup_klassy
enabled "$DOTS_KDE_APPEARANCE" && apply_appearance
enabled "$DOTS_KDE_WINDOWS"    && apply_windows
enabled "$DOTS_KDE_INPUT"      && apply_input
enabled "$DOTS_KDE_KONSOLE"    && apply_konsole
enabled "$DOTS_KDE_SESSION"    && apply_session
enabled "$DOTS_KDE_LAYOUT"     && apply_layout

if [ "$HAS_CHANGED" -eq 1 ]; then
    show_success "KDE setup complete! (Changes were made)"
    exit 0
else
    show_success "KDE setup complete! (No changes required)"
    exit 10
fi
