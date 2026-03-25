#!/usr/bin/env bash

set -eo pipefail

HOME_DIR="$HOME"
HAS_CHANGED=0

show_progress() { echo -e "\033[1;34m[..]\033[0m $1"; }
show_message()  { echo -e "\033[1;37m[>>]\033[0m $1"; }
show_success()  { echo -e "\033[1;32m[OK]\033[0m $1"; }
show_warning()  { echo -e "\033[1;33m[!!]\033[0m $1"; }
show_error()    { echo -e "\033[1;31m[XX]\033[0m $1"; }

copy_if_not_exists() {
    local source="$1"
    local dest="$2"
    
    if [ -e "$dest" ]; then
        show_message "$dest already exists."
    else
        cp "$source" "$dest"
        HAS_CHANGED=1
        show_success "Copied $source to $dest."
    fi
}

link_tmux_asset() {
    local target="$1"
    local link_name="$2"
    
    if [ -e "$link_name" ] || [ -L "$link_name" ]; then
        if [ "$(readlink "$link_name")" = "$target" ]; then
            show_message "$link_name already linked."
        else
            show_warning "Backing up existing $link_name..."
            mv "$link_name" "${link_name}.old"
            ln -sf "$target" "$link_name"
            HAS_CHANGED=1
            show_success "Symlinked $link_name."
        fi
    else
        ln -sf "$target" "$link_name"
        HAS_CHANGED=1
        show_success "Symlinked $link_name."
    fi
}

show_progress "Setting up tmux configuration..."

mkdir -p "${HOME_DIR}/.tmux"

link_tmux_asset "${HOME_DIR}/dots/tmux/.tmux.conf" "${HOME_DIR}/.tmux.conf"
link_tmux_asset "${HOME_DIR}/dots/tmux/themes" "${HOME_DIR}/.tmux/themes"
copy_if_not_exists "${HOME_DIR}/dots/tmux/.tmux.local.conf" "${HOME_DIR}/.tmux.local.conf"

if [ "$HAS_CHANGED" -eq 1 ]; then
    show_success "Tmux configuration setup complete! (Changes were made)"
    exit 0
else
    show_success "Tmux configuration setup complete! (No changes required)"
    exit 10
fi
