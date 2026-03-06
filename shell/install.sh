#!/usr/bin/env zsh

set -e
export PATH="$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${HOME}/.local/bin"
HOME_DIR="$HOME"
SKIP_SUDO=0
HAS_CHANGED=0

for arg in "$@"; do
    if [ "$arg" = "--no-sudo" ]; then
        SKIP_SUDO=1
    fi
done

show_progress() { echo -e "\033[1;34m[..]\033[0m $1"; }
show_message()  { echo -e "\033[1;37m[>>]\033[0m $1"; }
show_success()  { echo -e "\033[1;32m[OK]\033[0m $1"; }
show_warning()  { echo -e "\033[1;33m[!!]\033[0m $1"; }
show_error()    { echo -e "\033[1;31m[XX]\033[0m $1"; }

install_base_packages() {
    local -a pkgs=(zsh curl git ripgrep)
    local needs_install=0
    
    for cmd in zsh curl git rg; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            needs_install=1
            break
        fi
    done
    
    if [ "$needs_install" -eq 1 ]; then
        show_progress "Installing base packages..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y "${pkgs[@]}"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "${pkgs[@]}"
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm "${pkgs[@]}"
        elif command -v brew >/dev/null 2>&1; then
            brew install "${pkgs[@]}"
        else
            show_warning "Package manager not supported."
        fi
        HAS_CHANGED=1
    else
        show_success "Base packages already installed."
    fi
}

check_fzf_version() {
    local fzf_ver major minor
    fzf_ver=$(fzf --version | awk '{print $1}')
    major=$(echo "$fzf_ver" | cut -d. -f1)
    minor=$(echo "$fzf_ver" | cut -d. -f2)
    
    if [[ "$major" -gt 0 ]] || [[ "$major" -eq 0 && "$minor" -ge 48 ]]; then
        return 0
    fi
    return 1
}

install_fzf() {
    show_progress "Installing fzf..."
    if [ ! -d "${HOME_DIR}/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME_DIR}/.fzf"
        HAS_CHANGED=1
    else
        local pull_output
        pull_output=$(git -C "${HOME_DIR}/.fzf" pull 2>&1)
        if [[ "$pull_output" != *"Already up to date."* ]]; then
            HAS_CHANGED=1
        fi
    fi
    "${HOME_DIR}/.fzf/install" --bin --no-update-rc --no-bash --no-zsh --no-fish
    
    mkdir -p "${HOME_DIR}/.local/bin"
    ln -sf "${HOME_DIR}/.fzf/bin/fzf" "${HOME_DIR}/.local/bin/fzf"
    show_success "fzf installed."
}

install_zoxide() {
    show_progress "Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    HAS_CHANGED=1
    show_success "zoxide installed."
}

install_eza() {
    show_progress "Installing eza..."
    local temp_dir arch eza_url
    temp_dir=$(mktemp -d)
    arch=$(uname -m)
    
    if [ "$arch" = "x86_64" ]; then
        eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    elif [ "$arch" = "aarch64" ]; then
        eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
    else
        show_error "Unsupported architecture."
        return 1
    fi
    
    curl -fsSL "$eza_url" | tar -xz -C "$temp_dir"
    mkdir -p "${HOME_DIR}/.local/bin"
    mv "${temp_dir}/eza" "${HOME_DIR}/.local/bin/eza"
    rm -rf "$temp_dir"
    HAS_CHANGED=1
    show_success "eza installed."
}

link_file() {
    local target="$1"
    local link_name="$2"
    
    if [ -e "$link_name" ] || [ -L "$link_name" ]; then
        if [ "$(readlink "$link_name")" = "$target" ]; then
            show_message "$link_name already linked."
        else
            show_warning "Backing up $link_name..."
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

if [ "$SKIP_SUDO" -eq 1 ]; then
    show_warning "Skipping base packages installation (--no-sudo)."
else
    install_base_packages
fi

if ! command -v fzf >/dev/null 2>&1; then
    install_fzf
elif ! check_fzf_version; then
    show_warning "fzf outdated. Reinstalling..."
    install_fzf
else
    show_success "fzf up to date."
fi

if ! command -v zoxide >/dev/null 2>&1; then
    install_zoxide
else
    show_success "zoxide already installed."
fi

if ! command -v eza >/dev/null 2>&1; then
    install_eza
else
    show_success "eza already installed."
fi

if [ ! -d "${HOME_DIR}/.oh-my-zsh" ]; then
    show_progress "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    HAS_CHANGED=1
    show_success "oh-my-zsh installed."
else
    show_success "oh-my-zsh already installed."
fi

if ! command -v starship >/dev/null 2>&1; then
    show_progress "Installing starship..."
    if [ "$SKIP_SUDO" -eq 1 ]; then
        mkdir -p "${HOME_DIR}/.local/bin"
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "${HOME_DIR}/.local/bin"
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    HAS_CHANGED=1
    show_success "starship installed."
else
    show_success "starship already installed."
fi

show_progress "Setting up symlinks..."
link_file "${HOME_DIR}/dots/shell/.zshrc" "${HOME_DIR}/.zshrc"

mkdir -p "${HOME_DIR}/.config"
link_file "${HOME_DIR}/dots/shell/starship.toml" "${HOME_DIR}/.config/starship.toml"

if [ "$SKIP_SUDO" -eq 1 ]; then
    show_warning "Skipping default shell change (--no-sudo)."
else
    ZSH_PATH=$(command -v zsh || true)
    if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
        show_progress "Changing default shell..."
        if command -v sudo >/dev/null 2>&1; then
            sudo chsh -s "$ZSH_PATH" "$USER"
        else
            chsh -s "$ZSH_PATH"
        fi
        HAS_CHANGED=1
        show_success "Shell changed."
    else
        show_success "Shell already set to zsh."
    fi
fi

if [ "$HAS_CHANGED" -eq 1 ]; then
    show_success "Shell setup complete! (Changes were made)"
    exit 0
else
    show_success "Shell setup complete! (No changes required)"
    exit 10
fi
