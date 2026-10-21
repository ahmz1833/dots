# shellcheck shell=bash
# Plasma settings. Each value is written the way its System Settings page
# writes it: the plasma-apply-* tools, the GTK config service, or single keys
# through kwriteconfig6 --notify. Whole config files are never replaced.

setup_fonts() {
    local dest="$DATA_HOME/fonts/dots" conf="$CONFIG_HOME/fontconfig/conf.d/60-dots-fonts.conf" tmp
    SYNC_DIR_CHANGED=0
    sync_dir "$KDE_DIR/assets/fonts" "$dest"
    mkdir -p "$(dirname "$conf")"
    tmp=$(mktemp)
    sed -e "s|@FONT_UI@|$DOTS_KDE_FONT_UI|g" -e "s|@FONT_FIXED@|$DOTS_KDE_FONT_FIXED|g" \
        "$KDE_DIR/assets/fontconfig/60-dots-fonts.conf.in" > "$tmp"
    if ! cmp -s "$tmp" "$conf"; then
        mv "$tmp" "$conf"; mark_changed; SYNC_DIR_CHANGED=1
    else
        rm -f "$tmp"
    fi
    if [ "$SYNC_DIR_CHANGED" -eq 1 ]; then
        fc-cache -f "$dest" >/dev/null
        show_success "Fonts and fontconfig fallbacks updated."
    else
        show_message "Fonts already up to date."
    fi
}

# ------------------------------------------------------------- appearance ---

# The plasma-apply-* tools and the GTK service need a running session. Without
# one, each step writes the same keys those tools would, and the theme takes
# full effect at the next login.

