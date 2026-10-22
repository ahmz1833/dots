# shellcheck shell=bash
# Helpers for dots/kde. Sourced by install.sh.

show_progress() { echo -e "\033[1;34m[..]\033[0m $1"; }
show_message()  { echo -e "\033[1;37m[>>]\033[0m $1"; }
show_success()  { echo -e "\033[1;32m[OK]\033[0m $1"; }
show_warning()  { echo -e "\033[1;33m[!!]\033[0m $1"; }
show_error()    { echo -e "\033[1;31m[XX]\033[0m $1"; }

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dots/kde"
SRC_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/dots/src"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
LOG_DIR="$STATE_DIR/logs"
mkdir -p "$STATE_DIR/stamps" "$LOG_DIR" "$SRC_ROOT"

HAS_CHANGED=0
mark_changed() { HAS_CHANGED=1; }

enabled() { [ "${1:-0}" != "0" ] && [ "${1:-}" != "skip" ] && [ "${1:-}" != "never" ]; }

# ------------------------------------------------------------- detection ---

plasma_version() { plasmashell --version 2>/dev/null | awk '{print $2}'; }

is_plasma6() {
    command -v plasmashell >/dev/null 2>&1 || return 1
    [ "$(plasma_version | cut -d. -f1)" = "6" ]
}

# True when a Plasma session is running on this user's session bus.
plasma_running() {
    [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || return 1
    dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus.NameHasOwner string:org.kde.plasmashell 2>/dev/null | grep -q 'boolean true'
}

pkg_manager() {
    if command -v dnf >/dev/null 2>&1; then echo dnf
    elif command -v apt-get >/dev/null 2>&1; then echo apt
    elif command -v pacman >/dev/null 2>&1; then echo pacman
    else echo unknown
    fi
}

find_libexec() {
    local name="$1" p
    for p in /usr/libexec /usr/lib/libexec /usr/lib/*/libexec /usr/lib /usr/lib64/libexec; do
        [ -x "$p/$name" ] && { echo "$p/$name"; return 0; }
    done
    return 1
}

klassy_installed() {
    command -v klassy-settings >/dev/null 2>&1 && return 0
    compgen -G '/usr/lib*/qt6/plugins/org.kde.kdecoration3/org.kde.klassy.so' >/dev/null && return 0
    compgen -G '/usr/lib/*/qt6/plugins/org.kde.kdecoration3/org.kde.klassy.so' >/dev/null
}

# Looks for an icon/cursor theme in every place System Settings looks.
icon_theme_exists() {
    local d
    for d in "$DATA_HOME/icons" "$HOME/.icons" /usr/local/share/icons /usr/share/icons; do
        [ -f "$d/$1/index.theme" ] && return 0
    done
    return 1
}

gtk_theme_exists() {
    local d
    for d in "$HOME/.themes" "$DATA_HOME/themes" /usr/local/share/themes /usr/share/themes; do
        [ -d "$d/$1/gtk-3.0" ] && return 0
    done
    return 1
}

plasma_theme_exists() {
    [ -d "$DATA_HOME/plasma/desktoptheme/$1" ] || [ -d "/usr/share/plasma/desktoptheme/$1" ]
}

color_scheme_exists() {
    [ -f "$DATA_HOME/color-schemes/$1.colors" ] || [ -f "/usr/share/color-schemes/$1.colors" ]
}

# --------------------------------------------------------- dependencies ---

# Which rows of deps.list apply with the current configuration.
deps_features() {
    echo core
    enabled "$DOTS_KDE_FONTS" && echo fonts
    enabled "$DOTS_KDE_APPEARANCE" && echo appearance
    if enabled "$DOTS_KDE_THEMES"; then
        want_orchis_gtk && echo orchis-gtk
        want_oreo && echo oreo
        want_netspeed && echo netspeed
    fi
    klassy_will_build && echo klassy
    return 0
}

want_orchis_gtk() { enabled "$DOTS_KDE_GET_ORCHIS_GTK" && [[ "$DOTS_KDE_GTK_THEME" == Orchis* ]]; }
want_orchis_kde() { enabled "$DOTS_KDE_GET_ORCHIS_KDE" && [[ "$DOTS_KDE_PLASMA_THEME" == Orchis* ]]; }
want_tela()       { enabled "$DOTS_KDE_GET_TELA" && [[ "$DOTS_KDE_ICON_THEME" == Tela* ]]; }
want_oreo()       { enabled "$DOTS_KDE_GET_OREO" && [[ "$DOTS_KDE_CURSOR_THEME" == oreo_* ]]; }
want_netspeed()   { enabled "$DOTS_KDE_GET_NETSPEED"; }

klassy_will_build() {
    [ "${SKIP_SUDO:-0}" -eq 1 ] && return 1
    case "$DOTS_KDE_KLASSY" in
        build) return 0 ;;
        auto)  ! klassy_installed || [ -f "$STATE_DIR/stamps/klassy" ] ;;
        *)     return 1 ;;
    esac
}

