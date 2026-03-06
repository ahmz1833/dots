#!/bin/bash

set -eo pipefail

HOME_DIR="$HOME"
HAS_CHANGED=0

echo "[..] Setting up Vim configuration..."

mkdir -p "${HOME_DIR}/.vim"

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
            HAS_CHANGED=1
        fi
    else
        ln -sf "$target" "$link_name"
        echo "[OK] Symlinked $link_name"
        HAS_CHANGED=1
    fi
}

link_vim_asset "${HOME_DIR}/dots/vim/.vimrc" "${HOME_DIR}/.vimrc"
link_vim_asset "${HOME_DIR}/dots/vim/colors" "${HOME_DIR}/.vim/colors"

if [ "$HAS_CHANGED" -eq 1 ]; then
    echo "[OK] Vim configuration setup complete. (Changes were made)"
    exit 0
else
    echo "[OK] Vim configuration setup complete. (No changes required)"
    exit 10
fi
