#!/bin/bash

set -e

HOME_DIR="$HOME"

show_progress() { echo -e "\033[1;34m[..]\033[0m $1"; }
show_message()  { echo -e "\033[1;37m[>>]\033[0m $1"; }
show_success()  { echo -e "\033[1;32m[OK]\033[0m $1"; }
show_warning()  { echo -e "\033[1;33m[!!]\033[0m $1"; }
show_error()    { echo -e "\033[1;31m[XX]\033[0m $1"; }

install_base_packages() {
    show_progress "Installing base packages..."
    local pkgs="zsh curl git ripgrep"
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y $pkgs
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y $pkgs
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm $pkgs
    elif command -v brew >/dev/null 2>&1; then
        brew install $pkgs
    else
        show_warning "Package manager not supported. Ensure $pkgs are installed manually."
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
    show_progress "Installing fzf from git..."
    if [ ! -d "$HOME_DIR/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME_DIR/.fzf"
    else
        git -C "$HOME_DIR/.fzf" pull
    fi
    "$HOME_DIR/.fzf/install" --bin --no-update-rc --no-bash --no-zsh --no-fish
    
    mkdir -p "$HOME_DIR/.local/bin"
    ln -sf "$HOME_DIR/.fzf/bin/fzf" "$HOME_DIR/.local/bin/fzf"
    show_success "fzf installed."
}

install_zoxide() {
    show_progress "Installing zoxide from script..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    show_success "zoxide installed."
}

install_eza() {
    show_progress "Installing eza binary..."
    local temp_dir arch eza_url
    temp_dir=$(mktemp -d)
    arch=$(uname -m)
    
    if [ "$arch" = "x86_64" ]; then
        eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    elif [ "$arch" = "aarch64" ]; then
        eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
    else
        show_error "Unsupported architecture for eza binary: $arch"
        return 1
    fi
    
    curl -fsSL "$eza_url" | tar -xz -C "$temp_dir"
    mkdir -p "$HOME_DIR/.local/bin"
    mv "$temp_dir/eza" "$HOME_DIR/.local/bin/eza"
    rm -rf "$temp_dir"
    show_success "eza installed."
}

link_file() {
    local target="$1"
    local link_name="$2"
    
    if [ -e "$link_name" ] || [ -L "$link_name" ]; then
        if [ "$(readlink "$link_name")" = "$target" ]; then
            show_message "$link_name already linked."
        else
            show_warning "Backing up $link_name to ${link_name}.old..."
            mv "$link_name" "${link_name}.old"
            ln -s "$target" "$link_name"
            show_success "Symlinked $link_name."
        fi
    else
        ln -s "$target" "$link_name"
        show_success "Symlinked $link_name."
    fi
}

# Main Execution
cd "$HOME_DIR" || exit 1

show_message "Starting shell setup..."

install_base_packages

if ! command -v fzf >/dev/null 2>&1; then
    install_fzf
elif ! check_fzf_version; then
    show_warning "fzf version is outdated. Reinstalling..."
    install_fzf
else
    show_success "fzf is installed and compatible."
fi

if ! command -v zoxide >/dev/null 2>&1; then
    install_zoxide
else
    show_success "zoxide is already installed."
fi

if ! command -v eza >/dev/null 2>&1; then
    install_eza
else
    show_success "eza is already installed."
fi

if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    show_progress "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    show_success "oh-my-zsh installed."
else
    show_success "oh-my-zsh is already installed."
fi

if ! command -v starship >/dev/null 2>&1; then
    show_progress "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    show_success "starship installed."
else
    show_success "starship is already installed."
fi

show_progress "Setting up symlinks..."
link_file "dots/shell/.zshrc" ".zshrc"

mkdir -p .config
link_file "../dots/shell/starship.toml" ".config/starship.toml"

ZSH_PATH=$(command -v zsh || true)
if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
    show_progress "Changing default shell to zsh..."
    if command -v sudo >/dev/null 2>&1; then
        sudo chsh -s "$ZSH_PATH" "$USER"
    else
        chsh -s "$ZSH_PATH"
    fi
    show_success "Default shell changed to zsh."
else
    show_success "Default shell is already zsh."
fi

show_success "Shell setup complete."