CMAKE_INDEX=""
cmake_package_exists() {
    if [ -z "$CMAKE_INDEX" ]; then
        CMAKE_INDEX=$(find /usr/lib /usr/lib64 /usr/share /usr/local/lib /usr/local/share -maxdepth 5 \
            \( -name '*Config.cmake' -o -name '*-config.cmake' \) 2>/dev/null | sed 's#.*/##' | sort -u)
    fi
    local lower; lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    grep -qxF -e "$1Config.cmake" -e "$lower-config.cmake" <<<"$CMAKE_INDEX"
}

dep_present() {
    local check="$1" kind="${1%%:*}" name="${1#*:}"
    case "$kind" in
        cmd)     command -v "$name" >/dev/null 2>&1 ;;
        libexec) find_libexec "$name" >/dev/null ;;
        font)    fc-list "${name//_/ }" family 2>/dev/null | grep -q . ;;
        cmake)   cmake_package_exists "$name" ;;
        *)       show_error "Unknown check '$check' in deps.list"; return 1 ;;
    esac
}

# Prints "<check> <package>" for every applicable row (all rows when $1 = all).
deps_rows() {
    local pm col features feature check dnf apt pacman
    pm=$(pkg_manager)
    features=$(deps_features)
    while read -r feature check dnf apt pacman; do
        [ -z "$feature" ] || [[ "$feature" == \#* ]] && continue
        [ "${1:-}" = all ] || grep -qxF "$feature" <<<"$features" || continue
        case "$pm" in
            dnf) col="$dnf" ;; apt) col="$apt" ;; pacman) col="$pacman" ;; *) col="${check#*:}" ;;
        esac
        echo "$feature $check $col"
    done < "$KDE_DIR/deps.list"
}

install_command() {
    local pkgs; pkgs=$(printf '%s\n' "$@" | sort -u | sed "s/.*(.*)/'&'/" | tr '\n' ' ')
    case "$(pkg_manager)" in
        dnf)    echo "sudo dnf install $pkgs" ;;
        apt)    echo "sudo apt install $pkgs" ;;
        pacman) echo "sudo pacman -S --needed $pkgs" ;;
        *)      echo "Install with your package manager (names are binaries/libraries): $pkgs" ;;
    esac
}

# Fail-first: report everything missing at once, then stop.
deps_check() {
    local feature check pkg missing=() lines=()
    while read -r feature check pkg; do
        [ -z "$check" ] && continue
        if ! dep_present "$check"; then
            missing+=("$pkg")
            lines+=("  [$feature] ${check#*:}  ->  $pkg")
        fi
    done < <(deps_rows)
    [ "${#missing[@]}" -eq 0 ] && return 0
    show_error "Missing dependencies for dots/kde:"
    printf '%s\n' "${lines[@]}"
    echo
    show_message "Install them with:"
    echo "  $(install_command "${missing[@]}")"
    show_message "Or turn the related section off in ~/.config/dots/kde.conf (see kde/config.sh)."
    return 1
}

deps_print() {
    local feature check pkg pkgs=() status
    show_message "dots/kde dependencies for this configuration ($(pkg_manager)):"
    while read -r feature check pkg; do
        if dep_present "$check" 2>/dev/null; then status="ok"; else status="MISSING"; fi
        printf '  %-11s %-30s %-32s %s\n' "$feature" "${check#*:}" "$pkg" "$status"
        pkgs+=("$pkg")
    done < <(deps_rows)
    echo
    show_message "All at once:"
    echo "  $(install_command "${pkgs[@]}")"
}

