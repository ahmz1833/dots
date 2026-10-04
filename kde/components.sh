# shellcheck shell=bash
# Upstream themes and widgets. Each one is cloned into $SRC_ROOT, reinstalled
# only when upstream (or the chosen variant) changes, and installed into the
# user folders that System Settings lists, so it can be picked or removed there.

setup_orchis_gtk() {
    local rev key
    rev=$(repo_sync orchis-gtk vinceliuice/Orchis-theme)
    key="$rev $DOTS_KDE_ORCHIS_GTK_ARGS"
    needs_install orchis-gtk "$key" || gtk_theme_exists "$DOTS_KDE_GTK_THEME" || rm -f "$STATE_DIR/stamps/orchis-gtk"
    needs_install orchis-gtk "$key" || return 0
    show_progress "Installing Orchis GTK theme..."
    # shellcheck disable=SC2086 # args are a word list on purpose
    run_logged orchis-gtk bash "$SRC_ROOT/orchis-gtk/install.sh" -d "$HOME/.themes" $DOTS_KDE_ORCHIS_GTK_ARGS
    record_install orchis-gtk "$key"
    show_success "Orchis GTK theme installed (${rev:0:7})."
}

# Only the Plasma style is taken from Orchis-kde (no Kvantum, wallpapers or global theme).
setup_orchis_kde() {
    local rev name="$DOTS_KDE_PLASMA_THEME" base colors src dest
    rev=$(repo_sync orchis-kde vinceliuice/Orchis-kde)
    dest="$DATA_HOME/plasma/desktoptheme/$name"
    needs_install "orchis-kde-$name" "$rev" || [ -d "$dest" ] || rm -f "$STATE_DIR/stamps/orchis-kde-$name"
    needs_install "orchis-kde-$name" "$rev" || return 0
    src="$SRC_ROOT/orchis-kde"
    base="${name%-dark}"
    colors="$src/color-schemes/${base}$([ "$base" != "$name" ] && echo Dark).colors"
    if [ ! -d "$src/plasma/desktoptheme/$name" ] || [ ! -f "$colors" ]; then
        show_error "Orchis-kde has no Plasma style named '$name'."
        return 1
    fi
    show_progress "Installing Plasma style $name..."
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -r "$src/plasma/desktoptheme/$name" "$dest"
    cp -r "$src/plasma/desktoptheme/icons" "$dest/icons"
    cp "$colors" "$dest/colors"
    record_install "orchis-kde-$name" "$rev"
    show_success "Plasma style $name installed (${rev:0:7})."
}

setup_tela() {
    local rev key
    rev=$(repo_sync tela vinceliuice/Tela-icon-theme)
    key="$rev $DOTS_KDE_TELA_VARIANT"
    needs_install tela "$key" || icon_theme_exists "$DOTS_KDE_ICON_THEME" || rm -f "$STATE_DIR/stamps/tela"
    needs_install tela "$key" || return 0
    show_progress "Installing Tela icons ($DOTS_KDE_TELA_VARIANT)..."
    run_logged tela bash "$SRC_ROOT/tela/install.sh" -d "$DATA_HOME/icons" "$DOTS_KDE_TELA_VARIANT"
    record_install tela "$key"
    show_success "Tela icons installed (${rev:0:7})."
}

# Oreo ships sources only; build just the chosen color.
setup_oreo() {
    local rev key theme="oreo_${DOTS_KDE_OREO_COLOR}_cursors" dir="$SRC_ROOT/oreo"
    rev=$(repo_sync oreo varlesh/oreo-cursors)
    key="$rev $DOTS_KDE_OREO_COLOR"
    needs_install oreo "$key" || [ -d "$DATA_HOME/icons/$theme" ] || rm -f "$STATE_DIR/stamps/oreo"
    needs_install oreo "$key" || return 0
    show_progress "Building $theme (a few minutes)..."
    run_logged oreo-generate bash -c "cd '$dir' && ruby generator/convert.rb"
    if [ ! -d "$dir/src/$theme" ]; then
        show_error "Oreo has no '$DOTS_KDE_OREO_COLOR' color (see generator/colours.conf)."
        return 1
    fi
    find "$dir/src" -mindepth 1 -maxdepth 1 -type d -name 'oreo_*' ! -name "$theme" -exec rm -rf {} +
    run_logged oreo-build bash -c "cd '$dir' && bash build.sh"
    rm -rf "$DATA_HOME/icons/$theme"
    mkdir -p "$DATA_HOME/icons"
    cp -r "$dir/dist/$theme" "$DATA_HOME/icons/$theme"
    record_install oreo "$key"
    show_success "Cursor theme $theme installed (${rev:0:7})."
}

