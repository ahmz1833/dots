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

INSTALL_REGION="${INSTALL_REGION:-global}"
S3_ASSETS_BASE="https://s3.ahmz.ir/server_setup/assets/github.com"
S3_DOTS_BASE="https://s3.ahmz.ir/dots"

is_iran_install() {
    [ "$INSTALL_REGION" = "iran" ]
}

ensure_local_bin() {
    mkdir -p "${HOME_DIR}/.local/bin"
}

install_binary_from_tarball() {
    local url="$1"
    local binary_name="$2"
    local target_name="${3:-$2}"
    local temp_dir extracted_path

    temp_dir=$(mktemp -d)
    curl -fsSL "$url" | tar -xz -C "$temp_dir"
    extracted_path=$(find "$temp_dir" -type f -name "$binary_name" | head -n 1)

    if [ -z "$extracted_path" ]; then
        rm -rf "$temp_dir"
        show_error "Failed to locate $binary_name in downloaded archive."
        return 1
    fi

    ensure_local_bin
    chmod +x "$extracted_path"
    mv "$extracted_path" "${HOME_DIR}/.local/bin/${target_name}"
    rm -rf "$temp_dir"
}

install_oh_my_zsh_from_tarball() {
    local temp_dir

    temp_dir=$(mktemp -d)
    curl -fsSL "${S3_DOTS_BASE}/oh-my-zsh.tar.gz" | tar -xz -C "$temp_dir"

    if [ ! -d "${temp_dir}/.oh-my-zsh" ]; then
        rm -rf "$temp_dir"
        show_error "oh-my-zsh archive did not contain the expected .oh-my-zsh directory."
        return 1
    fi

    cp -a "${temp_dir}/.oh-my-zsh" "${HOME_DIR}/"
    rm -rf "$temp_dir"
}

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
    if is_iran_install && [ "$(uname -m)" = "x86_64" ]; then
        install_binary_from_tarball \
            "${S3_ASSETS_BASE}/junegunn/fzf/releases/download/v0.70.0/fzf-0.70.0-linux_amd64.tar.gz" \
            "fzf"
        HAS_CHANGED=1
    else
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

        ensure_local_bin
        ln -sf "${HOME_DIR}/.fzf/bin/fzf" "${HOME_DIR}/.local/bin/fzf"
    fi
    show_success "fzf installed."
}

install_zoxide() {
    show_progress "Installing zoxide..."
    if is_iran_install && [ "$(uname -m)" = "x86_64" ]; then
        install_binary_from_tarball \
            "${S3_ASSETS_BASE}/ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz" \
            "zoxide"
    else
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi
    HAS_CHANGED=1
    show_success "zoxide installed."
}

install_eza() {
    show_progress "Installing eza..."
    local arch eza_url
    arch=$(uname -m)

    if is_iran_install && [ "$arch" = "x86_64" ]; then
        eza_url="${S3_ASSETS_BASE}/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-musl.tar.gz"
        install_binary_from_tarball "$eza_url" "eza"
    elif [ "$arch" = "x86_64" ]; then
        eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
        install_binary_from_tarball "$eza_url" "eza"
    elif [ "$arch" = "aarch64" ]; then
        eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
        install_binary_from_tarball "$eza_url" "eza"
    else
        show_error "Unsupported architecture."
        return 1
    fi
    HAS_CHANGED=1
    show_success "eza installed."
}

install_starship() {
    show_progress "Installing starship..."
    if is_iran_install && [ "$(uname -m)" = "x86_64" ]; then
        install_binary_from_tarball \
            "${S3_ASSETS_BASE}/starship/starship/releases/download/v1.24.2/starship-x86_64-unknown-linux-musl.tar.gz" \
            "starship"
    else
        if [ "$SKIP_SUDO" -eq 1 ]; then
            ensure_local_bin
            curl -sS https://starship.rs/install.sh | sh -s -- -y -b "${HOME_DIR}/.local/bin"
        else
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    fi
    HAS_CHANGED=1
    show_success "starship installed."
}

install_oh_my_zsh() {
    if [ ! -d "${HOME_DIR}/.oh-my-zsh" ]; then
        show_progress "Installing oh-my-zsh..."
        if is_iran_install; then
            install_oh_my_zsh_from_tarball
        else
            RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        fi
        HAS_CHANGED=1
        show_success "oh-my-zsh installed."
    else
        show_success "oh-my-zsh already installed."
    fi
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

install_oh_my_zsh

if ! command -v starship >/dev/null 2>&1; then
    install_starship
else
    show_success "starship already installed."
fi

show_progress "Setting up symlinks..."
link_file "${HOME_DIR}/dots/shell/.zshrc" "${HOME_DIR}/.zshrc.common"

if [ -L "${HOME_DIR}/.zshrc" ] && [ "$(readlink "${HOME_DIR}/.zshrc")" = "${HOME_DIR}/dots/shell/.zshrc" ]; then
    show_warning "Removing old symlinked .zshrc..."
    rm -f "${HOME_DIR}/.zshrc"
    HAS_CHANGED=1
fi

if [ ! -f "${HOME_DIR}/.zshrc" ]; then
    echo "source ~/.zshrc.common" > "${HOME_DIR}/.zshrc"
    HAS_CHANGED=1
    show_success "Created new ~/.zshrc sourcing .zshrc.common"
elif ! grep -q "source ~/.zshrc.common" "${HOME_DIR}/.zshrc"; then
    show_warning "Prepending source to existing ~/.zshrc..."
    echo "source ~/.zshrc.common" | cat - "${HOME_DIR}/.zshrc" > "${HOME_DIR}/.zshrc.tmp"
    mv "${HOME_DIR}/.zshrc.tmp" "${HOME_DIR}/.zshrc"
    HAS_CHANGED=1
    show_success "Updated ~/.zshrc to source .zshrc.common"
fi

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