# ------------------------------------------------------------- KConfig ---

# Fills KGROUP_ARGS with --group flags for a "A][B" group path.
group_args() {
    local g
    KGROUP_ARGS=()
    while IFS= read -r g; do KGROUP_ARGS+=(--group "$g"); done < <(sed 's/\]\[/\n/g' <<<"$1")
}

kget() {
    group_args "$2"
    kreadconfig6 --file "$1" "${KGROUP_ARGS[@]}" --key "$3" 2>/dev/null || true
}

# kset <file> <group path, "A][B" for nested> <key> <value>
# Writes through kwriteconfig6 --notify, so open apps and System Settings see it.
kset() {
    local file="$1" groups="$2" key="$3" value="$4"
    [ "$(kget "$file" "$groups" "$key")" = "$value" ] && return 0
    group_args "$groups"
    kwriteconfig6 --notify --file "$file" "${KGROUP_ARGS[@]}" --key "$key" "$value"
    mark_changed
}

qfont() { echo "$1,$2,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; }

kwin_reconfigure() {
    plasma_running || return 0
    dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
}

# --------------------------------------------------------- files & repos ---

file_hash() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }

# Copies a file that the user may later edit through KDE's UI.
# Updated only while it still matches what dots installed last time.
managed_copy() {
    local src="$1" dest="$2" stamp
    stamp="$STATE_DIR/stamps/file$(echo "$dest" | tr '/' '_')"
    mkdir -p "$(dirname "$dest")"
    if [ ! -e "$dest" ]; then
        cp "$src" "$dest"; file_hash "$dest" > "$stamp"; mark_changed
        show_success "Installed $dest"
    elif cmp -s "$src" "$dest"; then
        file_hash "$dest" > "$stamp"
    elif [ -f "$stamp" ] && [ "$(file_hash "$dest")" = "$(cat "$stamp")" ]; then
        cp "$src" "$dest"; file_hash "$dest" > "$stamp"; mark_changed
        show_success "Updated $dest"
    else
        show_warning "$dest was changed outside dots; keeping it (delete it to get the dots version)."
    fi
}

# Makes <dest> an exact copy of <src> (dest is owned by dots).
sync_dir() {
    local src="$1" dest="$2" f name
    mkdir -p "$dest"
    for f in "$src"/*; do
        name=$(basename "$f")
        cmp -s "$f" "$dest/$name" || { cp "$f" "$dest/$name"; mark_changed; SYNC_DIR_CHANGED=1; }
    done
    for f in "$dest"/*; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        [ -e "$src/$name" ] || { rm -f "$f"; mark_changed; SYNC_DIR_CHANGED=1; }
    done
}

# repo_sync <name> <owner/repo> [branch] -> prints the checked-out commit.
# Shallow clone on first use, then fetch + hard reset so upstream updates arrive.
repo_sync() {
    local branch="${3:-}" dir="$SRC_ROOT/$1" url="$DOTS_KDE_GIT_BASE/$2"
    if [ ! -d "$dir/.git" ]; then
        rm -rf "$dir"
        git clone -q --depth=1 ${branch:+-b "$branch"} "$url" "$dir" >&2
    else
        git -C "$dir" fetch -q --depth=1 origin "${branch:-HEAD}" >&2
        git -C "$dir" reset -q --hard FETCH_HEAD >&2
        git -C "$dir" clean -qfdx >&2
    fi
    git -C "$dir" rev-parse HEAD
}

# needs_install <name> <key>: true when <key> differs from the last install.
needs_install() { [ "$(cat "$STATE_DIR/stamps/$1" 2>/dev/null)" != "$2" ]; }
record_install() { echo "$2" > "$STATE_DIR/stamps/$1"; mark_changed; }

# run_logged <name> <command...>: quiet unless it fails.
run_logged() {
    local name="$1"; shift
    if ! "$@" > "$LOG_DIR/$name.log" 2>&1; then
        show_error "$name failed. Last lines of $LOG_DIR/$name.log:"
        tail -n 20 "$LOG_DIR/$name.log"
        return 1
    fi
}
