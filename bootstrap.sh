#!/bin/bash

set -e

HOME_DIR="$HOME"
DOTS_DIR="${HOME_DIR}/dots"
GITHUB_USER="ahmz1833"
GITHUB_REPO="dots"
FETCH_MODE="interactive"
S3_BUCKET_URL="https://s3.ahmz.ir/dots"
SKIP_SUDO=0

for arg in "$@"; do
    if [ "$arg" = "--no-sudo" ]; then
        SKIP_SUDO=1
    fi
done

show_progress() { echo -e "\033[1;34m[..]\033[0m $1"; }
show_message()  { echo -e "\033[1;37m[>>]\033[0m $1"; }
show_success()  { echo -e "\033[1;32m[OK]\033[0m $1"; }
show_error()    { echo -e "\033[1;31m[XX]\033[0m $1"; exit 1; }

fetch_dots() {
    local mode="$1"
    
    if [ -d "$DOTS_DIR" ]; then
        if [ -d "$DOTS_DIR/.git" ]; then
            if [ "$mode" = "ssh" ] || [ "$mode" = "https" ]; then
                show_progress "Updating existing git repository..."
                git -C "$DOTS_DIR" pull || show_error "Failed to pull git repository."
                return 0
            else
                show_message "Git repo exists, but using tarball mode. Overwriting files..."
            fi
        else
            if [ "$mode" = "ssh" ] || [ "$mode" = "https" ]; then
                show_warning "Directory exists but is not a git repository."
                show_progress "Backing up to dots.bak and cloning freshly..."
                mv "$DOTS_DIR" "${DOTS_DIR}.bak.$(date +%s)"
            else
                show_progress "Updating existing directory from tarball..."
            fi
        fi
    fi

    case "$mode" in
        ssh)
            if [ ! -d "$DOTS_DIR" ]; then
                show_progress "Cloning via SSH..."
                git clone "git@github.com:${GITHUB_USER}/${GITHUB_REPO}.git" "$DOTS_DIR"
            fi
            ;;
        https)
            if [ ! -d "$DOTS_DIR" ]; then
                show_progress "Cloning via HTTPS..."
                git clone "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$DOTS_DIR"
            fi
            ;;
        raw)
            show_progress "Downloading tarball from GitHub (Raw)..."
            mkdir -p "$DOTS_DIR"
            curl -fsSL "https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/main.tar.gz" | tar -xz -C "$DOTS_DIR" --strip-components=1
            ;;
        s3)
            show_progress "Downloading tarball from S3..."
            mkdir -p "$DOTS_DIR"
            curl -fsSL "${S3_BUCKET_URL}/dots.tar.gz" | tar -xz -C "$DOTS_DIR" --strip-components=1
            ;;
        *)
            show_error "Invalid fetch mode."
            ;;
    esac
}

setup_scripts() {
    show_progress "Symlinking scripts to ~/.local/bin..."
    local bin_dir="${HOME_DIR}/.local/bin"
    mkdir -p "$bin_dir"

    if [ -d "${DOTS_DIR}/scripts" ]; then
        for script in "${DOTS_DIR}/scripts/"*; do
            if [ -f "$script" ]; then
                local script_name
                script_name=$(basename "$script")
                ln -sf "$script" "${bin_dir}/${script_name}"
                show_message "Linked $script_name"
            fi
        done
        show_success "Scripts symlinked."
    else
        show_message "No scripts directory found. Skipping."
    fi
}

# --- Main Logic ---

if [ "$FETCH_MODE" = "interactive" ]; then
    echo "Select download method for dotfiles:"
    echo "1) SSH (git clone git@github...)"
    echo "2) HTTPS (git clone https://github...)"
    echo "3) Raw (GitHub Tarball)"
    echo "4) S3 (S3 Tarball)"
    read -rp "Enter choice [1-4] (default 2): " choice

    case "$choice" in
        1) fetch_dots "ssh" ;;
        3) fetch_dots "raw" ;;
        4) fetch_dots "s3" ;;
        *) fetch_dots "https" ;;
    esac
elif [ "$FETCH_MODE" = "s3" ]; then
    show_message "S3 mode forced. Fetching from S3 bucket..."
    fetch_dots "s3"
else
    fetch_dots "$FETCH_MODE"
fi

INSTALL_ARGS=""
if [ "$SKIP_SUDO" -eq 1 ]; then
    INSTALL_ARGS="--no-sudo"
fi

show_progress "Executing Vim install script..."
if [ -f "${DOTS_DIR}/vim/install.sh" ]; then
    bash "${DOTS_DIR}/vim/install.sh"
else
    show_message "Vim install script not found. Skipping."
fi

show_progress "Executing Shell install script..."
if [ -f "${DOTS_DIR}/shell/install.sh" ]; then
    zsh "${DOTS_DIR}/shell/install.sh" $INSTALL_ARGS
else
    show_message "Shell install script not found. Skipping."
fi

setup_scripts

show_success "Bootstrap complete!"
