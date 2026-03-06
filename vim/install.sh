#!/bin/bash

set -e

HOME_DIR="$HOME"

echo "[..] Setting up Vim configuration..."

mkdir -p "${HOME_DIR}/.vim"

# Helper function to link vim assets
link_vim_asset() {
    local target="$1"
    local link_name="$2"

    if [ -e "$link_name" ] || [ -L "$link_name" ]; then
        if [ "$(readlink "$link_name")" = "$target" ]; then
            echo "[>>] $link_name is already linked."
        else
            echo "[!!] Backing up existing $link_name to ${link_name}.old..."
            rm -rf "${link_name}.old"
            mv "$link_name" "${link_name}.old"
            ln -sf "$target" "$link_name"
            echo "[OK] Symlinked $link_name"
        fi
    else
        ln -sf "$target" "$link_name"
        echo "[OK] Symlinked $link_name"
    fi
}

link_vim_asset "${HOME_DIR}/dots/vim/.vimrc" "${HOME_DIR}/.vimrc"
link_vim_asset "${HOME_DIR}/dots/vim/colors" "${HOME_DIR}/.vim/colors"

echo "[OK] Vim configuration setup complete."
