# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal dotfiles repo (`dots/`) that provisions Linux environments with zsh, tmux, vim, and utility scripts. Owned by GitHub user `ahmz1833`. The repo lives at `~/dots` on target machines and is deployed via `bootstrap.sh`.

## Key Commands

- **Bootstrap (interactive):** `bash dots/bootstrap.sh` - fetches repo (SSH/HTTPS/tarball/S3), then runs all install scripts
- **Bootstrap (no root):** `bash dots/bootstrap.sh --no-sudo` - skips package installs and shell change
- **Publish to S3:** `bash dots/publish.sh` - tarballs repo and uploads to `s3://ahmz/dots` via s3cmd
- **Remote install:** `curl -sL https://s3.ahmz.ir/dots/bootstrap.sh | bash`

## Core Problem: Restricted Server Access

The primary audience is Iranian sysadmins whose servers cannot freely reach GitHub, npm, or other common package sources due to network restrictions. The admin typically has a VPN on their local machine but not on the server. This constraint drives most design decisions:

**Flow 1 — S3 mirror (`publish.sh`):** The repo and bootstrap script are published to `s3.ahmz.ir`, an accessible S3 endpoint. Servers that can't reach GitHub can pull everything from S3 instead. `bootstrap.sh` with `FETCH_MODE="s3"` is the version uploaded for `curl | bash` remote installs.

**Flow 2 — Proxy tunneling (`proxy`/`unproxy` shell functions):** Once dotfiles are on the server, the admin can SSH-tunnel a SOCKS5 proxy from their local machine (e.g. `ssh -D 1080 server`) and then run `proxy` on the server to route all traffic (curl, git HTTP, git SSH, npm) through `socks5h://127.0.0.1:1080`. This lets install scripts that fetch from GitHub (fzf, zoxide, eza, oh-my-zsh, starship) work through the local machine's VPN. `unproxy` tears it all down cleanly.

**Flow 3 — `pssh` (proxy-aware SSH):** For hopping between restricted servers, `pssh <port> user@host` routes SSH through a local SOCKS5 proxy. Useful when the admin needs to reach a second server that's only accessible through the first.

**Flow 4 — Pre-baked Docker image (`sandbox-base/`):** The Dockerfile installs all CLI tools (fzf, zoxide, eza, starship, ripgrep, etc.) at image build time. The image can be built on a machine with internet access, pushed to a local registry, and used on restricted servers with zero runtime downloads.

**Flow 5 — Multiple bootstrap fetch modes:** `bootstrap.sh` offers 4 download methods (SSH git, HTTPS git, GitHub tarball, S3 tarball) so the admin can pick whichever source is reachable from their server.

When adding new features or install steps that download from the internet, keep these constraints in mind: always consider whether the download will work on a restricted server, and prefer approaches that work through the S3 mirror or SOCKS5 proxy flow.

## Architecture

### Bootstrap Flow

`bootstrap.sh` is the entrypoint. It:
1. Fetches/updates the repo to `~/dots` (4 modes: SSH, HTTPS, GitHub tarball, S3 tarball)
2. Runs `vim/install.sh` (bash), `shell/install.sh` (zsh), `tmux/install.sh` (bash) in sequence
3. Symlinks everything in `scripts/` to `~/.local/bin`

Install scripts use exit code conventions: `0` = changes made, `10` = no changes needed, anything else = error. The `run_subscript` wrapper in bootstrap.sh handles this.

### Component Layout

- **`shell/`** - zsh setup: installs oh-my-zsh, starship, fzf (requires >=0.48), zoxide, eza. Symlinks `.zshrc` and `starship.toml`. The `.zshrc` auto-clones 5 oh-my-zsh plugins on first load (fzf-tab, autosuggestions, syntax-highlighting, history-substring-search, autocomplete).
- **`tmux/`** - Plugin-free tmux config. Prefix is `Ctrl+Space`. Has a theming system with 10 color themes in `themes/` and 3 status bar presets (classic, minimal, full). `full` preset supports two powerline architectures: "conic" (arrow separators) and "round" (pill separators). `.tmux.local.conf` is *copied* (not symlinked) for per-machine overrides.
- **`vim/`** - Symlinks `.vimrc` and `colors/` directory.
- **`scripts/`** - CLI utilities symlinked to `~/.local/bin`:
  - `checkusage` - CPU/RAM display (used by starship prompt and tmux status bar)
  - `netspd` - Network speed monitor (used by tmux status bar)
  - `checkip` - Public IP with caching (used by starship prompt)
  - `dnss` / `dnss-rctl` - DNS management via NetworkManager / resolvectl
  - `mkservice` - Interactive systemd service creator wizard
  - `proj2clip` - Copies project source tree to clipboard for LLM context
  - `fixxtime` - NTP time sync fix
- **`sandbox-base/`** - Dockerfile for a Debian bookworm base image with all CLI tools pre-installed. Used as a container sandbox base.

### Tmux Theming System

Themes set `@thm_*` color variables in `themes/*.conf`. The status bar builder in `.tmux.conf` reads `@status_preset`, `@show_*` toggles, and `@full_architecture` to dynamically compose the status line. All user-facing knobs are documented in `.tmux.local.conf`. The chain of evaluation: local conf loads first (sets theme + toggles), then `.tmux.conf` builds segments conditionally.

### Starship Prompt

`starship.toml` uses a "hybrid" palette with 256-color codes (not hex) for SSH compatibility. Custom modules (`checkusage`, `checkip`) shell out to scripts in `~/.local/bin`. The prompt uses a two-pill powerline design for language indicators.

## Conventions

- All install scripts are idempotent: they check current state before acting and only modify what's needed
- Symlink pattern: config files in `~/dots/` are symlinked to their expected locations (`~/.zshrc`, `~/.tmux.conf`, etc.)
- Exception: `.tmux.local.conf` is copied (not symlinked) so each machine can diverge
- Shell scripts use colored status prefixes: `[..]` progress, `[>>]` info, `[OK]` success, `[!!]` warning, `[XX]` error
- The `.zshrc` sources `~/.zshrc.mine` at the end for machine-local shell customizations