setup_netspeed() {
    local rev pkg
    rev=$(repo_sync netspeed dfaust/plasma-applet-netspeed-widget)
    pkg="$SRC_ROOT/netspeed/package"
    needs_install netspeed "$rev" || [ -d "$DATA_HOME/plasma/plasmoids/org.kde.netspeedWidget" ] \
        || rm -f "$STATE_DIR/stamps/netspeed"
    needs_install netspeed "$rev" || return 0
    show_progress "Installing Netspeed widget..."
    if [ -d "$DATA_HOME/plasma/plasmoids/org.kde.netspeedWidget" ]; then
        run_logged netspeed kpackagetool6 --type Plasma/Applet --upgrade "$pkg"
    else
        run_logged netspeed kpackagetool6 --type Plasma/Applet --install "$pkg"
    fi
    record_install netspeed "$rev"
    show_success "Netspeed widget installed (${rev:0:7})."
}

# ---------------------------------------------------------------- Klassy ---

klassy_branch() {
    if [ "$DOTS_KDE_KLASSY_BRANCH" != auto ]; then
        echo "$DOTS_KDE_KLASSY_BRANCH"; return
    fi
    local running branches best=""
    running=$(plasma_version | cut -d. -f1-2)
    branches=$(git ls-remote --heads "$DOTS_KDE_GIT_BASE/paulmcauley/klassy" 'plasma*' \
        | sed -n 's#.*refs/heads/plasma\([0-9.]*\)$#\1#p' | sort -V)
    while read -r b; do
        [ -z "$b" ] && continue
        [ "$(printf '%s\n%s\n' "$b" "$running" | sort -V | head -1)" = "$b" ] && best="$b"
    done <<<"$branches"
    [ -z "$best" ] && best=$(tail -n1 <<<"$branches")
    echo "plasma$best"
}

# Klassy installs into /usr (KWin only loads decorations from system paths), so it needs sudo.
setup_klassy() {
    if ! klassy_will_build; then
        if [ "${SKIP_SUDO:-0}" -eq 1 ] && ! klassy_installed; then
            show_warning "Klassy is not installed and --no-sudo was given; skipping it."
        elif klassy_installed && [ ! -f "$STATE_DIR/stamps/klassy" ] && [ "$DOTS_KDE_KLASSY" = auto ]; then
            show_message "Klassy is installed outside dots; leaving it alone (DOTS_KDE_KLASSY=build to manage it)."
        fi
        return 0
    fi
    local branch rev key dir="$SRC_ROOT/klassy" manifest="$STATE_DIR/klassy-install-manifest.txt"
    branch=$(klassy_branch)
    rev=$(repo_sync klassy paulmcauley/klassy "$branch")
    key="$branch $rev"
    needs_install klassy "$key" || klassy_installed || rm -f "$STATE_DIR/stamps/klassy"
    needs_install klassy "$key" || return 0
    show_progress "Building Klassy ($branch)..."
    run_logged klassy-configure cmake -S "$dir" -B "$dir/build" -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DKDE_INSTALL_USE_QT_SYS_PATHS=ON -DBUILD_QT5=OFF
    run_logged klassy-build cmake --build "$dir/build" -j"$(nproc)"
    show_progress "Installing Klassy into /usr (sudo)..."
    if [ -f "$manifest" ]; then
        # Remove files of the previous dots-built version that the new one no longer ships.
        xargs -d '\n' sudo rm -f < "$manifest" || true
    fi
    run_logged klassy-install sudo cmake --install "$dir/build"
    cp "$dir/build/install_manifest.txt" "$manifest"
    record_install klassy "$key"
    show_success "Klassy installed ($branch, ${rev:0:7}). Log out and in if KWin doesn't pick it up."
}

setup_components() {
    want_orchis_gtk && setup_orchis_gtk
    want_orchis_kde && setup_orchis_kde
    want_tela && setup_tela
    want_oreo && setup_oreo
    want_netspeed && setup_netspeed
    return 0
}
