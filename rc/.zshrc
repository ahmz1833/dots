# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.


######### NOTE: You may disable/enable lines below: #########

HOME_DIR=$HOME
if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [ $? -eq 0 ]; then
        show_success "zsh-autosuggestions plugin installed successfully"
    else
        show_error "zsh-autosuggestions installation failed"
    fi
fi
if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ $? -eq 0 ]; then
        show_success "zsh-syntax-highlighting plugin installed successfully"
    else
        show_error "zsh-syntax-highlighting installation failed"
    fi
fi
if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-history-substring-search" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-history-substring-search"
    if [ $? -eq 0 ]; then
        show_success "zsh-history-substring-search plugin installed successfully"
    else
        show_error "zsh-history-substring-search installation failed"
    fi
fi
if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autocomplete" ]; then
    git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autocomplete"
    if [ $? -eq 0 ]; then
        show_success "zsh-autocomplete plugin installed successfully"
    else
        show_error "zsh-autocomplete installation failed"
    fi
fi

#############################################################
#
plugins=(
    git
    zsh-history-substring-search
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-autocomplete
    fzf
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"i

alias cl='clear'

alias py='python3'

alias k='kubectl'
alias kg='k get'
alias kgp='k get pods'
alias kgs='k get services'
alias kgn='k get nodes'
alias kd='k describe'
alias kdp='k describe pod'
alias kdn='k describe node'
alias kex='k exec -it'
alias kl='k logs'
alias kdel='k delete'

alias g='git'
alias glog='git log --graph --color --decorate --oneline'
alias gitlog='git log --all --color --decorate --graph'

alias grep='grep --color=auto'

alias svi='sudo vim'
alias ls='eza --icons'
alias la='ls -algi'
alias l='ls -lahgi'
alias lt='ls --tree'

alias hex='hexdump --canonical'
alias zz='zip -qr9T "$(basename "$(pwd)").zip" .'
alias rsyncr='rsync -rvzP'

alias sctl='sudo systemctl'
alias sctls='sctl status'
alias sctlr='sctl restart'

alias pls='sudo $(fc -ln -1)'

alias -g G='| grep'
alias -g L='| less'

###############################################

extract() {
  local archive="$1"
  local dest="${2:-.}"

  if [ -f "$archive" ]; then
    # 1. Resolve absolute path of the archive
    # (We need this because if we 'cd' into $dest, a relative path like '../file.zip' breaks)
    if [[ "$archive" != /* ]]; then
      archive="$PWD/$archive"
    fi

    # 2. Create and Enter destination
    mkdir -p "$dest"
    cd "$dest"

    # 3. Extract using standard commands (no complex flags needed)
    case "$archive" in
      *.tar.bz2)   tar xjf "$archive"   ;;
      *.tar.gz)    tar xzf "$archive"   ;;
      *.bz2)       bunzip2 "$archive"   ;;
      *.rar)       unrar x "$archive"   ;;
      *.gz)        gunzip "$archive"    ;;
      *.tar)       tar xf "$archive"    ;;
      *.tbz2)      tar xjf "$archive"   ;;
      *.tgz)       tar xzf "$archive"   ;;
      *.zip)       unzip "$archive"     ;;
      *.Z)         uncompress "$archive";;
      *.7z)        7z x "$archive"      ;;
      *)           echo "Unknown format: $archive" ;;
    esac

    # 4. Go back to original folder (silently)
    cd - > /dev/null
  else
    echo "'$archive' is not a valid file"
  fi
}

cheat() {
    curl "cheat.sh/$1"
}

server() {
    local port="${1:-8000}"
    # Check if python3 is available (most likely)
    if command -v python3 &>/dev/null; then
        python3 -m http.server "$port"
    # Fallback for older python2 systems
    elif command -v python &>/dev/null; then
        python -m SimpleHTTPServer "$port"
    else
        echo "Python is not installed."
    fi
}

bak() {
  local file="$1"
  if [ -f "$file" ] || [ -d "$file" ]; then
    local timestamp=$(date +%Y%m%d_%H%M)
    cp -r "$file" "$file.$timestamp"
    echo "Backup created: $file.$timestamp"
  else
    echo "Error: File '$file' not found."
  fi
}

f() {
  find . -name "*$1*"
}

whop() {
    # -i: internet files, -P: no port names, -n: no host names
    sudo lsof -i :"$1" -P -n
}

###############################################
bindkey '^ ' autosuggest-accept

source <(zoxide init zsh)
source <(starship init zsh)