apply_color_scheme() {
    local name="$DOTS_KDE_COLOR_SCHEME" f
    for f in "$KDE_DIR"/assets/color-schemes/*.colors; do
        managed_copy "$f" "$DATA_HOME/color-schemes/$(basename "$f")"
    done
    color_scheme_exists "$name" || { show_warning "Color scheme $name not found; skipped."; return 0; }
    [ "$(kget kdeglobals General ColorScheme)" = "$name" ] && return 0
    if plasma_running; then
        plasma-apply-colorscheme "$name" >/dev/null
        mark_changed
    else
        show_warning "Color scheme $name needs a Plasma session to apply; re-run from inside Plasma."
    fi
}

apply_plasma_theme() {
    local name="$DOTS_KDE_PLASMA_THEME"
    plasma_theme_exists "$name" || { show_warning "Plasma style $name not found; skipped."; return 0; }
    [ "$(kget plasmarc Theme name)" = "$name" ] && return 0
    if plasma_running; then
        plasma-apply-desktoptheme "$name" >/dev/null
        mark_changed
    else
        kset plasmarc Theme name "$name"
    fi
}

apply_icons() {
    local name="$DOTS_KDE_ICON_THEME"
    icon_theme_exists "$name" || { show_warning "Icon theme $name not found; skipped."; return 0; }
    [ "$(kget kdeglobals Icons Theme)" = "$name" ] && return 0
    if plasma_running; then
        "$(find_libexec plasma-changeicons)" "$name" >/dev/null
        mark_changed
    else
        kset kdeglobals Icons Theme "$name"
    fi
}

apply_cursor() {
    local name="$DOTS_KDE_CURSOR_THEME" size="$DOTS_KDE_CURSOR_SIZE"
    icon_theme_exists "$name" || { show_warning "Cursor theme $name not found; skipped."; return 0; }
    [ "$(kget kcminputrc Mouse cursorTheme)" = "$name" ] && [ "$(kget kcminputrc Mouse cursorSize)" = "$size" ] && return 0
    if plasma_running; then
        plasma-apply-cursortheme --size "$size" "$name" >/dev/null
        mark_changed
    else
        kset kcminputrc Mouse cursorTheme "$name"
        kset kcminputrc Mouse cursorSize "$size"
    fi
}

apply_gtk_theme() {
    local name="$DOTS_KDE_GTK_THEME" current
    gtk_theme_exists "$name" || { show_warning "GTK theme $name not found; skipped."; return 0; }
    current=$(dbus-send --session --print-reply=literal --dest=org.kde.GtkConfig /GtkConfig \
        org.kde.GtkConfig.gtkTheme 2>/dev/null | tr -d ' ') || true
    if [ -n "$current" ]; then
        [ "$current" = "$name" ] && return 0
        dbus-send --session --type=method_call --dest=org.kde.GtkConfig /GtkConfig \
            org.kde.GtkConfig.setGtkTheme string:"$name"
        mark_changed
    else
        # GTK config service not running: write what it would write.
        kset "$CONFIG_HOME/gtk-3.0/settings.ini" Settings gtk-theme-name "$name"
        kset "$CONFIG_HOME/gtk-4.0/settings.ini" Settings gtk-theme-name "$name"
    fi
}

apply_fonts() {
    local ui small fixed
    ui=$(qfont "$DOTS_KDE_FONT_UI" "$DOTS_KDE_FONT_UI_SIZE")
    small=$(qfont "$DOTS_KDE_FONT_UI" "$DOTS_KDE_FONT_SMALL_SIZE")
    fixed=$(qfont "$DOTS_KDE_FONT_FIXED" "$DOTS_KDE_FONT_FIXED_SIZE")
    kset kdeglobals General font "$ui"
    kset kdeglobals General menuFont "$ui"
    kset kdeglobals General toolBarFont "$ui"
    kset kdeglobals General smallestReadableFont "$small"
    kset kdeglobals General fixed "$fixed"
    kset kdeglobals WM activeFont "$ui"
    kset kdeglobals General XftAntialias true
    kset kdeglobals General XftHintStyle hintslight
    kset kdeglobals General XftSubPixel none
}

apply_appearance() {
    apply_color_scheme
    apply_plasma_theme
    apply_icons
    apply_cursor
    apply_gtk_theme
    apply_fonts
    if [ "$DOTS_KDE_WIDGET_STYLE" = Klassy ] && ! klassy_installed; then
        show_warning "Application style Klassy is not installed; keeping the current style."
    else
        kset kdeglobals KDE widgetStyle "$DOTS_KDE_WIDGET_STYLE"
    fi
    if [ -n "$DOTS_KDE_SPLASH" ]; then
        if [ -d "$DATA_HOME/plasma/look-and-feel/$DOTS_KDE_SPLASH/contents/splash" ] \
            || [ -d "/usr/share/plasma/look-and-feel/$DOTS_KDE_SPLASH/contents/splash" ]; then
            kset ksplashrc KSplash Engine KSplashQML
            kset ksplashrc KSplash Theme "$DOTS_KDE_SPLASH"
        else
            show_warning "Splash $DOTS_KDE_SPLASH is not installed (get it from System Settings > Splash Screen > Get New)."
        fi
    fi
    show_success "Appearance applied."
}

# ---------------------------------------------------------------- windows ---

# Klassy options as "Group|Key|Value" lines; override DOTS_KDE_KLASSY_SETTINGS to change them.
: "${DOTS_KDE_KLASSY_SETTINGS:=ButtonColors|ButtonBackgroundColorsActive|TitleBarTextNegativeClose
ButtonColors|ButtonBackgroundColorsInactive|TitleBarTextNegativeClose
ButtonColors|ButtonIconColorsActive|TitleBarTextNegativeClose
ButtonColors|CloseButtonIconColorActive|NegativeWhenHoverPress
ButtonColors|CloseButtonIconColorInactive|AsSelected
Windeco|ButtonIconStyle|StyleTraditional}"

apply_windows() {
    local e group key value
    if klassy_installed; then
        kset kwinrc org.kde.kdecoration2 library org.kde.klassy
        kset kwinrc org.kde.kdecoration2 theme Klassy
        while IFS='|' read -r group key value; do
            [ -n "$key" ] && kset klassy/klassyrc "$group" "$key" "$value"
        done <<<"$DOTS_KDE_KLASSY_SETTINGS"
    else
        show_warning "Klassy is not installed; keeping the current window decoration."
    fi
    kset kwinrc org.kde.kdecoration2 BorderSize "$DOTS_KDE_BORDER_SIZE"
    kset kwinrc org.kde.kdecoration2 BorderSizeAuto false
    kset kwinrc org.kde.kdecoration2 ButtonsOnLeft "$DOTS_KDE_BUTTONS_LEFT"
    kset kwinrc org.kde.kdecoration2 ButtonsOnRight "$DOTS_KDE_BUTTONS_RIGHT"
    for e in $DOTS_KDE_EFFECTS_ON; do kset kwinrc Plugins "${e}Enabled" true; done
    for e in $DOTS_KDE_EFFECTS_OFF; do kset kwinrc Plugins "${e}Enabled" false; done
    kset kwinrc TabBox LayoutName "$DOTS_KDE_TASK_SWITCHER"
    kset kwinrc TabBox HighlightWindows false
    kset kwinrc TabBoxAlternative LayoutName "$DOTS_KDE_TASK_SWITCHER_ALT"
    kwin_reconfigure
    show_success "Window settings applied."
}

# ------------------------------------------------------------------ input ---

kwin_input() { busctl --user "$1" org.kde.KWin "/org/kde/KWin/InputDevice$2" "${@:3}" 2>/dev/null; }

apply_touchpads() {
    local devices dev name vendor product group found=0
    devices=$(kwin_input get-property "" org.kde.KWin.InputDeviceManager devicesSysNames | grep -o '"[^"]*"' | tr -d '"') || true
    if [ -z "$devices" ]; then
        show_warning "KWin input devices not reachable (needs a Wayland session); touchpad skipped."
        return 0
    fi
    for dev in $devices; do
        [ "$(kwin_input get-property "/$dev" org.kde.KWin.InputDevice touchpad)" = "b true" ] || continue
        found=1
        name=$(kwin_input get-property "/$dev" org.kde.KWin.InputDevice name | sed 's/^s "//;s/"$//')
        vendor=$(kwin_input get-property "/$dev" org.kde.KWin.InputDevice vendor | awk '{print $2}')
        product=$(kwin_input get-property "/$dev" org.kde.KWin.InputDevice product | awk '{print $2}')
        group="Libinput][$vendor][$product][$name"
        # Same keys the Touchpad page saves; also set live on the device.
        kset kcminputrc "$group" TapToClick "$DOTS_KDE_TOUCHPAD_TAP"
        kset kcminputrc "$group" NaturalScroll "$DOTS_KDE_TOUCHPAD_NATURAL_SCROLL"
        kset kcminputrc "$group" PointerAcceleration "$DOTS_KDE_TOUCHPAD_ACCEL"
        kwin_input set-property "/$dev" org.kde.KWin.InputDevice tapToClick b "$DOTS_KDE_TOUCHPAD_TAP" || true
        kwin_input set-property "/$dev" org.kde.KWin.InputDevice naturalScroll b "$DOTS_KDE_TOUCHPAD_NATURAL_SCROLL" || true
        kwin_input set-property "/$dev" org.kde.KWin.InputDevice pointerAcceleration d "$DOTS_KDE_TOUCHPAD_ACCEL" || true
    done
    [ "$found" -eq 1 ] || show_message "No touchpad found."
}

apply_input() {
    kset kxkbrc Layout LayoutList "$DOTS_KDE_KEYBOARD_LAYOUTS"
    kset kxkbrc Layout Use true
    plasma_running && dbus-send --session --type=signal /Layouts org.kde.keyboard.reloadConfig 2>/dev/null || true
    apply_touchpads
    show_success "Input settings applied."
}

# ---------------------------------------------------------------- konsole ---

apply_konsole() {
    local profile="$DATA_HOME/konsole/$DOTS_KDE_KONSOLE_PROFILE.profile" shell="$DOTS_KDE_KONSOLE_SHELL" f
    for f in "$KDE_DIR"/assets/konsole/*.colorscheme; do
        managed_copy "$f" "$DATA_HOME/konsole/$(basename "$f")"
    done
    [ -n "$shell" ] || shell=$(command -v zsh || command -v bash)
    mkdir -p "$DATA_HOME/konsole"
    kset "$profile" General Name "$DOTS_KDE_KONSOLE_PROFILE"
    kset "$profile" General Command "$shell"
    kset "$profile" General Parent FALLBACK/
    kset "$profile" Appearance ColorScheme "$DOTS_KDE_KONSOLE_COLORS"
    kset "$profile" Appearance Font "$(qfont "$DOTS_KDE_FONT_FIXED" "$DOTS_KDE_KONSOLE_FONT_SIZE")"
    kset "$profile" "Cursor Options" CursorShape 1
    kset konsolerc "Desktop Entry" DefaultProfile "$DOTS_KDE_KONSOLE_PROFILE.profile"
    show_success "Konsole profile $DOTS_KDE_KONSOLE_PROFILE applied."
}

# ---------------------------------------------------------------- session ---

# Folders must always open in Dolphin. Two things can send them elsewhere when
# another desktop's file manager is installed (e.g. Nautilus on Workstation):
#  - the folder MIME default falls back to /usr/share/applications/mimeapps.list;
#  - org.freedesktop.FileManager1 (used by "Show in folder" in Chrome, Telegram, ...)
#    has two D-Bus service files, and D-Bus starts Nautilus when Dolphin isn't running.
apply_file_manager() {
    local f conflict=0 tmp
    desktop_file_exists org.kde.dolphin || { show_warning "Dolphin not installed; file manager default skipped."; return 0; }
    kset mimeapps.list "Default Applications" inode/directory org.kde.dolphin.desktop
    for f in /usr/share/dbus-1/services/*.service /usr/local/share/dbus-1/services/*.service; do
        [ -f "$f" ] || continue
        grep -qx 'Name=org.freedesktop.FileManager1' "$f" || continue
        grep -q '^Exec=.*dolphin' "$f" || conflict=1
    done
    [ "$conflict" -eq 1 ] || return 0
    # A user service file takes precedence over the system ones.
    tmp=$(mktemp)
    printf '[D-BUS Service]\nName=org.freedesktop.FileManager1\nExec=%s --daemon\n' "$(command -v dolphin)" > "$tmp"
    managed_copy "$tmp" "$DATA_HOME/dbus-1/services/org.freedesktop.FileManager1.service"
    rm -f "$tmp"
}


apply_session() {
    local g
    kset kscreenlockerrc Daemon Timeout "$DOTS_KDE_LOCK_TIMEOUT"
    if [ -n "$DOTS_KDE_LOCK_WALLPAPER_DIR" ] && [ -d "$DOTS_KDE_LOCK_WALLPAPER_DIR" ]; then
        kset kscreenlockerrc Greeter WallpaperPlugin org.kde.slideshow
        kset kscreenlockerrc "Greeter][Wallpaper][org.kde.slideshow][General" SlidePaths "${DOTS_KDE_LOCK_WALLPAPER_DIR%/}/"
        kset kscreenlockerrc "Greeter][Wallpaper][org.kde.slideshow][General" SlideInterval "$DOTS_KDE_WALLPAPER_INTERVAL"
    fi
    for g in AC Battery LowBattery; do
        kset powerdevilrc "$g][SuspendAndShutdown" PowerButtonAction "$DOTS_KDE_POWER_BUTTON"
    done
    if enabled "$DOTS_KDE_FORMATS_C"; then
        for g in LC_TIME LC_MEASUREMENT LC_PAPER LC_ADDRESS; do
            kset plasma-localerc Formats "$g" C
        done
    fi
    [ -n "$DOTS_KDE_SPECTACLE_KEYS" ] && \
        kset kglobalshortcutsrc "services][org.kde.spectacle.desktop" _launch "$DOTS_KDE_SPECTACLE_KEYS"
    enabled "$DOTS_KDE_DOLPHIN_DEFAULT" && apply_file_manager
    if enabled "$DOTS_KDE_HIDE_MENUBARS"; then
        kset konsolerc MainWindow MenuBar Disabled
        kset dolphinrc MainWindow MenuBar Disabled
    fi
    show_success "Session settings applied (shortcuts and formats take effect after the next login)."
}

# ----------------------------------------------------------------- layout ---

desktop_file_exists() {
    local d
    for d in "$DATA_HOME/applications" /usr/local/share/applications /usr/share/applications \
             "$DATA_HOME/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications; do
        [ -f "$d/$1.desktop" ] && return 0
    done
    return 1
}

json_list() {
    local first=1 item
    printf '['
    for item in "$@"; do
        [ "$first" -eq 1 ] || printf ','
        printf '"%s"' "$(sed 's/["\\]/\\&/g' <<<"$item")"
        first=0
    done
    printf ']'
}

apply_layout() {
    local marker="$STATE_DIR/stamps/layout" launchers=() walls=() item alt dir config script reply
    if [ "$DOTS_KDE_LAYOUT" = once ] && [ -f "$marker" ]; then
        return 0
    fi
    plasma_running || { show_warning "No running Plasma session; panel layout skipped."; return 0; }
    # Each entry is "preferred://x", a desktop-file id, or "id1|id2" (first one installed wins).
    for item in $DOTS_KDE_PANEL_LAUNCHERS; do
        case "$item" in
            preferred://*) launchers+=("$item") ;;
            *)
                IFS='|' read -r -a alts <<<"$item"
                for alt in "${alts[@]}"; do
                    desktop_file_exists "$alt" && { launchers+=("applications:$alt.desktop"); break; }
                done
                ;;
        esac
    done
    IFS=':' read -r -a dirs <<<"$DOTS_KDE_WALLPAPER_DIRS"
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] && walls+=("${dir%/}/")
    done
    config=$(printf '{"height":%s,"floating":%s,"launcherIcon":"%s","launchers":%s,"firstDay":%s,"wallpapers":%s,"interval":%s}' \
        "$DOTS_KDE_PANEL_HEIGHT" "$DOTS_KDE_PANEL_FLOATING" "$DOTS_KDE_LAUNCHER_ICON" \
        "$(json_list "${launchers[@]}")" "$DOTS_KDE_CLOCK_FIRST_DAY" "$(json_list "${walls[@]}")" "$DOTS_KDE_WALLPAPER_INTERVAL")
    script=$(sed "s|@CONFIG@|$(sed 's/[&|\\]/\\&/g' <<<"$config")|" "$KDE_DIR/panel.js")
    show_progress "Applying panel layout..."
    if ! reply=$(dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell \
            org.kde.PlasmaShell.evaluateScript string:"$script" 2>&1); then
        show_error "Plasma rejected the layout script: $reply"
        return 1
    fi
    date -Iseconds > "$marker"
    mark_changed
    show_success "Panel layout applied."
}
