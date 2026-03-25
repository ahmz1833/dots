#!/bin/bash

set -eo pipefail

HOME_DIR="$HOME"
DOTS_DIR="${HOME_DIR}/dots"
GITHUB_USER="ahmz1833"
GITHUB_REPO="dots"
FETCH_MODE="interactive"
S3_BUCKET_URL="https://s3.ahmz.ir/dots"
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
show_error()    { echo -e "\033[1;31m[XX]\033[0m $1"; exit 1; }

run_subscript() {
    set +e
    "$@"
    local rc=$?
    set -e
    if [ $rc -eq 0 ]; then
        HAS_CHANGED=1
    elif [ $rc -ne 10 ]; then
        show_error "Script failed with exit code $rc: $*"
    fi
}

fetch_dots() {
    local mode="$1"
    
    if [ -d "$DOTS_DIR" ]; then
        if [ -d "$DOTS_DIR/.git" ]; then
            if [ "$mode" = "ssh" ] || [ "$mode" = "https" ]; then
                show_progress "Updating existing git repository..."
                local pull_output
                pull_output=$(git -C "$DOTS_DIR" pull 2>&1) || show_error "Failed to pull git repository."
                
                if [[ "$pull_output" != *"Already up to date."* ]]; then
                    HAS_CHANGED=1
                    show_message "Repository updated."
                fi
                return 0
            else
                show_message "Git repo exists, but using tarball mode."
            fi
        else
            if [ "$mode" = "ssh" ] || [ "$mode" = "https" ]; then
                show_progress "Backing up to dots.bak and cloning freshly..."
                mv "$DOTS_DIR" "${DOTS_DIR}.bak.$(date +%s)"
                HAS_CHANGED=1
            else
                show_progress "Checking existing directory against tarball..."
            fi
        fi
    fi

    case "$mode" in
        ssh)
            if [ ! -d "$DOTS_DIR" ]; then
                show_progress "Cloning via SSH..."
                git clone "git@github.com:${GITHUB_USER}/${GITHUB_REPO}.git" "$DOTS_DIR"
                HAS_CHANGED=1
            fi
            ;;
        https)
            if [ ! -d "$DOTS_DIR" ]; then
                show_progress "Cloning via HTTPS..."
                git clone "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$DOTS_DIR"
                HAS_CHANGED=1
            fi
            ;;
        raw|s3)
            local temp_dir tar_url
            temp_dir=$(mktemp -d)
            
            if [ "$mode" = "raw" ]; then
                show_progress "Downloading tarball from GitHub (Raw)..."
                tar_url="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/main.tar.gz"
            else
                show_progress "Downloading tarball from S3..."
                tar_url="${S3_BUCKET_URL}/dots.tar.gz"
            fi
            
            # Download and extract to the temporary directory first
            curl -fsSL "$tar_url" | tar -xz -C "$temp_dir" --strip-components=1
            
            if [ -d "$DOTS_DIR" ]; then
                # Compare temp directory against current dots directory
                if diff -rq --exclude=".git" "$temp_dir" "$DOTS_DIR" >/dev/null 2>&1; then
                    show_message "Tarball contents match existing directory. No changes."
                else
                    show_progress "Differences found. Updating directory..."
                    cp -a "$temp_dir/." "$DOTS_DIR/"
                    HAS_CHANGED=1
                fi
            else
                show_progress "Extracting tarball to new directory..."
                mkdir -p "$DOTS_DIR"
                cp -a "$temp_dir/." "$DOTS_DIR/"
                HAS_CHANGED=1
            fi
            
            # Clean up
            rm -rf "$temp_dir"
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
                local target_link="${bin_dir}/${script_name}"
                
                if [ ! -L "$target_link" ] || [ "$(readlink "$target_link")" != "$script" ]; then
                    ln -sf "$script" "$target_link"
                    show_message "Linked $script_name"
                    HAS_CHANGED=1
                fi
            fi
        done
        show_success "Scripts symlink check complete."
    else
        show_message "No scripts directory found. Skipping."
    fi
}

# --- Main Logic ---

if [ "$FETCH_MODE" = "interactive" ]; then
    if [ -t 0 ]; then
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
    else
        show_message "Non-interactive environment detected. Defaulting to HTTPS mode."
        fetch_dots "https"
    fi
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
    run_subscript bash "${DOTS_DIR}/vim/install.sh"
else
    show_message "Vim install script not found. Skipping."
fi

show_progress "Executing Shell install script..."
if [ -f "${DOTS_DIR}/shell/install.sh" ]; then
    run_subscript zsh "${DOTS_DIR}/shell/install.sh" $INSTALL_ARGS
else
    show_message "Shell install script not found. Skipping."
fi

show_progress "Executing Tmux install script..."
if [ -f "${DOTS_DIR}/tmux/install.sh" ]; then
    run_subscript bash "${DOTS_DIR}/tmux/install.sh"
else
    show_message "Tmux install script not found. Skipping."
fi

setup_scripts

if [ "$HAS_CHANGED" -eq 1 ]; then
    show_success "Bootstrap complete! (Changes were made)"
    exit 0
else
    show_success "Bootstrap complete! (No changes required)"
    exit 10
fi
